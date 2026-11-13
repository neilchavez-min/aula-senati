import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';

class PdfService {
  static const PdfColor senatiAzul = PdfColor.fromInt(0xFF003882);
  static const PdfColor senatiCeleste = PdfColor.fromInt(0xFF0B5CAD);
  static const PdfColor senatiGrisClaro = PdfColor.fromInt(0xFFF2F4F8);
  static const PdfColor senatiBorde = PdfColor.fromInt(0xFFD0D7DE);

  /// Genera y abre el diálogo de impresión / guardado del PDF institucional SENATI
  static Future<void> imprimirConsolidado({
    required Grupo grupo,
    Sesion? sesion,
    required List<Map<String, dynamic>> datos,
  }) async {
    final pdfBytes = await generarPdfConsolidado(
      grupo: grupo,
      sesion: sesion,
      datos: datos,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'SENATI_Reporte_${grupo.codigo}_${sesion != null ? "Sesion_${sesion.numeroSesion}" : "Consolidado"}.pdf',
    );
  }

  /// Construye el documento PDF con membrete institucional SENATI
  static Future<Uint8List> generarPdfConsolidado({
    required Grupo grupo,
    Sesion? sesion,
    required List<Map<String, dynamic>> datos,
  }) async {
    final pdf = pw.Document();
    final fechaGeneracion = DateTime.now().toString().substring(0, 16);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera institucional SENATI
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SENATI',
                        style: pw.TextStyle(
                          color: senatiAzul,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'DIRECCIÓN NACIONAL - ESCUELA DE TECNOLOGÍAS DE LA INFORMACIÓN',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 8,
                        ),
                      ),
                      pw.Text(
                        'SISTEMA AULA PUNTOS - CONTROL ACADÉMICO OFFLINE-FIRST',
                        style: const pw.TextStyle(
                          color: PdfColors.grey600,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: senatiAzul,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'REPORTE OFICIAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: senatiAzul, thickness: 1.5),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado el: $fechaGeneracion | Sistema Aula Puntos SENATI (Offline-First)',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Ficha de información del grupo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: senatiGrisClaro,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: senatiBorde),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _itemInfo('Asignatura:', grupo.asignatura),
                      ),
                      pw.Expanded(
                        child: _itemInfo('Código/NRC:', grupo.codigo),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _itemInfo('Programa/Periodo:', '${grupo.programa} / ${grupo.periodo}'),
                      ),
                      pw.Expanded(
                        child: _itemInfo('Sección:', grupo.seccion),
                      ),
                    ],
                  ),
                  if (sesion != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _itemInfo('Sesión N°:', '${sesion.numeroSesion} (${sesion.tipoSesion} - ${sesion.duracionHoras}h)'),
                        ),
                        pw.Expanded(
                          child: _itemInfo('Fecha de Sesión:', sesion.fecha),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    _itemInfo('Tema:', sesion.tema),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Título de la tabla
            pw.Text(
              sesion != null ? 'CONSOLIDADO DE ASISTENCIA Y PUNTOS DE LA SESIÓN' : 'RESUMEN ACUMULADO GENERAL DEL GRUPO',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: senatiAzul,
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabla de datos
            pw.Table(
              border: pw.TableBorder.all(color: senatiBorde, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // N°
                1: const pw.FixedColumnWidth(75), // Código
                2: const pw.FlexColumnWidth(3),   // Apellidos y Nombres
                3: const pw.FlexColumnWidth(2),   // Asistencia / Desglose
                4: const pw.FixedColumnWidth(55), // Puntos
              },
              children: [
                // Cabecera de tabla
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: senatiAzul),
                  children: [
                    _th('#'),
                    _th('CÓDIGO'),
                    _th('ESTUDIANTE (APELLIDOS Y NOMBRES)'),
                    _th(sesion != null ? 'ASISTENCIA' : 'ASISTENCIAS (P/T/F/J)'),
                    _th('PUNTOS'),
                  ],
                ),
                // Filas
                ...datos.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  final esPar = entry.key % 2 == 0;
                  final bg = esPar ? PdfColors.white : const PdfColor.fromInt(0xFFFAFAFA);

                  String detalleAsistencia = '';
                  if (sesion != null) {
                    detalleAsistencia = (item['estadoAsistencia'] as String?) ?? 'Falta';
                  } else {
                    final p = item['totalPresentes'] ?? 0;
                    final t = item['totalTardanzas'] ?? 0;
                    final f = item['totalFaltas'] ?? 0;
                    final j = item['totalJustificados'] ?? 0;
                    detalleAsistencia = 'P:$p  T:$t  F:$f  J:$j';
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _td('$i', align: pw.TextAlign.center),
                      _td(item['codigoInstitucional'] ?? '', align: pw.TextAlign.center),
                      _td('${item['apellidos']}, ${item['nombres']}'),
                      _td(detalleAsistencia, align: pw.TextAlign.center),
                      _td('${item['totalPuntos'] ?? 0} pts', align: pw.TextAlign.center, bold: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),
            // Firmas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text('Firma del Instructor', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('SENATI - Sede Central', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text('Coordinación Académica TI', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('SENATI', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _itemInfo(String label, String valor) {
    return pw.RichText(
      text: pw.TextSpan(
        text: '$label ',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: senatiAzul),
        children: [
          pw.TextSpan(
            text: valor,
            style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 9, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Genera texto formateado para exportación a Excel / CSV y WhatsApp
  static String generarCsvTexto({
    required Grupo grupo,
    Sesion? sesion,
    required List<Map<String, dynamic>> datos,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== REPORTE AULA PUNTOS - SENATI ===');
    buffer.writeln('Asignatura: ${grupo.asignatura}');
    buffer.writeln('Código/NRC: ${grupo.codigo} | Sección: ${grupo.seccion}');
    if (sesion != null) {
      buffer.writeln('Sesión N°: ${sesion.numeroSesion} - Fecha: ${sesion.fecha}');
      buffer.writeln('Tema: ${sesion.tema}');
      buffer.writeln('----------------------------------------');
      buffer.writeln('N°,CÓDIGO,APELLIDOS Y NOMBRES,ASISTENCIA,PUNTOS');
      for (int i = 0; i < datos.length; i++) {
        final d = datos[i];
        final estado = d['estadoAsistencia'] ?? 'Falta';
        final puntos = d['totalPuntos'] ?? 0;
        buffer.writeln('${i + 1},${d['codigoInstitucional']},"${d['apellidos']}, ${d['nombres']}",$estado,$puntos');
      }
    } else {
      buffer.writeln('CONSOLIDADO GENERAL DEL GRUPO');
      buffer.writeln('----------------------------------------');
      buffer.writeln('N°,CÓDIGO,APELLIDOS Y NOMBRES,PRESENTES,TARDANZAS,FALTAS,JUSTIFICADOS,PUNTOS_TOTAL');
      for (int i = 0; i < datos.length; i++) {
        final d = datos[i];
        final p = d['totalPresentes'] ?? 0;
        final t = d['totalTardanzas'] ?? 0;
        final f = d['totalFaltas'] ?? 0;
        final j = d['totalJustificados'] ?? 0;
        final puntos = d['totalPuntos'] ?? 0;
        buffer.writeln('${i + 1},${d['codigoInstitucional']},"${d['apellidos']}, ${d['nombres']}",$p,$t,$f,$j,$puntos');
      }
    }
    return buffer.toString();
  }
}
