import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';

import 'package:aula_puntos_senati/features/attendance/domain/entities/asistencia.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/estudiante.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/instructor.dart';
import 'package:aula_puntos_senati/features/points/domain/entities/actividad.dart';
import 'package:aula_puntos_senati/features/points/domain/entities/participacion.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static const String _dbName = 'aula_puntos_senati.db';
  static const int _dbVersion = 2;
  static const Uuid _uuid = Uuid();

  DatabaseHelper._internal() : _databasePathOverride = null;

  @visibleForTesting
  DatabaseHelper.forTesting(String databasePath) : _databasePathOverride = databasePath;

  static final DatabaseHelper instance = DatabaseHelper._internal();

  final String? _databasePathOverride;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePathOverride = _databasePathOverride;
    if (databasePathOverride != null) {
      return openDatabase(
        databasePathOverride,
        version: _dbVersion,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // 1. Soporte para Navegadores Web (Chrome, Edge, Firefox) mediante WebAssembly
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        _dbName,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // 2. Soporte para Escritorio (Windows/Linux/macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 3. Soporte para Móvil (Android/iOS)
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await SeedData.insert(db);
  }

  Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE instructores (
        instructorId TEXT PRIMARY KEY NOT NULL,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        correo TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE grupos (
        grupoId TEXT PRIMARY KEY NOT NULL,
        codigo TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        programa TEXT NOT NULL,
        asignatura TEXT NOT NULL,
        periodo TEXT NOT NULL,
        seccion TEXT NOT NULL,
        instructorId TEXT,
        FOREIGN KEY (instructorId) REFERENCES instructores (instructorId) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE estudiantes (
        estudianteId TEXT PRIMARY KEY NOT NULL,
        codigoInstitucional TEXT UNIQUE NOT NULL,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE grupo_estudiantes (
        grupoId TEXT NOT NULL,
        estudianteId TEXT NOT NULL,
        fechaIncorporacion TEXT NOT NULL,
        PRIMARY KEY (grupoId, estudianteId),
        FOREIGN KEY (grupoId) REFERENCES grupos (grupoId) ON DELETE CASCADE,
        FOREIGN KEY (estudianteId) REFERENCES estudiantes (estudianteId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sesiones (
        sesionId TEXT PRIMARY KEY NOT NULL,
        grupoId TEXT NOT NULL,
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
        asistenciaId TEXT PRIMARY KEY NOT NULL,
        sesionId TEXT NOT NULL,
        estudianteId TEXT NOT NULL,
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
        actividadId TEXT PRIMARY KEY NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        valorDefecto INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE participaciones (
        participacionId TEXT PRIMARY KEY NOT NULL,
        sesionId TEXT NOT NULL,
        estudianteId TEXT NOT NULL,
        actividadId TEXT NOT NULL,
        puntos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        uuidTransaccion TEXT UNIQUE NOT NULL,
        FOREIGN KEY (sesionId) REFERENCES sesiones (sesionId) ON DELETE CASCADE,
        FOREIGN KEY (estudianteId) REFERENCES estudiantes (estudianteId) ON DELETE CASCADE,
        FOREIGN KEY (actividadId) REFERENCES actividades (actividadId) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateIntegerIdsToUuids(db);
  }

  Future<void> _migrateIntegerIdsToUuids(DatabaseExecutor db) async {
    const tableNames = [
      'instructores',
      'grupos',
      'estudiantes',
      'grupo_estudiantes',
      'sesiones',
      'asistencias',
      'actividades',
      'participaciones',
    ];
    final oldRows = <String, List<Map<String, dynamic>>>{};
    for (final tableName in tableNames) {
      oldRows[tableName] = await db.query(tableName);
    }

    Map<Object?, String> idMap(String tableName, String key) {
      final result = <Object?, String>{};
      for (final row in oldRows[tableName]!) {
        result[row[key]] = _uuid.v4();
      }
      return result;
    }

    final instructorIds = idMap('instructores', 'instructorId');
    final groupIds = idMap('grupos', 'grupoId');
    final studentIds = idMap('estudiantes', 'estudianteId');
    final sessionIds = idMap('sesiones', 'sesionId');
    final attendanceIds = idMap('asistencias', 'asistenciaId');
    final activityIds = idMap('actividades', 'actividadId');
    final participationIds = idMap('participaciones', 'participacionId');

    for (final tableName in [
      'participaciones',
      'asistencias',
      'grupo_estudiantes',
      'sesiones',
      'grupos',
      'estudiantes',
      'instructores',
      'actividades',
    ]) {
      await db.delete(tableName);
    }
    for (final tableName in [
      'participaciones',
      'asistencias',
      'grupo_estudiantes',
      'sesiones',
      'grupos',
      'estudiantes',
      'instructores',
      'actividades',
    ]) {
      await db.execute('DROP TABLE $tableName');
    }
    await _createTables(db);

    for (final row in oldRows['instructores']!) {
      await db.insert('instructores', {
        ...row,
        'instructorId': instructorIds[row['instructorId']],
      });
    }
    for (final row in oldRows['grupos']!) {
      await db.insert('grupos', {
        ...row,
        'grupoId': groupIds[row['grupoId']],
        'instructorId': row['instructorId'] == null ? null : instructorIds[row['instructorId']],
      });
    }
    for (final row in oldRows['estudiantes']!) {
      await db.insert('estudiantes', {
        ...row,
        'estudianteId': studentIds[row['estudianteId']],
      });
    }
    for (final row in oldRows['grupo_estudiantes']!) {
      await db.insert('grupo_estudiantes', {
        ...row,
        'grupoId': groupIds[row['grupoId']],
        'estudianteId': studentIds[row['estudianteId']],
      });
    }
    for (final row in oldRows['sesiones']!) {
      await db.insert('sesiones', {
        ...row,
        'sesionId': sessionIds[row['sesionId']],
        'grupoId': groupIds[row['grupoId']],
      });
    }
    for (final row in oldRows['asistencias']!) {
      await db.insert('asistencias', {
        ...row,
        'asistenciaId': attendanceIds[row['asistenciaId']],
        'sesionId': sessionIds[row['sesionId']],
        'estudianteId': studentIds[row['estudianteId']],
      });
    }
    for (final row in oldRows['actividades']!) {
      await db.insert('actividades', {
        ...row,
        'actividadId': activityIds[row['actividadId']],
      });
    }
    for (final row in oldRows['participaciones']!) {
      await db.insert('participaciones', {
        ...row,
        'participacionId': participationIds[row['participacionId']],
        'sesionId': sessionIds[row['sesionId']],
        'estudianteId': studentIds[row['estudianteId']],
        'actividadId': activityIds[row['actividadId']],
      });
    }
  }

  // ==========================================
  // COPIA DE SEGURIDAD Y RESTAURACIÓN (BACKUP & RESTORE)
  // ==========================================

  Future<String> getDatabasePathString() async {
    if (kIsWeb) return 'IndexedDB (Almacenamiento Local de Chrome)';
    final String dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }

  Future<int> getDatabaseFileSize() async {
    if (kIsWeb) return 1024 * 64; // Tamaño estimado en navegador Web
    try {
      final path = await getDatabasePathString();
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  /// Exporta un volcado completo de las 8 tablas relacionales en formato estructurado JSON.
  Future<Map<String, dynamic>> exportarBackupCompleto() async {
    final db = await database;

    final instructores = await db.query('instructores');
    final grupos = await db.query('grupos');
    final estudiantes = await db.query('estudiantes');
    final grupoEstudiantes = await db.query('grupo_estudiantes');
    final sesiones = await db.query('sesiones');
    final asistencias = await db.query('asistencias');
    final actividades = await db.query('actividades');
    final participaciones = await db.query('participaciones');

    return {
      'sistema': 'Aula Puntos - SENATI',
      'version': _dbVersion,
      'fechaBackup': DateTime.now().toIso8601String(),
      'tablas': {
        'instructores': instructores,
        'grupos': grupos,
        'estudiantes': estudiantes,
        'grupo_estudiantes': grupoEstudiantes,
        'sesiones': sesiones,
        'asistencias': asistencias,
        'actividades': actividades,
        'participaciones': participaciones,
      },
      'conteos': {
        'instructores': instructores.length,
        'grupos': grupos.length,
        'estudiantes': estudiantes.length,
        'sesiones': sesiones.length,
        'asistencias': asistencias.length,
        'participaciones': participaciones.length,
      }
    };
  }

  /// Restaura la base de datos a partir de una copia de seguridad JSON garantizando integridad referencial
  Future<Map<String, int>> restaurarDesdeBackup(Map<String, dynamic> backupData) async {
    final tablas = backupData['tablas'] as Map<String, dynamic>?;
    if (tablas == null) {
      throw const FormatException('El formato del archivo de respaldo es inválido (no contiene "tablas").');
    }

    final db = await database;
    final Map<String, int> restaurados = {};

    await db.transaction((txn) async {
      // 1. Limpieza de tablas hijas a padres para evitar violaciones de clave foránea
      await txn.delete('participaciones');
      await txn.delete('asistencias');
      await txn.delete('sesiones');
      await txn.delete('grupo_estudiantes');
      await txn.delete('estudiantes');
      await txn.delete('grupos');
      await txn.delete('instructores');
      await txn.delete('actividades');

      final instructorIds = _backupIdMap(tablas['instructores'] as List?, 'instructorId');
      final groupIds = _backupIdMap(tablas['grupos'] as List?, 'grupoId');
      final studentIds = _backupIdMap(tablas['estudiantes'] as List?, 'estudianteId');
      final sessionIds = _backupIdMap(tablas['sesiones'] as List?, 'sesionId');
      final attendanceIds = _backupIdMap(tablas['asistencias'] as List?, 'asistenciaId');
      final activityIds = _backupIdMap(tablas['actividades'] as List?, 'actividadId');
      final participationIds = _backupIdMap(tablas['participaciones'] as List?, 'participacionId');

      Map<String, dynamic> remap(Map<String, dynamic> row, Map<String, Object?> ids) {
        final result = Map<String, dynamic>.from(row);
        for (final entry in ids.entries) {
          final oldId = row[entry.key];
          if (oldId == null) {
            result[entry.key] = null;
          } else {
            final newId = entry.value is Map<Object?, String>
                ? (entry.value as Map<Object?, String>)[oldId]
                : null;
            if (newId == null) {
              throw FormatException('El respaldo contiene una referencia inválida en ${entry.key}.');
            }
            result[entry.key] = newId;
          }
        }
        return result;
      }

      List<Map<String, dynamic>> rows(String tableName, Map<String, Object?> ids) {
        final rawRows = tablas[tableName] as List? ?? const [];
        return rawRows.whereType<Map>().map((row) {
          return remap(Map<String, dynamic>.from(row), ids);
        }).toList();
      }

      // 2. Inserción de tablas padres a hijas
      Future<int> insertarFilas(String tabla, List<dynamic>? filas) async {
        if (filas == null) return 0;
        int count = 0;
        for (final fila in filas) {
          if (fila is Map<String, dynamic>) {
            await txn.insert(tabla, fila, conflictAlgorithm: ConflictAlgorithm.replace);
            count++;
          }
        }
        return count;
      }

      restaurados['instructores'] = await insertarFilas('instructores', rows('instructores', {'instructorId': instructorIds}));
      restaurados['actividades'] = await insertarFilas('actividades', rows('actividades', {'actividadId': activityIds}));
      restaurados['grupos'] = await insertarFilas('grupos', rows('grupos', {
        'grupoId': groupIds,
        'instructorId': instructorIds,
      }));
      restaurados['estudiantes'] = await insertarFilas('estudiantes', rows('estudiantes', {'estudianteId': studentIds}));
      restaurados['grupo_estudiantes'] = await insertarFilas('grupo_estudiantes', rows('grupo_estudiantes', {
        'grupoId': groupIds,
        'estudianteId': studentIds,
      }));
      restaurados['sesiones'] = await insertarFilas('sesiones', rows('sesiones', {
        'sesionId': sessionIds,
        'grupoId': groupIds,
      }));
      restaurados['asistencias'] = await insertarFilas('asistencias', rows('asistencias', {
        'asistenciaId': attendanceIds,
        'sesionId': sessionIds,
        'estudianteId': studentIds,
      }));
      restaurados['participaciones'] = await insertarFilas('participaciones', rows('participaciones', {
        'participacionId': participationIds,
        'sesionId': sessionIds,
        'estudianteId': studentIds,
        'actividadId': activityIds,
      }));
    });

    return restaurados;
  }

  Map<Object?, String> _backupIdMap(List? rows, String key) {
    final result = <Object?, String>{};
    for (final row in rows ?? const []) {
      if (row is Map && row[key] != null) {
        result[row[key]] = _uuid.v4();
      }
    }
    return result;
  }

  /// Restablece la base de datos al estado inicial de fábrica con datos SENATI
  Future<void> reiniciarBaseDeDatos() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('participaciones');
      await txn.delete('asistencias');
      await txn.delete('sesiones');
      await txn.delete('grupo_estudiantes');
      await txn.delete('estudiantes');
      await txn.delete('grupos');
      await txn.delete('instructores');
      await txn.delete('actividades');
      await SeedData.insert(txn);
    });
  }

  Future<List<Instructor>> getInstructores() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('instructores');
    return maps.map((e) => Instructor.fromMap(e)).toList();
  }

  Future<String> insertInstructor(Instructor instructor) async {
    final db = await database;
    final id = instructor.instructorId ?? _uuid.v4();
    await db.insert('instructores', {
      ...instructor.toMap(),
      'instructorId': id,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  // ==========================================
  // OPERACIONES CRUD: GRUPOS
  // ==========================================

  Future<List<Grupo>> getGrupos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grupos', orderBy: 'grupoId DESC');
    return maps.map((e) => Grupo.fromMap(e)).toList();
  }

  Future<Grupo?> getGrupoById(String id) async {
    final db = await database;
    final maps = await db.query('grupos', where: 'grupoId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Grupo.fromMap(maps.first);
    return null;
  }

  Future<String> insertGrupo(Grupo grupo) async {
    final db = await database;
    final id = grupo.grupoId ?? _uuid.v4();
    await db.insert('grupos', {...grupo.toMap(), 'grupoId': id});
    return id;
  }

  Future<int> updateGrupo(Grupo grupo) async {
    final db = await database;
    return await db.update(
      'grupos',
      grupo.toMap(),
      where: 'grupoId = ?',
      whereArgs: [grupo.grupoId],
    );
  }

  Future<int> deleteGrupo(String id) async {
    final db = await database;
    return await db.delete('grupos', where: 'grupoId = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD: ESTUDIANTES Y MATRÍCULA
  // ==========================================

  Future<List<Estudiante>> getEstudiantesByGrupo(String grupoId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT e.* FROM estudiantes e
      INNER JOIN grupo_estudiantes ge ON e.estudianteId = ge.estudianteId
      WHERE ge.grupoId = ?
      ORDER BY e.apellidos ASC, e.nombres ASC
    ''', [grupoId]);
    return results.map((e) => Estudiante.fromMap(e)).toList();
  }

  Future<String> insertEstudiante(Estudiante estudiante) async {
    final db = await database;
    final id = estudiante.estudianteId ?? _uuid.v4();
    await db.insert('estudiantes', {
      ...estudiante.toMap(),
      'estudianteId': id,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> vincularEstudianteAGrupo(String grupoId, String estudianteId) async {
    final db = await database;
    await db.insert('grupo_estudiantes', {
      'grupoId': grupoId,
      'estudianteId': estudianteId,
      'fechaIncorporacion': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Importa masivamente estudiantes desde texto CSV hacia un grupo en SQLite.
  /// Formato soportado por línea:
  /// CODIGO, APELLIDOS, NOMBRES  (o separado por ;)
  Future<Map<String, int>> importarAlumnosDesdeCsv({
    required String grupoId,
    required String csvContenido,
  }) async {
    final db = await database;
    final lineas = csvContenido.split('\n');
    int importados = 0;
    int ignorados = 0;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (var rawLinea in lineas) {
        final linea = rawLinea.trim();
        if (linea.isEmpty) continue;

        // Separar por coma o punto y coma
        final separador = linea.contains(';') ? ';' : ',';
        final partes = linea.split(separador).map((e) => e.replaceAll('"', '').trim()).toList();

        if (partes.length < 3) {
          ignorados++;
          continue;
        }

        final codigo = partes[0];
        final apellidos = partes[1];
        final nombres = partes[2];

        // Ignorar encabezados típicos
        if (codigo.toLowerCase().contains('cod') ||
            codigo.toLowerCase().contains('id') ||
            apellidos.toLowerCase().contains('apellido')) {
          continue;
        }

        // Buscar si ya existe el estudiante por su código institucional
        final existentes = await txn.query(
          'estudiantes',
          where: 'codigoInstitucional = ?',
          whereArgs: [codigo],
        );

        String estudianteId;
        if (existentes.isNotEmpty) {
          estudianteId = existentes.first['estudianteId'] as String;
          // Actualizar nombres si cambiaron
          await txn.update(
            'estudiantes',
            {'apellidos': apellidos, 'nombres': nombres},
            where: 'estudianteId = ?',
            whereArgs: [estudianteId],
          );
        } else {
          estudianteId = _uuid.v4();
          await txn.insert('estudiantes', {
            'estudianteId': estudianteId,
            'codigoInstitucional': codigo,
            'apellidos': apellidos,
            'nombres': nombres,
          });
        }

        // Vincular al grupo
        await txn.insert('grupo_estudiantes', {
          'grupoId': grupoId,
          'estudianteId': estudianteId,
          'fechaIncorporacion': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Inicializar asistencias en las sesiones existentes de este grupo
        final sesiones = await txn.query('sesiones', where: 'grupoId = ?', whereArgs: [grupoId]);
        for (final s in sesiones) {
          final sId = s['sesionId'] as String;
          await txn.insert('asistencias', {
            'asistenciaId': _uuid.v4(),
            'sesionId': sId,
            'estudianteId': estudianteId,
            'estado': 'Presente',
            'fechaRegistro': now,
            'observacion': 'Importado vía CSV',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        importados++;
      }
    });

    return {'importados': importados, 'ignorados': ignorados};
  }

  /// Genera el contenido CSV del padrón de alumnos de un grupo
  Future<String> exportarAlumnosACsv(String grupoId) async {
    final estudiantes = await getEstudiantesByGrupo(grupoId);
    final buffer = StringBuffer();
    buffer.writeln('CODIGO,APELLIDOS,NOMBRES');
    for (final e in estudiantes) {
      buffer.writeln('${e.codigoInstitucional},"${e.apellidos}","${e.nombres}"');
    }
    return buffer.toString();
  }

  // ==========================================
  // OPERACIONES CRUD: SESIONES
  // ==========================================

  Future<List<Sesion>> getSesionesByGrupo(String grupoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sesiones',
      where: 'grupoId = ?',
      whereArgs: [grupoId],
      orderBy: 'numeroSesion ASC',
    );
    return maps.map((e) => Sesion.fromMap(e)).toList();
  }

  Future<Sesion?> getSesionById(String id) async {
    final db = await database;
    final maps = await db.query('sesiones', where: 'sesionId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Sesion.fromMap(maps.first);
    return null;
  }

  Future<String> insertSesion(Sesion sesion) async {
    final db = await database;
    final id = sesion.sesionId ?? _uuid.v4();
    await db.insert('sesiones', {...sesion.toMap(), 'sesionId': id});

    // Al crear una sesión, inicializamos automáticamente la lista de asistencias en 'Presente' por defecto
    final estudiantes = await getEstudiantesByGrupo(sesion.grupoId);
    final now = DateTime.now().toIso8601String();
    for (final est in estudiantes) {
      if (est.estudianteId != null) {
        await db.insert('asistencias', {
          'asistenciaId': _uuid.v4(),
          'sesionId': id,
          'estudianteId': est.estudianteId,
          'estado': 'Presente',
          'fechaRegistro': now,
          'observacion': '',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    return id;
  }

  Future<int> updateSesion(Sesion sesion) async {
    final db = await database;
    return await db.update('sesiones', sesion.toMap(), where: 'sesionId = ?', whereArgs: [sesion.sesionId]);
  }

  Future<int> deleteSesion(String id) async {
    final db = await database;
    return await db.delete('sesiones', where: 'sesionId = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES: ASISTENCIAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getAsistenciasDetalladasBySesion(String sesionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        e.estudianteId,
        e.codigoInstitucional,
        e.nombres,
        e.apellidos,
        COALESCE(a.asistenciaId, '') as asistenciaId,
        COALESCE(a.estado, 'Falta') as estado,
        COALESCE(a.observacion, '') as observacion,
        COALESCE(a.fechaRegistro, '') as fechaRegistro
      FROM estudiantes e
      INNER JOIN grupo_estudiantes ge ON e.estudianteId = ge.estudianteId
      INNER JOIN sesiones s ON s.grupoId = ge.grupoId
      LEFT JOIN asistencias a ON a.sesionId = s.sesionId AND a.estudianteId = e.estudianteId
      WHERE s.sesionId = ?
      ORDER BY e.apellidos ASC, e.nombres ASC
    ''', [sesionId]);
  }

  Future<void> registrarOActualizarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String estado,
    String observacion = '',
  }) async {
    if (!Asistencia.estadosValidos.contains(estado)) {
      throw ArgumentError('Estado de asistencia inválido: $estado');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.rawInsert('''
      INSERT INTO asistencias (asistenciaId, sesionId, estudianteId, estado, fechaRegistro, observacion)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(sesionId, estudianteId) DO UPDATE SET
        estado = excluded.estado,
        fechaRegistro = excluded.fechaRegistro,
        observacion = excluded.observacion
    ''', [_uuid.v4(), sesionId, estudianteId, estado, now, observacion]);
  }

  Future<Map<String, int>> getResumenAsistenciaBySesion(String sesionId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT estado, COUNT(*) as cantidad
      FROM asistencias
      WHERE sesionId = ?
      GROUP BY estado
    ''', [sesionId]);

    final Map<String, int> resumen = {
      'Presente': 0,
      'Tardanza': 0,
      'Falta': 0,
      'Justificado': 0,
    };

    for (final row in results) {
      final estado = row['estado'] as String?;
      final cant = row['cantidad'] as int? ?? 0;
      if (estado != null && resumen.containsKey(estado)) {
        resumen[estado] = cant;
      }
    }
    return resumen;
  }

  // ==========================================
  // OPERACIONES: ACTIVIDADES Y PARTICIPACIONES
  // ==========================================

  Future<List<Actividad>> getActividades() async {
    final db = await database;
    final maps = await db.query('actividades', orderBy: 'actividadId ASC');
    return maps.map((e) => Actividad.fromMap(e)).toList();
  }

  Future<String> insertActividad(Actividad actividad) async {
    final db = await database;
    final id = actividad.actividadId ?? _uuid.v4();
    await db.insert('actividades', {...actividad.toMap(), 'actividadId': id});
    return id;
  }

  /// Registra una participación garantizando idempotencia mediante uuidTransaccion único.
  Future<String> registrarParticipacion({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
    String? uuidTransaccion,
  }) async {
    final db = await database;
    final uuid = uuidTransaccion ?? const Uuid().v4();
    final participacionId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final participacion = Participacion(
      participacionId: participacionId,
      sesionId: sesionId,
      estudianteId: estudianteId,
      actividadId: actividadId,
      puntos: puntos,
      fecha: now,
      uuidTransaccion: uuid,
    );

    await db.insert(
      'participaciones',
      participacion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // Rechaza duplicados si el uuid ya existe
    );
    return participacionId;
  }

  /// Deshace la última participación registrada en la sesión
  Future<Map<String, dynamic>?> deshacerUltimaParticipacion(String sesionId) async {
    final db = await database;
    final ultimas = await db.rawQuery('''
      SELECT p.*, e.nombres, e.apellidos, a.nombre as actividadNombre
      FROM participaciones p
      INNER JOIN estudiantes e ON e.estudianteId = p.estudianteId
      INNER JOIN actividades a ON a.actividadId = p.actividadId
      WHERE p.sesionId = ?
      ORDER BY p.participacionId DESC
      LIMIT 1
    ''', [sesionId]);

    if (ultimas.isEmpty) return null;

    final registro = ultimas.first;
    final int partId = registro['participacionId'] as int;

    await db.delete('participaciones', where: 'participacionId = ?', whereArgs: [partId]);
    return registro;
  }

  /// Elimina una participación específica por su ID
  Future<int> eliminarParticipacion(String participacionId) async {
    final db = await database;
    return await db.delete('participaciones', where: 'participacionId = ?', whereArgs: [participacionId]);
  }

  /// Obtiene el historial cronológico detallado de participaciones de una sesión
  Future<List<Map<String, dynamic>>> getHistorialParticipacionesBySesion(String sesionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.participacionId,
        p.puntos,
        p.fecha,
        p.uuidTransaccion,
        e.estudianteId,
        e.codigoInstitucional,
        e.nombres,
        e.apellidos,
        a.nombre as actividadNombre
      FROM participaciones p
      INNER JOIN estudiantes e ON e.estudianteId = p.estudianteId
      INNER JOIN actividades a ON a.actividadId = p.actividadId
      WHERE p.sesionId = ?
      ORDER BY p.participacionId DESC
    ''', [sesionId]);
  }

  /// Obtiene el Top Ranking de estudiantes con mayor puntaje en la sesión
  Future<List<Map<String, dynamic>>> getTopRankingSesion(String sesionId, {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        e.estudianteId,
        e.codigoInstitucional,
        e.nombres,
        e.apellidos,
        SUM(p.puntos) as totalPuntos,
        COUNT(p.participacionId) as totalIntervenciones
      FROM participaciones p
      INNER JOIN estudiantes e ON e.estudianteId = p.estudianteId
      WHERE p.sesionId = ?
      GROUP BY e.estudianteId
      HAVING totalPuntos > 0
      ORDER BY totalPuntos DESC, totalIntervenciones DESC
      LIMIT ?
    ''', [sesionId, limit]);
  }

  /// Retorna el puntaje acumulado de cada estudiante en una sesión particular.
  Future<Map<String, int>> getPuntosPorEstudiantesEnSesion(String sesionId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT estudianteId, COALESCE(SUM(puntos), 0) as totalPuntos
      FROM participaciones
      WHERE sesionId = ?
      GROUP BY estudianteId
    ''', [sesionId]);

    final Map<String, int> mapa = {};
    for (final row in results) {
      final estId = row['estudianteId'] as String;
      final total = (row['totalPuntos'] as num?)?.toInt() ?? 0;
      mapa[estId] = total;
    }
    return mapa;
  }

  /// Obtiene la lista de estudiantes con sus puntos y asistencia en una sesión para Puntuación Rápida
  Future<List<Map<String, dynamic>>> getEstudiantesConPuntosEnSesion(String sesionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        e.estudianteId,
        e.codigoInstitucional,
        e.nombres,
        e.apellidos,
        COALESCE(a.estado, 'Presente') as estadoAsistencia,
        COALESCE(puntos_sub.totalPuntos, 0) as totalPuntos
      FROM estudiantes e
      INNER JOIN grupo_estudiantes ge ON e.estudianteId = ge.estudianteId
      INNER JOIN sesiones s ON s.grupoId = ge.grupoId
      LEFT JOIN asistencias a ON a.sesionId = s.sesionId AND a.estudianteId = e.estudianteId
      LEFT JOIN (
        SELECT estudianteId, SUM(puntos) as totalPuntos
        FROM participaciones
        WHERE sesionId = ?
        GROUP BY estudianteId
      ) puntos_sub ON puntos_sub.estudianteId = e.estudianteId
      WHERE s.sesionId = ?
      ORDER BY e.apellidos ASC, e.nombres ASC
    ''', [sesionId, sesionId]);
  }

  // ==========================================
  // OPERACIONES: REPORTES Y CONSOLIDADO
  // ==========================================

  Future<List<Map<String, dynamic>>> getConsolidadoReporte({
    required String grupoId,
    String? sesionId,
  }) async {
    final db = await database;
    if (sesionId != null) {
      // Consolidado por sesión
      return await db.rawQuery('''
        SELECT 
          e.estudianteId,
          e.codigoInstitucional,
          e.nombres,
          e.apellidos,
          COALESCE(a.estado, 'Falta') as estadoAsistencia,
          COALESCE(SUM(p.puntos), 0) as totalPuntos,
          COUNT(p.participacionId) as cantidadParticipaciones
        FROM estudiantes e
        INNER JOIN grupo_estudiantes ge ON e.estudianteId = ge.estudianteId
        LEFT JOIN asistencias a ON a.estudianteId = e.estudianteId AND a.sesionId = ?
        LEFT JOIN participaciones p ON p.estudianteId = e.estudianteId AND p.sesionId = ?
        WHERE ge.grupoId = ?
        GROUP BY e.estudianteId
        ORDER BY e.apellidos ASC, e.nombres ASC
      ''', [sesionId, sesionId, grupoId]);
    } else {
      // Consolidado global de todo el grupo
      return await db.rawQuery('''
        SELECT 
          e.estudianteId,
          e.codigoInstitucional,
          e.nombres,
          e.apellidos,
          SUM(CASE WHEN a.estado = 'Presente' THEN 1 ELSE 0 END) as totalPresentes,
          SUM(CASE WHEN a.estado = 'Tardanza' THEN 1 ELSE 0 END) as totalTardanzas,
          SUM(CASE WHEN a.estado = 'Falta' THEN 1 ELSE 0 END) as totalFaltas,
          SUM(CASE WHEN a.estado = 'Justificado' THEN 1 ELSE 0 END) as totalJustificados,
          COALESCE(SUM(p.puntos), 0) as totalPuntos
        FROM estudiantes e
        INNER JOIN grupo_estudiantes ge ON e.estudianteId = ge.estudianteId
        LEFT JOIN sesiones s ON s.grupoId = ge.grupoId
        LEFT JOIN asistencias a ON a.estudianteId = e.estudianteId AND a.sesionId = s.sesionId
        LEFT JOIN participaciones p ON p.estudianteId = e.estudianteId AND p.sesionId = s.sesionId
        WHERE ge.grupoId = ?
        GROUP BY e.estudianteId
        ORDER BY e.apellidos ASC, e.nombres ASC
      ''', [grupoId]);
    }
  }

  // Métricas generales para el Dashboard
  Future<Map<String, int>> getDashboardMetrics() async {
    final db = await database;
    final gruposCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM grupos')) ?? 0;
    final estudiantesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM estudiantes')) ?? 0;
    final sesionesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sesiones')) ?? 0;
    final participacionesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM participaciones')) ?? 0;
    final totalPuntos = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(SUM(puntos), 0) FROM participaciones')) ?? 0;

    return {
      'grupos': gruposCount,
      'estudiantes': estudiantesCount,
      'sesiones': sesionesCount,
      'participaciones': participacionesCount,
      'totalPuntos': totalPuntos,
    };
  }
}
