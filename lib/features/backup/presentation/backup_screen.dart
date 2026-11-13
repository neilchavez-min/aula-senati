import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/backup/domain/usecases/backup_use_cases.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupUseCases get _backup => context.read<BackupUseCases>();

  String _dbPath = '';
  int _dbSize = 0;
  Map<String, int> _metricas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarInfoDatabase();
  }

  Future<void> _cargarInfoDatabase() async {
    setState(() => _isLoading = true);
    final path = await _backup.getDatabasePathString();
    final size = await _backup.getDatabaseFileSize();
    final metricas = await _backup.getDashboardMetrics();

    setState(() {
      _dbPath = path;
      _dbSize = size;
      _metricas = metricas;
      _isLoading = false;
    });
  }

  void _crearYExportarBackup() async {
    setState(() => _isLoading = true);
    try {
      final backupData = await _backup.exportarBackupCompleto();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      setState(() => _isLoading = false);

      if (!mounted) return;

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
                Icon(Icons.cloud_download, color: Color(0xFF003882), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Copia de Seguridad Generada',
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
                  'El respaldo incluye las 8 tablas relacionales con integridad referencial completa.',
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
                          jsonString,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003882),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar Backup al Portapapeles'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonString));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copia de seguridad copiada al portapapeles. Guárdala en un archivo o compártela.'),
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
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar respaldo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirModalRestaurar() {
    final jsonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Restaurar Copia de Seguridad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003882),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Pega el contenido JSON de tu copia de seguridad para restaurar todas las tablas:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonCtrl,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: '{\n  "sistema": "Aula Puntos - SENATI",\n  "tablas": { ... }\n}',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A33),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text(
                      'VALIDAR Y RESTAURAR EN SQLITE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final raw = jsonCtrl.text.trim();
                      if (raw.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Pegue el contenido del archivo JSON de respaldo.')),
                        );
                        return;
                      }

                      try {
                        final parsed = jsonDecode(raw) as Map<String, dynamic>;
                        final resultado = await _backup.restaurarDesdeBackup(parsed);

                        if (ctx.mounted) Navigator.pop(ctx);
                        await _cargarInfoDatabase();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Base de datos restaurada: ${resultado['grupos']} grupos, ${resultado['sesiones']} sesiones, ${resultado['estudiantes']} estudiantes.',
                              ),
                              backgroundColor: const Color(0xFF007A33),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error al restaurar: Formato JSON inválido o incompatible ($e)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarReinicioFabrica() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('¿Restablecer de Fábrica?'),
            ],
          ),
          content: const Text(
            'Esta acción eliminará todos los registros actuales y restaurará la base de datos al estado inicial con los datos institucionales SENATI de demostración.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                await _backup.reiniciarBaseDeDatos();
                await _cargarInfoDatabase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Base de datos restablecida con datos iniciales SENATI.'),
                      backgroundColor: Color(0xFF007A33),
                    ),
                  );
                }
              },
              child: const Text('Sí, Restablecer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double kbSize = _dbSize / 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copia de Seguridad y Restauración'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado del archivo SQLite
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.storage, color: Color(0xFF003882)),
                              SizedBox(width: 8),
                              Text(
                                'Estado de Base de Datos Local',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003882),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _itemInfoRow('Motor:', 'SQLite 3 (Offline-First)'),
                          _itemInfoRow('Archivo:', 'aula_puntos_senati.db'),
                          _itemInfoRow('Tamaño en disco:', '${kbSize.toStringAsFixed(2)} KB'),
                          const SizedBox(height: 6),
                          Text(
                            'Ubicación: $_dbPath',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace'),
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(child: _chipMetrica('Grupos', '${_metricas['grupos'] ?? 0}')),
                              Expanded(child: _chipMetrica('Sesiones', '${_metricas['sesiones'] ?? 0}')),
                              Expanded(child: _chipMetrica('Estudiantes', '${_metricas['estudiantes'] ?? 0}')),
                              Expanded(child: _chipMetrica('Puntos', '${_metricas['totalPuntos'] ?? 0}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta Crear Copia de Seguridad
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.cloud_upload_outlined, color: Color(0xFF007A33)),
                              SizedBox(width: 8),
                              Text(
                                'Exportar Copia de Seguridad',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Genera un archivo con todas las asistencias, grupos, estudiantes y notas acumuladas. Guárdalo para trasladar tu información a otro dispositivo.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003882),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('GENERAR Y EXPORTAR BACKUP (JSON)'),
                              onPressed: _crearYExportarBackup,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta Restaurar Respaldo
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.settings_backup_restore, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text(
                                'Restaurar Copia de Seguridad',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Restaura la información desde un archivo de respaldo generado previamente.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD97706),
                                side: const BorderSide(color: Color(0xFFD97706)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.restore),
                              label: const Text('IMPORTAR / RESTAURAR RESPALDO'),
                              onPressed: _abrirModalRestaurar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta Restablecer Fábrica
                  Card(
                    elevation: 1,
                    color: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.delete_forever, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Zona de Peligro: Restablecer Fábrica',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Borra todos los datos y reinicia con el grupo de demostración SENATI.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reiniciar Base de Datos'),
                              onPressed: _confirmarReinicioFabrica,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _itemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chipMetrica(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003882)),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}
