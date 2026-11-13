import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/attendance/domain/usecases/attendance_use_cases.dart';
import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/usecases/groups_use_cases.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';
import 'package:aula_puntos_senati/features/sessions/domain/usecases/sessions_use_cases.dart';

class AsistenciaScreen extends StatefulWidget {
  final Grupo? grupo;
  final Sesion? sesion;

  const AsistenciaScreen({super.key, this.grupo, this.sesion});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  GroupsUseCases get _groups => context.read<GroupsUseCases>();
  SessionsUseCases get _sessions => context.read<SessionsUseCases>();
  AttendanceUseCases get _attendance => context.read<AttendanceUseCases>();

  List<Grupo> _grupos = [];
  Grupo? _grupoActual;
  List<Sesion> _sesiones = [];
  Sesion? _sesionActual;

  List<Map<String, dynamic>> _estudiantes = [];
  Map<String, int> _resumen = {
    'Presente': 0,
    'Tardanza': 0,
    'Falta': 0,
    'Justificado': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    final grupos = await _groups.getGrupos();
    _grupos = grupos;

    if (widget.grupo != null) {
      _grupoActual = grupos.firstWhere(
        (g) => g.grupoId == widget.grupo!.grupoId,
        orElse: () => grupos.isNotEmpty ? grupos.first : widget.grupo!,
      );
    } else if (grupos.isNotEmpty) {
      _grupoActual = grupos.first;
    }

    if (_grupoActual != null && _grupoActual!.grupoId != null) {
      await _cargarSesionesYAsistencias(_grupoActual!.grupoId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSesionesYAsistencias(String grupoId) async {
    final sesiones = await _sessions.getSesionesByGrupo(grupoId);
    _sesiones = sesiones;

    if (widget.sesion != null) {
      _sesionActual = sesiones.firstWhere(
        (s) => s.sesionId == widget.sesion!.sesionId,
        orElse: () => sesiones.isNotEmpty ? sesiones.first : widget.sesion!,
      );
    } else if (sesiones.isNotEmpty) {
      _sesionActual = sesiones.first;
    } else {
      _sesionActual = null;
    }

    if (_sesionActual != null && _sesionActual!.sesionId != null) {
      await _refrescarAsistencias(_sesionActual!.sesionId!);
    } else {
      setState(() {
        _estudiantes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescarAsistencias(String sesionId) async {
    setState(() => _isLoading = true);
    final list = await _attendance.getAsistenciasDetalladasBySesion(sesionId);
    final res = await _attendance.getResumenAsistenciaBySesion(sesionId);

    setState(() {
      _estudiantes = list;
      _resumen = res;
      _isLoading = false;
    });
  }

  Future<void> _cambiarEstado(String estudianteId, String nuevoEstado) async {
    if (_sesionActual == null || _sesionActual!.sesionId == null) return;

    try {
      await _attendance.registrarOActualizarAsistencia(
        sesionId: _sesionActual!.sesionId!,
        estudianteId: estudianteId,
        estado: nuevoEstado,
      );

      // Persistencia reactiva: refrescamos los datos consumiendo SQLite inmediatamente
      await _refrescarAsistencias(_sesionActual!.sesionId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado en SQLite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'Presente':
        return const Color(0xFF007A33); // Verde SENATI
      case 'Tardanza':
        return const Color(0xFFD97706); // Ámbar
      case 'Falta':
        return const Color(0xFFDC2626); // Rojo
      case 'Justificado':
        return const Color(0xFF2563EB); // Azul
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia SENATI'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selectores de Grupo y Sesión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<Grupo>(
                  isExpanded: true,
                  value: _grupoActual,
                  decoration: const InputDecoration(
                    labelText: 'Grupo / NRC',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      setState(() => _grupoActual = g);
                      _cargarSesionesYAsistencias(g.grupoId!);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Sesion>(
                  isExpanded: true,
                  value: _sesionActual,
                  decoration: const InputDecoration(
                    labelText: 'Sesión de Clase',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: _sesiones.map((s) {
                    return DropdownMenuItem<Sesion>(
                      value: s,
                      child: Text(
                        'Sesión ${s.numeroSesion}: ${s.tema} (${s.fecha})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (s) {
                    if (s != null && s.sesionId != null) {
                      setState(() => _sesionActual = s);
                      _refrescarAsistencias(s.sesionId!);
                    }
                  },
                ),
              ],
            ),
          ),

          // Resumen en cabecera con contador responsivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _chipContador('Presentes', _resumen['Presente'] ?? 0, const Color(0xFF007A33))),
                Expanded(child: _chipContador('Tardanzas', _resumen['Tardanza'] ?? 0, const Color(0xFFD97706))),
                Expanded(child: _chipContador('Faltas', _resumen['Falta'] ?? 0, const Color(0xFFDC2626))),
                Expanded(child: _chipContador('Justificados', _resumen['Justificado'] ?? 0, const Color(0xFF2563EB))),
              ],
            ),
          ),

          // Lista de Estudiantes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _estudiantes.isEmpty
                    ? Center(
                        child: Text(
                          _sesionActual == null
                              ? 'Seleccione o cree una sesión para registrar asistencia'
                              : 'No hay estudiantes vinculados a este grupo',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _estudiantes.length,
                        itemBuilder: (context, index) {
                          final est = _estudiantes[index];
                          final String estudianteId = est['estudianteId'] as String;
                          final String estadoActual = est['estado'] as String? ?? 'Falta';

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _getColorForEstado(estadoActual).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Indicador de orden y código
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF003882).withOpacity(0.1),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF003882),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Datos alumno
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${est['apellidos']}, ${est['nombres']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          'Cód: ${est['codigoInstitucional']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botones de estado [P] [T] [F] [J]
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _botonEstado(
                                        label: 'P',
                                        tooltip: 'Presente',
                                        estado: 'Presente',
                                        estadoActual: estadoActual,
                                        color: const Color(0xFF007A33),
                                        onTap: () => _cambiarEstado(estudianteId, 'Presente'),
                                      ),
                                      _botonEstado(
                                        label: 'T',
                                        tooltip: 'Tardanza',
                                        estado: 'Tardanza',
                                        estadoActual: estadoActual,
                                        color: const Color(0xFFD97706),
                                        onTap: () => _cambiarEstado(estudianteId, 'Tardanza'),
                                      ),
                                      _botonEstado(
                                        label: 'F',
                                        tooltip: 'Falta',
                                        estado: 'Falta',
                                        estadoActual: estadoActual,
                                        color: const Color(0xFFDC2626),
                                        onTap: () => _cambiarEstado(estudianteId, 'Falta'),
                                      ),
                                      _botonEstado(
                                        label: 'J',
                                        tooltip: 'Justificado',
                                        estado: 'Justificado',
                                        estadoActual: estadoActual,
                                        color: const Color(0xFF2563EB),
                                        onTap: () => _cambiarEstado(estudianteId, 'Justificado'),
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

  Widget _chipContador(String titulo, int cantidad, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonEstado({
    required String label,
    required String tooltip,
    required String estado,
    required String estadoActual,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool seleccionado = (estado == estadoActual);

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: seleccionado ? color : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color,
                width: seleccionado ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: seleccionado ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
