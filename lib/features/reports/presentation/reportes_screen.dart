import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/usecases/groups_use_cases.dart';
import 'package:aula_puntos_senati/features/reports/domain/usecases/reports_use_cases.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';
import 'package:aula_puntos_senati/features/sessions/domain/usecases/sessions_use_cases.dart';
import 'package:aula_puntos_senati/features/reports/data/exporters/excel_service.dart';
import 'package:aula_puntos_senati/features/reports/data/exporters/pdf_service.dart';
import 'package:share_plus/share_plus.dart';

class ReportesScreen extends StatefulWidget {
  final Grupo? grupoInicial;

  const ReportesScreen({super.key, this.grupoInicial});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  GroupsUseCases get _groups => context.read<GroupsUseCases>();
  SessionsUseCases get _sessions => context.read<SessionsUseCases>();
  ReportsUseCases get _reports => context.read<ReportsUseCases>();

  List<Grupo> _grupos = [];
  Grupo? _grupoSeleccionado;

  List<Sesion> _sesiones = [];
  Sesion? _sesionSeleccionada; // null = Todas las sesiones (Consolidado General)

  List<Map<String, dynamic>> _datosReporte = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    setState(() => _isLoading = true);
    final grupos = await _groups.getGrupos();
    _grupos = grupos;

    if (widget.grupoInicial != null) {
      _grupoSeleccionado = grupos.firstWhere(
        (g) => g.grupoId == widget.grupoInicial!.grupoId,
        orElse: () => grupos.isNotEmpty ? grupos.first : widget.grupoInicial!,
      );
    } else if (grupos.isNotEmpty) {
      _grupoSeleccionado = grupos.first;
    }

    if (_grupoSeleccionado != null && _grupoSeleccionado!.grupoId != null) {
      await _cargarSesionesYReporte(_grupoSeleccionado!.grupoId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSesionesYReporte(String grupoId) async {
    final sesiones = await _sessions.getSesionesByGrupo(grupoId);
    _sesiones = sesiones;
    _sesionSeleccionada = null; // Inicializar en consolidado general
    await _generarVistaReporte();
  }

  Future<void> _generarVistaReporte() async {
    if (_grupoSeleccionado == null || _grupoSeleccionado!.grupoId == null) {
      setState(() {
        _datosReporte = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final datos = await _reports.getConsolidadoReporte(
      grupoId: _grupoSeleccionado!.grupoId!,
      sesionId: _sesionSeleccionada?.sesionId,
    );

    setState(() {
      _datosReporte = datos;
      _isLoading = false;
    });
  }

  void _exportarPdf() async {
    if (_grupoSeleccionado == null) return;
    try {
      await PdfService.imprimirConsolidado(
        grupo: _grupoSeleccionado!,
        sesion: _sesionSeleccionada,
        datos: _datosReporte,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarExcel() async {
    final grupo = _grupoSeleccionado;
    if (grupo == null) return;

    try {
      final bytes = ExcelService.generarConsolidado(
        grupo: grupo,
        sesion: _sesionSeleccionada,
        datos: _datosReporte,
      );
      final tipoReporte = _sesionSeleccionada == null
          ? 'Consolidado'
          : 'Sesion_${_sesionSeleccionada!.numeroSesion}';
      final nombreArchivo = 'Aula_Puntos_${grupo.codigo}_$tipoReporte.xlsx';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: nombreArchivo,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: 'Reporte Aula Puntos SENATI - ${grupo.asignatura}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _compartirExcelWhatsApp() {
    if (_grupoSeleccionado == null) return;

    final csvTexto = PdfService.generarCsvTexto(
      grupo: _grupoSeleccionado!,
      sesion: _sesionSeleccionada,
      datos: _datosReporte,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.share, color: Color(0xFF003882), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exportar Excel / WhatsApp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Texto en formato CSV listo para WhatsApp o Excel:',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SelectableText(
                        csvTexto,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar al Portapapeles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003882),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: csvTexto));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reporte copiado. Listo para pegar en Excel o WhatsApp.'),
                        backgroundColor: Color(0xFF007A33),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Exportación SENATI'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF Oficial',
            onPressed: _datosReporte.isEmpty ? null : _exportarPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Exportar archivo Excel',
            onPressed: _datosReporte.isEmpty ? null : _exportarExcel,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Exportar Excel / WhatsApp',
            onPressed: _datosReporte.isEmpty ? null : _compartirExcelWhatsApp,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros responsivos con isExpanded garantizado
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<Grupo>(
                  isExpanded: true,
                  value: _grupoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Grupo',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: _grupos.map((g) {
                    return DropdownMenuItem<Grupo>(
                      value: g,
                      child: Text(
                        '${g.codigo} - ${g.asignatura}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (g) {
                    if (g != null && g.grupoId != null) {
                      setState(() => _grupoSeleccionado = g);
                      _cargarSesionesYReporte(g.grupoId!);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Sesion?>(
                  isExpanded: true,
                  value: _sesionSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Filtro de Sesión',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<Sesion?>(
                      value: null,
                      child: Text(
                        'Todas las sesiones (Consolidado General)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._sesiones.map((s) {
                      return DropdownMenuItem<Sesion?>(
                        value: s,
                        child: Text(
                          'Sesión ${s.numeroSesion}: ${s.tema}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (s) {
                    setState(() => _sesionSeleccionada = s);
                    _generarVistaReporte();
                  },
                ),
              ],
            ),
          ),

          // Botones de Acción Rápida (PDF / Excel WhatsApp) responsivos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003882),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text(
                      'Exportar PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _datosReporte.isEmpty ? null : _exportarPdf,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003882),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      side: const BorderSide(color: Color(0xFF003882)),
                    ),
                    icon: const Icon(Icons.table_chart, size: 16),
                    label: const Text(
                      'CSV / WhatsApp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _datosReporte.isEmpty ? null : _compartirExcelWhatsApp,
                  ),
                ),
              ],
            ),
          ),

          // Vista preliminar del consolidado responsivo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _datosReporte.isEmpty
                    ? Center(
                        child: Text(
                          _grupoSeleccionado == null
                              ? 'Seleccione un grupo para visualizar el reporte'
                              : 'No hay datos registrados en el grupo seleccionado',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _datosReporte.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _datosReporte[index];
                          final int totalPuntos = item['totalPuntos'] as int? ?? 0;

                          String subtexto = '';
                          if (_sesionSeleccionada != null) {
                            subtexto = 'Asistencia: ${item['estadoAsistencia'] ?? 'Falta'}';
                          } else {
                            final p = item['totalPresentes'] ?? 0;
                            final t = item['totalTardanzas'] ?? 0;
                            final f = item['totalFaltas'] ?? 0;
                            final j = item['totalJustificados'] ?? 0;
                            subtexto = 'P:$p  T:$t  F:$f  J:$j';
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF003882).withValues(alpha: 0.1),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF003882),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${item['apellidos']}, ${item['nombres']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cód: ${item['codigoInstitucional']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                Text(
                                  subtexto,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: totalPuntos > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: totalPuntos > 0 ? const Color(0xFF007A33) : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                '$totalPuntos pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: totalPuntos > 0 ? const Color(0xFF007A33) : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
