import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';

class ExcelService {
  static Uint8List generarConsolidado({
    required Grupo grupo,
    Sesion? sesion,
    required List<Map<String, dynamic>> datos,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];
    excel.delete('Sheet1');

    sheet.appendRow([TextCellValue('AULA PUNTOS - SENATI')]);
    sheet.appendRow([TextCellValue('Asignatura'), TextCellValue(grupo.asignatura)]);
    sheet.appendRow([TextCellValue('Código'), TextCellValue(grupo.codigo)]);
    sheet.appendRow([TextCellValue('Sección'), TextCellValue(grupo.seccion)]);

    if (sesion != null) {
      sheet.appendRow([TextCellValue('Sesión'), IntCellValue(sesion.numeroSesion)]);
      sheet.appendRow([TextCellValue('Fecha'), TextCellValue(sesion.fecha)]);
      sheet.appendRow([TextCellValue('Tema'), TextCellValue(sesion.tema)]);
    }

    sheet.appendRow([TextCellValue('')]);

    final encabezados = sesion == null
        ? ['N°', 'Código', 'Apellidos y nombres', 'Presentes', 'Tardanzas', 'Faltas', 'Justificados', 'Puntos']
        : ['N°', 'Código', 'Apellidos y nombres', 'Asistencia', 'Puntos'];
    sheet.appendRow(encabezados.map(TextCellValue.new).toList());

    for (var index = 0; index < datos.length; index++) {
      final fila = datos[index];
      final celdas = <CellValue?>[
        IntCellValue(index + 1),
        TextCellValue('${fila['codigoInstitucional'] ?? ''}'),
        TextCellValue('${fila['apellidos'] ?? ''}, ${fila['nombres'] ?? ''}'),
      ];

      if (sesion == null) {
        celdas.addAll([
          IntCellValue(_intValue(fila['totalPresentes'])),
          IntCellValue(_intValue(fila['totalTardanzas'])),
          IntCellValue(_intValue(fila['totalFaltas'])),
          IntCellValue(_intValue(fila['totalJustificados'])),
        ]);
      } else {
        celdas.add(TextCellValue('${fila['estadoAsistencia'] ?? 'Falta'}'));
      }

      celdas.add(IntCellValue(_intValue(fila['totalPuntos'])));
      sheet.appendRow(celdas);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}