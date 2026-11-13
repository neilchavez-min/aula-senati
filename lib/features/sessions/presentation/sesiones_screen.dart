import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/attendance/presentation/asistencia_screen.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/usecases/groups_use_cases.dart';
import 'package:aula_puntos_senati/features/points/presentation/puntuacion_screen.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';
import 'package:aula_puntos_senati/features/sessions/domain/usecases/sessions_use_cases.dart';

class SesionesScreen extends StatefulWidget {
  final Grupo? grupoInicial;

  const SesionesScreen({super.key, this.grupoInicial});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  GroupsUseCases get _groups => context.read<GroupsUseCases>();
  SessionsUseCases get _sessions => context.read<SessionsUseCases>();

  List<Grupo> _grupos = [];
  Grupo? _grupoSeleccionado;
  List<Sesion> _sesiones = [];
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
      await _cargarSesiones(_grupoSeleccionado!.grupoId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSesiones(String grupoId) async {
    setState(() => _isLoading = true);
    final lista = await _sessions.getSesionesByGrupo(grupoId);
    setState(() {
      _sesiones = lista;
      _isLoading = false;
    });
  }

  void _abrirModalCrearSesion() {
    if (_grupoSeleccionado == null || _grupoSeleccionado!.grupoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un grupo primero.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroSesionCtrl = TextEditingController(text: '${_sesiones.length + 1}');
    final temaCtrl = TextEditingController(text: 'Estrategias de Monitoreo y Evaluación de Desempeño');
    final duracionCtrl = TextEditingController(text: '4');
    final obsCtrl = TextEditingController(text: 'Laboratorio de cómputo - Aula TIC SENATI');
    String tipoSeleccionado = 'Teoría';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            'Crear Sesión Académica',
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
                      Text(
                        'Grupo: ${_grupoSeleccionado!.asignatura} (${_grupoSeleccionado!.codigo})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: numeroSesionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Número de Sesión',
                                prefixIcon: Icon(Icons.format_list_numbered),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: duracionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duración (Horas)',
                                prefixIcon: Icon(Icons.timer),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Sesión',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Teoría', child: Text('Teoría (Aula)')),
                          DropdownMenuItem(value: 'Práctica', child: Text('Práctica (Taller / Laboratorio)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => tipoSeleccionado = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: temaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tema Desarrollado',
                          prefixIcon: Icon(Icons.topic),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: obsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones / Ambiente',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
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
                            'GUARDAR SESIÓN EN SQLITE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final nuevaSesion = Sesion(
                                grupoId: _grupoSeleccionado!.grupoId!,
                                numeroSesion: int.tryParse(numeroSesionCtrl.text) ?? 1,
                                fecha: DateTime.now().toIso8601String().split('T').first,
                                tema: temaCtrl.text.trim(),
                                tipoSesion: tipoSeleccionado,
                                duracionHoras: int.tryParse(duracionCtrl.text) ?? 2,
                                observaciones: obsCtrl.text.trim(),
                              );

                              try {
                                await _sessions.insertSesion(nuevaSesion);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  _cargarSesiones(_grupoSeleccionado!.grupoId!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sesión registrada y plantilla de asistencia inicializada.'),
                                      backgroundColor: Color(0xFF007A33),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al crear sesión: $e'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Sesiones'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        onPressed: _abrirModalCrearSesion,
        icon: const Icon(Icons.add_task),
        label: const Text('Nueva Sesión'),
      ),
      body: Column(
        children: [
          // Selector de Grupo Activo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.groups, color: Color(0xFF003882)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Grupo>(
                      isExpanded: true,
                      value: _grupoSeleccionado,
                      hint: const Text('Seleccione un grupo'),
                      items: _grupos.map((g) {
                        return DropdownMenuItem<Grupo>(
                          value: g,
                          child: Text(
                            '${g.codigo} - ${g.asignatura} (${g.seccion})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (g) {
                        if (g != null && g.grupoId != null) {
                          setState(() => _grupoSeleccionado = g);
                          _cargarSesiones(g.grupoId!);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Sesiones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sesiones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay sesiones registradas para este grupo',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _abrirModalCrearSesion,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Primera Sesión'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sesiones.length,
                        itemBuilder: (context, index) {
                          final sesion = _sesiones[index];
                          final esPractica = sesion.tipoSesion.toLowerCase().contains('práct');

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                          color: const Color(0xFF003882),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Sesión #${sesion.numeroSesion}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: esPractica ? const Color(0xFFFEF3C7) : const Color(0xFFE0E7FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${sesion.tipoSesion} (${sesion.duracionHoras}h)',
                                          style: TextStyle(
                                            color: esPractica ? const Color(0xFF92400E) : const Color(0xFF3730A3),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sesion.tema,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fecha: ${sesion.fecha}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  if (sesion.observaciones.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Obs: ${sesion.observaciones}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.how_to_reg, size: 16),
                                        label: const Text('Asistencia'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF003882),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AsistenciaScreen(
                                                grupo: _grupoSeleccionado!,
                                                sesion: sesion,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.star, size: 16),
                                        label: const Text('Puntos'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF003882),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PuntuacionScreen(
                                                grupo: _grupoSeleccionado!,
                                                sesion: sesion,
                                              ),
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
          ),
        ],
      ),
    );
  }
}
