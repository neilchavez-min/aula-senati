import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static const Uuid _uuid = Uuid();

  static Future<void> insert(DatabaseExecutor db) async {
    final instructorId = _uuid.v4();
    await db.insert('instructores', {
      'instructorId': instructorId,
      'nombres': 'Carlos Alberto',
      'apellidos': 'Mendoza Ramos',
      'correo': 'cmendoza@senati.pe',
    });

    final actividades = [
      {
        'nombre': 'Participación en clase',
        'descripcion': 'Respuesta correcta o intervención en sesión teórica/práctica',
        'valorDefecto': 1,
      },
      {
        'nombre': 'Resolución de Laboratorio',
        'descripcion': 'Completitud y sustentación de guía de laboratorio práctico',
        'valorDefecto': 2,
      },
      {
        'nombre': 'Pregunta de Reto SENATI',
        'descripcion': 'Resolución de problema complejo planteado en clase',
        'valorDefecto': 3,
      },
    ];

    for (final actividad in actividades) {
      await db.insert('actividades', {
        ...actividad,
        'actividadId': _uuid.v4(),
      });
    }

    final grupoId = _uuid.v4();
    await db.insert('grupos', {
      'grupoId': grupoId,
      'codigo': '202601',
      'nombre': 'Monitores de Empresa - G1',
      'programa': '2026-20',
      'asignatura': 'FORMACIÓN MONITORES EMPRESA',
      'periodo': '2026-20',
      'seccion': '2026-20-202601',
      'instructorId': instructorId,
    });

    final estudiantes = [
      {'codigo': 'SEN-102931', 'nombres': 'Jean Pierre', 'apellidos': 'Quispe Flores'},
      {'codigo': 'SEN-102932', 'nombres': 'María Fernanda', 'apellidos': 'Rojas Castillo'},
      {'codigo': 'SEN-102933', 'nombres': 'Álvaro Daniel', 'apellidos': 'Gutiérrez Torres'},
      {'codigo': 'SEN-102934', 'nombres': 'Brenda Lucía', 'apellidos': 'Huamán Velarde'},
      {'codigo': 'SEN-102935', 'nombres': 'Christian José', 'apellidos': 'Salazar Morales'},
      {'codigo': 'SEN-102936', 'nombres': 'Valeria Sofía', 'apellidos': 'Cárdenas Peña'},
      {'codigo': 'SEN-102937', 'nombres': 'Kevin Anthony', 'apellidos': 'Vargas Medina'},
      {'codigo': 'SEN-102938', 'nombres': 'Diana Carolina', 'apellidos': 'Palacios Ramos'},
    ];

    final now = DateTime.now();
    final fechaRegistro = now.toIso8601String();
    final estudianteIds = <String>[];

    for (final estudiante in estudiantes) {
      final estudianteId = _uuid.v4();
      await db.insert('estudiantes', {
        'estudianteId': estudianteId,
        'codigoInstitucional': estudiante['codigo'],
        'nombres': estudiante['nombres'],
        'apellidos': estudiante['apellidos'],
      });
      estudianteIds.add(estudianteId);

      await db.insert('grupo_estudiantes', {
        'grupoId': grupoId,
        'estudianteId': estudianteId,
        'fechaIncorporacion': fechaRegistro,
      });
    }

    final sesionId = _uuid.v4();
    await db.insert('sesiones', {
      'sesionId': sesionId,
      'grupoId': grupoId,
      'numeroSesion': 1,
      'fecha': now.toIso8601String().split('T').first,
      'tema': 'Introducción al Rol del Monitor y Pedagogía Dual',
      'tipoSesion': 'Teoría',
      'duracionHoras': 4,
      'observaciones': 'Primera sesión presencial en aula tecnológica SENATI.',
    });

    for (var index = 0; index < estudianteIds.length; index++) {
      await db.insert('asistencias', {
        'asistenciaId': _uuid.v4(),
        'sesionId': sesionId,
        'estudianteId': estudianteIds[index],
        'estado': index == 3 ? 'Tardanza' : 'Presente',
        'fechaRegistro': fechaRegistro,
        'observacion': '',
      });
    }
  }
}