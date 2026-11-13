import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/groups/domain/entities/estudiante.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/usecases/groups_use_cases.dart';
import 'package:aula_puntos_senati/features/sessions/presentation/sesiones_screen.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  GroupsUseCases get _groups => context.read<GroupsUseCases>();
  List<Grupo> _grupos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _groups.getGrupos();
      if (mounted) {
        setState(() {
          _grupos = lista;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando grupos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar grupos: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _abrirModalNuevoGrupo() async {
    final instructores = await _groups.getInstructores();
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final codigoCtrl = TextEditingController(text: '202601');
    final programaCtrl = TextEditingController(text: '2026-20');
    final asignaturaCtrl = TextEditingController(text: 'FORMACIÓN MONITORES EMPRESA');
    final periodoCtrl = TextEditingController(text: '2026-20');
    final seccionCtrl = TextEditingController(text: '2026-20-202601');
    final nombreCtrl = TextEditingController(text: 'Monitores de Empresa - Aula TI');

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nuevo Grupo SENATI',
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
                  const Divider(),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: codigoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código / NRC (ej. 202601)',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Descriptivo del Grupo',
                      prefixIcon: Icon(Icons.group_work),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: asignaturaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Asignatura (ej. FORMACIÓN MONITORES EMPRESA)',
                      prefixIcon: Icon(Icons.menu_book),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: programaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Programa (ej. 2026-20)',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: periodoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Periodo (ej. 2026-20)',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: seccionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sección (ej. 2026-20-202601)',
                      prefixIcon: Icon(Icons.meeting_room),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003882),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'REGISTRAR GRUPO EN SQLITE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final nuevoGrupo = Grupo(
                            codigo: codigoCtrl.text.trim(),
                            nombre: nombreCtrl.text.trim(),
                            programa: programaCtrl.text.trim(),
                            asignatura: asignaturaCtrl.text.trim(),
                            periodo: periodoCtrl.text.trim(),
                            seccion: seccionCtrl.text.trim(),
                            instructorId: instructores.isEmpty ? null : instructores.first.instructorId,
                          );

                          try {
                            await _groups.insertGrupo(nuevoGrupo);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              _cargarGrupos();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Grupo SENATI registrado exitosamente en base de datos local.'),
                                  backgroundColor: Color(0xFF007A33),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar grupo: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modal interactivo para Importación y Exportación CSV de alumnos
  void _abrirModalGestionAlumnosCsv(Grupo grupo) async {
    final String grupoId = grupo.grupoId!;
    List<Estudiante> estudiantes = await _groups.getEstudiantesByGrupo(grupoId);
    final csvInputCtrl = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gestión de Alumnos (CSV)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003882),
                                ),
                              ),
                              Text(
                                '${grupo.codigo} - ${grupo.asignatura}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Resumen de alumnos actuales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alumnos inscritos: ${estudiantes.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copiar CSV actual'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF003882)),
                          onPressed: estudiantes.isEmpty
                              ? null
                              : () async {
                                  final csvTexto = await _groups.exportarAlumnosACsv(grupoId);
                                  Clipboard.setData(ClipboardData(text: csvTexto));
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Padrón de alumnos copiado en formato CSV.'),
                                        backgroundColor: Color(0xFF007A33),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      'Pegar o escribir alumnos en formato CSV:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const Text(
                      'Formato por fila: CODIGO, APELLIDOS, NOMBRES (ej. SEN-102941, Castro Rios, Luis)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: csvInputCtrl,
                      maxLines: 5,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "SEN-102941, Ramos Vega, Carlos Daniel\nSEN-102942, Morales Peña, Andrea Lucía",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                            icon: const Icon(Icons.playlist_add, size: 16),
                            label: const Text(
                              'Cargar Ejemplo SENATI',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setModalState(() {
                                csvInputCtrl.text =
                                    "SEN-102941, Ramos Vega, Carlos Daniel\n"
                                    "SEN-102942, Morales Peña, Andrea Lucía\n"
                                    "SEN-102943, Villanueva Cruz, Jorge Luis\n"
                                    "SEN-102944, Benites Campos, Sandra Melissa";
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A33),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                            icon: const Icon(Icons.file_download, size: 16),
                            label: const Text(
                              'Importar a SQLite',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final rawCsv = csvInputCtrl.text.trim();
                              if (rawCsv.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Ingrese o pegue líneas en formato CSV.')),
                                );
                                return;
                              }

                              final res = await _groups.importarAlumnosDesdeCsv(
                                grupoId: grupoId,
                                csvContenido: rawCsv,
                              );

                              final listaActualizada = await _groups.getEstudiantesByGrupo(grupoId);
                              setModalState(() {
                                estudiantes = listaActualizada;
                                csvInputCtrl.clear();
                              });

                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Proceso completado: ${res['importados']} alumnos importados/vinculados a SQLite.',
                                    ),
                                    backgroundColor: const Color(0xFF007A33),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),
                    const Text(
                      'Padrón actual en base de datos local:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: estudiantes.isEmpty
                          ? const Center(
                              child: Text('No hay alumnos inscritos', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              itemCount: estudiantes.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final est = estudiantes[i];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF003882).withValues(alpha: 0.1),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF003882)),
                                    ),
                                  ),
                                  title: Text(
                                    '${est.apellidos}, ${est.nombres}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    est.codigoInstitucional,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Grupos SENATI'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGrupos,
            tooltip: 'Refrescar datos locales',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        onPressed: _abrirModalNuevoGrupo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Grupo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grupos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay grupos registrados en SQLite',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _abrirModalNuevoGrupo,
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar Primer Grupo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _grupos.length,
                  itemBuilder: (context, index) {
                    final grupo = _grupos[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NRC: ${grupo.codigo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003882),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Sec: ${grupo.seccion}',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              grupo.asignatura,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              grupo.nombre,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.school, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Prog: ${grupo.programa} | Periodo: ${grupo.periodo}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.file_upload, size: 16),
                                  label: const Text('Alumnos CSV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF003882),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onPressed: () => _abrirModalGestionAlumnosCsv(grupo),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.calendar_month, size: 16),
                                  label: const Text('Ver Sesiones'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003882),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SesionesScreen(grupoInicial: grupo),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
