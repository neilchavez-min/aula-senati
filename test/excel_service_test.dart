import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula_puntos_senati/models/grupo.dart';
import 'package:aula_puntos_senati/services/excel_service.dart';

void main() {
  test('genera un archivo Excel con los datos del consolidado', () {
    final grupo = Grupo(
      codigo: '202601',
      nombre: 'Grupo de prueba',
      programa: '2026-20',
      asignatura: 'Formación técnica',
      periodo: '2026-20',
      seccion: 'G1',
    );

    final bytes = ExcelService.generarConsolidado(
      grupo: grupo,
      datos: [
        {
          'codigoInstitucional': 'SEN-001',
          'apellidos': 'Pérez',
          'nombres': 'Ana',
          'totalPresentes': 3,
          'totalTardanzas': 1,
          'totalFaltas': 0,
          'totalJustificados': 0,
          'totalPuntos': 5,
        },
      ],
    );
    final workbook = Excel.decodeBytes(bytes);
    final rows = workbook.tables['Reporte']!.rows;

    expect((rows[5][0]?.value as TextCellValue).value.toString(), contains('N°'));
    expect((rows[6][1]?.value as TextCellValue).value.toString(), contains('SEN-001'));
    expect((rows[6][7]?.value as IntCellValue).value, 5);
  });
}