import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aula_puntos_senati/database/database_helper.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('crea el esquema nuevo con datos semilla UUID', () async {
    final directory = await Directory.systemTemp.createTemp('aula-puntos-fresh-');
    final path = '${directory.path}${Platform.pathSeparator}fresh.db';
    final helper = DatabaseHelper.forTesting(path);

    try {
      final db = await helper.database;
      final ids = {
        'instructores': 'instructorId',
        'grupos': 'grupoId',
        'estudiantes': 'estudianteId',
        'sesiones': 'sesionId',
        'asistencias': 'asistenciaId',
        'actividades': 'actividadId',
      };

      for (final entry in ids.entries) {
        final rows = await db.query(entry.key, columns: [entry.value]);
        expect(rows, isNotEmpty);
        for (final row in rows) {
          expect('${row[entry.value]}', matches(RegExp(r'^[0-9a-f-]{36}$')));
        }
      }

      final grupo = (await db.query('grupos')).single;
      final instructor = (await db.query('instructores')).single;
      final estudiante = (await db.query('estudiantes')).first;
      final sesion = (await db.query('sesiones')).single;
      expect(grupo['instructorId'], instructor['instructorId']);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);

      final matricula = await db.query('grupo_estudiantes', limit: 1);
      expect(matricula.single['grupoId'], grupo['grupoId']);
      expect(matricula.single['estudianteId'], estudiante['estudianteId']);
      expect((await db.query('asistencias')).length, 8);
      expect((await db.query('asistencias')).first['sesionId'], sesion['sesionId']);

      final asistenciaExistente = (await db.query('asistencias')).first;
      final estudianteId = asistenciaExistente['estudianteId'] as String;
      await db.delete(
        'asistencias',
        where: 'sesionId = ? AND estudianteId = ?',
        whereArgs: [sesion['sesionId'], estudianteId],
      );

      await helper.registrarOActualizarAsistencia(
        sesionId: sesion['sesionId'] as String,
        estudianteId: estudianteId,
        estado: 'Justificado',
      );
      final asistenciaInsertada = (await db.query(
        'asistencias',
        where: 'sesionId = ? AND estudianteId = ?',
        whereArgs: [sesion['sesionId'], estudianteId],
      )).single;

      await helper.registrarOActualizarAsistencia(
        sesionId: sesion['sesionId'] as String,
        estudianteId: estudianteId,
        estado: 'Tardanza',
      );
      final asistenciasActualizadas = await db.query(
        'asistencias',
        where: 'sesionId = ? AND estudianteId = ?',
        whereArgs: [sesion['sesionId'], estudianteId],
      );

      expect(asistenciasActualizadas, hasLength(1));
      expect(asistenciasActualizadas.single['asistenciaId'], asistenciaInsertada['asistenciaId']);
      expect(asistenciasActualizadas.single['estado'], 'Tardanza');
    } finally {
      await helper.closeForTesting();
      await directory.delete(recursive: true);
    }
  });

  test('crear una sesión conserva las sesiones anteriores del grupo', () async {
    final directory = await Directory.systemTemp.createTemp('aula-puntos-sessions-');
    final path = '${directory.path}${Platform.pathSeparator}sessions.db';
    final helper = DatabaseHelper.forTesting(path);

    try {
      final grupo = (await helper.getGrupos()).single;
      final anteriores = await helper.getSesionesByGrupo(grupo.grupoId!);

      for (var index = 0; index < 2; index++) {
        await helper.insertSesion(
          Sesion(
            grupoId: grupo.grupoId!,
            numeroSesion: anteriores.length + index + 1,
            fecha: '2026-11-13',
            tema: 'Sesión de prueba ${index + 1}',
            tipoSesion: 'Teoría',
            duracionHoras: 2,
            observaciones: '',
          ),
        );
      }

      final actuales = await helper.getSesionesByGrupo(grupo.grupoId!);
      expect(actuales, hasLength(anteriores.length + 2));
      expect(actuales.map((sesion) => sesion.tema), contains('Introducción al Rol del Monitor y Pedagogía Dual'));
    } finally {
      await helper.closeForTesting();
      await directory.delete(recursive: true);
    }
  });

  test('un código de grupo duplicado no reemplaza el grupo ni borra sus sesiones', () async {
    final directory = await Directory.systemTemp.createTemp('aula-puntos-duplicate-group-');
    final path = '${directory.path}${Platform.pathSeparator}groups.db';
    final helper = DatabaseHelper.forTesting(path);

    try {
      final grupoOriginal = (await helper.getGrupos()).single;
      final sesionesOriginales = await helper.getSesionesByGrupo(grupoOriginal.grupoId!);

      await expectLater(
        helper.insertGrupo(
          Grupo(
            codigo: grupoOriginal.codigo,
            nombre: 'Grupo duplicado',
            programa: grupoOriginal.programa,
            asignatura: grupoOriginal.asignatura,
            periodo: grupoOriginal.periodo,
            seccion: grupoOriginal.seccion,
            instructorId: grupoOriginal.instructorId,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );

      final grupos = await helper.getGrupos();
      final sesiones = await helper.getSesionesByGrupo(grupoOriginal.grupoId!);
      expect(grupos, hasLength(1));
      expect(grupos.single.grupoId, grupoOriginal.grupoId);
      expect(grupos.single.nombre, grupoOriginal.nombre);
      expect(sesiones.map((sesion) => sesion.sesionId),
          sesionesOriginales.map((sesion) => sesion.sesionId));
    } finally {
      await helper.closeForTesting();
      await directory.delete(recursive: true);
    }
  });

  test('migra IDs enteros a UUID y conserva relaciones y datos', () async {
    final directory = await Directory.systemTemp.createTemp('aula-puntos-migration-');
    final path = '${directory.path}${Platform.pathSeparator}legacy.db';

    final legacyDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE instructores (
            instructorId INTEGER PRIMARY KEY AUTOINCREMENT,
            nombres TEXT NOT NULL,
            apellidos TEXT NOT NULL,
            correo TEXT UNIQUE NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE grupos (
            grupoId INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo TEXT UNIQUE NOT NULL,
            nombre TEXT NOT NULL,
            programa TEXT NOT NULL,
            asignatura TEXT NOT NULL,
            periodo TEXT NOT NULL,
            seccion TEXT NOT NULL,
            instructorId INTEGER,
            FOREIGN KEY (instructorId) REFERENCES instructores (instructorId) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE estudiantes (
            estudianteId INTEGER PRIMARY KEY AUTOINCREMENT,
            codigoInstitucional TEXT UNIQUE NOT NULL,
            nombres TEXT NOT NULL,
            apellidos TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE grupo_estudiantes (
            grupoId INTEGER NOT NULL,
            estudianteId INTEGER NOT NULL,
            fechaIncorporacion TEXT NOT NULL,
            PRIMARY KEY (grupoId, estudianteId),
            FOREIGN KEY (grupoId) REFERENCES grupos (grupoId) ON DELETE CASCADE,
            FOREIGN KEY (estudianteId) REFERENCES estudiantes (estudianteId) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sesiones (
            sesionId INTEGER PRIMARY KEY AUTOINCREMENT,
            grupoId INTEGER NOT NULL,
            numeroSesion INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            tema TEXT NOT NULL,
            tipoSesion TEXT NOT NULL,
            duracionHoras INTEGER NOT NULL,
            observaciones TEXT,
            FOREIGN KEY (grupoId) REFERENCES grupos (grupoId) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE asistencias (
            asistenciaId INTEGER PRIMARY KEY AUTOINCREMENT,
            sesionId INTEGER NOT NULL,
            estudianteId INTEGER NOT NULL,
            estado TEXT NOT NULL CHECK(estado IN ('Presente', 'Tardanza', 'Falta', 'Justificado')),
            fechaRegistro TEXT NOT NULL,
            observacion TEXT,
            UNIQUE (sesionId, estudianteId),
            FOREIGN KEY (sesionId) REFERENCES sesiones (sesionId) ON DELETE CASCADE,
            FOREIGN KEY (estudianteId) REFERENCES estudiantes (estudianteId) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE actividades (
            actividadId INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            valorDefecto INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE participaciones (
            participacionId INTEGER PRIMARY KEY AUTOINCREMENT,
            sesionId INTEGER NOT NULL,
            estudianteId INTEGER NOT NULL,
            actividadId INTEGER NOT NULL,
            puntos INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            uuidTransaccion TEXT UNIQUE NOT NULL,
            FOREIGN KEY (sesionId) REFERENCES sesiones (sesionId) ON DELETE CASCADE,
            FOREIGN KEY (estudianteId) REFERENCES estudiantes (estudianteId) ON DELETE CASCADE,
            FOREIGN KEY (actividadId) REFERENCES actividades (actividadId) ON DELETE CASCADE
          )
        ''');

        final instructorId = await db.insert('instructores', {
          'nombres': 'Ana',
          'apellidos': 'Instructora',
          'correo': 'ana@example.test',
        });
        final grupoId = await db.insert('grupos', {
          'codigo': 'G-1',
          'nombre': 'Grupo Uno',
          'programa': 'P1',
          'asignatura': 'Bases de datos',
          'periodo': '2026-1',
          'seccion': 'A',
          'instructorId': instructorId,
        });
        final estudianteId = await db.insert('estudiantes', {
          'codigoInstitucional': 'SEN-001',
          'nombres': 'Luis',
          'apellidos': 'Pérez',
        });
        await db.insert('grupo_estudiantes', {
          'grupoId': grupoId,
          'estudianteId': estudianteId,
          'fechaIncorporacion': '2026-01-01',
        });
        final sesionId = await db.insert('sesiones', {
          'grupoId': grupoId,
          'numeroSesion': 1,
          'fecha': '2026-01-01',
          'tema': 'Introducción',
          'tipoSesion': 'Teoría',
          'duracionHoras': 2,
          'observaciones': '',
        });
        await db.insert('asistencias', {
          'sesionId': sesionId,
          'estudianteId': estudianteId,
          'estado': 'Presente',
          'fechaRegistro': '2026-01-01T08:00:00',
          'observacion': '',
        });
        final actividadId = await db.insert('actividades', {
          'nombre': 'Participación',
          'descripcion': '',
          'valorDefecto': 1,
        });
        await db.insert('participaciones', {
          'sesionId': sesionId,
          'estudianteId': estudianteId,
          'actividadId': actividadId,
          'puntos': 3,
          'fecha': '2026-01-01T08:30:00',
          'uuidTransaccion': 'transaction-1',
        });
      },
    );
    await legacyDb.close();

    final helper = DatabaseHelper.forTesting(path);
    try {
      final migratedDb = await helper.database;
      final instructor = (await migratedDb.query('instructores')).single;
      final grupo = (await migratedDb.query('grupos')).single;
      final estudiante = (await migratedDb.query('estudiantes')).single;
      final sesion = (await migratedDb.query('sesiones')).single;
      final asistencia = (await migratedDb.query('asistencias')).single;
      final actividad = (await migratedDb.query('actividades')).single;
      final participacion = (await migratedDb.query('participaciones')).single;

      expect(grupo['instructorId'], instructor['instructorId']);
      expect(grupo['nombre'], 'Grupo Uno');
      expect(asistencia['sesionId'], sesion['sesionId']);
      expect(asistencia['estudianteId'], estudiante['estudianteId']);
      expect(participacion['sesionId'], sesion['sesionId']);
      expect(participacion['estudianteId'], estudiante['estudianteId']);
      expect(participacion['actividadId'], actividad['actividadId']);
      expect(participacion['puntos'], 3);
      expect('${grupo['grupoId']}', matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(await migratedDb.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    } finally {
      await helper.closeForTesting();
      await directory.delete(recursive: true);
    }
  });

  test('restaura backups antiguos remapeando IDs numéricos a UUID', () async {
    final directory = await Directory.systemTemp.createTemp('aula-puntos-backup-');
    final path = '${directory.path}${Platform.pathSeparator}restored.db';
    final helper = DatabaseHelper.forTesting(path);

    try {
      await helper.restaurarDesdeBackup({
        'tablas': {
          'instructores': [
            {'instructorId': 7, 'nombres': 'Ana', 'apellidos': 'Instructora', 'correo': 'ana@example.test'},
          ],
          'grupos': [
            {
              'grupoId': 4,
              'codigo': 'G-1',
              'nombre': 'Grupo Uno',
              'programa': 'P1',
              'asignatura': 'Bases de datos',
              'periodo': '2026-1',
              'seccion': 'A',
              'instructorId': 7,
            },
          ],
          'estudiantes': [
            {'estudianteId': 9, 'codigoInstitucional': 'SEN-001', 'nombres': 'Luis', 'apellidos': 'Pérez'},
          ],
          'grupo_estudiantes': [
            {'grupoId': 4, 'estudianteId': 9, 'fechaIncorporacion': '2026-01-01'},
          ],
          'sesiones': [
            {
              'sesionId': 2,
              'grupoId': 4,
              'numeroSesion': 1,
              'fecha': '2026-01-01',
              'tema': 'Introducción',
              'tipoSesion': 'Teoría',
              'duracionHoras': 2,
              'observaciones': '',
            },
          ],
          'asistencias': [
            {
              'asistenciaId': 1,
              'sesionId': 2,
              'estudianteId': 9,
              'estado': 'Presente',
              'fechaRegistro': '2026-01-01T08:00:00',
              'observacion': '',
            },
          ],
          'actividades': [
            {'actividadId': 3, 'nombre': 'Participación', 'descripcion': '', 'valorDefecto': 1},
          ],
          'participaciones': [
            {
              'participacionId': 5,
              'sesionId': 2,
              'estudianteId': 9,
              'actividadId': 3,
              'puntos': 2,
              'fecha': '2026-01-01T08:30:00',
              'uuidTransaccion': 'legacy-transaction',
            },
          ],
        },
      });

      final db = await helper.database;
      final instructor = (await db.query('instructores')).single;
      final grupo = (await db.query('grupos')).single;
      final estudiante = (await db.query('estudiantes')).single;
      final sesion = (await db.query('sesiones')).single;
      final asistencia = (await db.query('asistencias')).single;
      final actividad = (await db.query('actividades')).single;
      final participacion = (await db.query('participaciones')).single;

      expect(grupo['instructorId'], instructor['instructorId']);
      expect(asistencia['sesionId'], sesion['sesionId']);
      expect(asistencia['estudianteId'], estudiante['estudianteId']);
      expect(participacion['sesionId'], sesion['sesionId']);
      expect(participacion['estudianteId'], estudiante['estudianteId']);
      expect(participacion['actividadId'], actividad['actividadId']);
      expect(participacion['uuidTransaccion'], 'legacy-transaction');
      expect('${participacion['participacionId']}', matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    } finally {
      await helper.closeForTesting();
      await directory.delete(recursive: true);
    }
  });
}