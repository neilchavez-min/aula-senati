import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/groups/domain/entities/grupo.dart';
import 'package:aula_puntos_senati/features/groups/domain/usecases/groups_use_cases.dart';
import 'package:aula_puntos_senati/features/points/domain/entities/actividad.dart';
import 'package:aula_puntos_senati/features/points/domain/usecases/points_use_cases.dart';
import 'package:aula_puntos_senati/features/sessions/domain/entities/sesion.dart';
import 'package:aula_puntos_senati/features/sessions/domain/usecases/sessions_use_cases.dart';

class PuntuacionScreen extends StatefulWidget {
  final Grupo? grupo;
  final Sesion? sesion;

  const PuntuacionScreen({super.key, this.grupo, this.sesion});

  @override
  State<PuntuacionScreen> createState() => _PuntuacionScreenState();
}

class _PuntuacionScreenState extends State<PuntuacionScreen> {
  GroupsUseCases get _groups => context.read<GroupsUseCases>();
  SessionsUseCases get _sessions => context.read<SessionsUseCases>();
  PointsUseCases get _points => context.read<PointsUseCases>();
  final _uuid = const Uuid();

  List<Grupo> _grupos = [];
  Grupo? _grupoActual;
  List<Sesion> _sesiones = [];
  Sesion? _sesionActual;

  List<Actividad> _actividades = [];
  Actividad? _actividadSeleccionada;

  List<Map<String, dynamic>> _estudiantesPuntajes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    setState(() => _isLoading = true);
    final grupos = await _groups.getGrupos();
    final actividades = await _points.getActividades();

    _grupos = grupos;
    _actividades = actividades;
    if (actividades.isNotEmpty) {
      _actividadSeleccionada = actividades.first;
    }

    if (widget.grupo != null) {
      _grupoActual = grupos.firstWhere(
        (g) => g.grupoId == widget.grupo!.grupoId,
        orElse: () => grupos.isNotEmpty ? grupos.first : widget.grupo!,
      );
    } else if (grupos.isNotEmpty) {
      _grupoActual = grupos.first;
    }

    if (_grupoActual != null && _grupoActual!.grupoId != null) {
      await _cargarSesionesYPuntos(_grupoActual!.grupoId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSesionesYPuntos(String grupoId) async {
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
      await _refrescarPuntajes(_sesionActual!.sesionId!);
    } else {
      setState(() {
        _estudiantesPuntajes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescarPuntajes(String sesionId) async {
    setState(() => _isLoading = true);
    final list = await _points.getEstudiantesConPuntosEnSesion(sesionId);
    setState(() {
      _estudiantesPuntajes = list;
      _isLoading = false;
    });
  }

  /// Asignación rápida de puntos con idempotencia garantizada mediante UUID
  Future<void> _asignarPuntos(String estudianteId, int delta) async {
    if (_sesionActual == null || _sesionActual!.sesionId == null) return;
    if (_actividadSeleccionada == null || _actividadSeleccionada!.actividadId == null) return;

    // Regla de negocio: Generación de uuidTransaccion único en cliente
    final transaccionId = _uuid.v4();

    try {
      await _points.registrarParticipacion(
        sesionId: _sesionActual!.sesionId!,
        estudianteId: estudianteId,
        actividadId: _actividadSeleccionada!.actividadId!,
        puntos: delta,
        uuidTransaccion: transaccionId,
      );

      // Persistencia reactiva: refrescamos inmediatamente desde SQLite
      await _refrescarPuntajes(_sesionActual!.sesionId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar puntos en SQLite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Deshacer la última asignación de puntos en la sesión activa
  Future<void> _deshacerUltimoPunto() async {
    if (_sesionActual == null || _sesionActual!.sesionId == null) return;

    final registroRevertido = await _points.deshacerUltimaParticipacion(_sesionActual!.sesionId!);
    if (registroRevertido != null) {
      await _refrescarPuntajes(_sesionActual!.sesionId!);
      if (mounted) {
        final pts = registroRevertido['puntos'];
        final ptsStr = (pts is int && pts > 0) ? '+$pts' : '$pts';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deshecho: Se anuló $ptsStr pts a ${registroRevertido['apellidos']}, ${registroRevertido['nombres']}',
            ),
            backgroundColor: const Color(0xFFC05621),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay participaciones para deshacer en esta sesión.'),
          ),
        );
      }
    }
  }

  /// Modal para ver la bitácora cronológica de participaciones
  void _mostrarModalHistorial() async {
    if (_sesionActual == null || _sesionActual!.sesionId == null) return;

    final String sesionId = _sesionActual!.sesionId!;
    List<Map<String, dynamic>> historial = await _points.getHistorialParticipacionesBySesion(sesionId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history, color: Color(0xFF003882)),
                          SizedBox(width: 8),
                          Text(
                            'Historial de Participaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003882),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Sesión ${_sesionActual!.numeroSesion}: ${_sesionActual!.tema}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(),
                  historial.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Aún no hay puntos asignados en esta sesión.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: historial.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = historial[i];
                              final String partId = item['participacionId'] as String;
                              final int pts = item['puntos'] as int? ?? 0;
                              final String ptsStr = pts > 0 ? '+$pts' : '$pts';
                              final String hora = (item['fecha'] as String? ?? '').length >= 16
                                  ? (item['fecha'] as String).substring(11, 16)
                                  : '';

                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: pts > 0
                                        ? const Color(0xFFE8F5E9)
                                        : pts < 0
                                            ? const Color(0xFFFFEBEE)
                                            : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: pts > 0
                                          ? const Color(0xFF007A33)
                                          : pts < 0
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ptsStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: pts > 0
                                            ? const Color(0xFF007A33)
                                            : pts < 0
                                                ? Colors.red
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${item['apellidos']}, ${item['nombres']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${item['actividadNombre']} • $hora hrs',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'Eliminar este registro',
                                  onPressed: () async {
                                    await _points.eliminarParticipacion(partId);
                                    final actualizado = await _points.getHistorialParticipacionesBySesion(sesionId);
                                    setModalState(() {
                                      historial = actualizado;
                                    });
                                    await _refrescarPuntajes(sesionId);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Modal con el Podio / Ranking de la clase
  void _mostrarModalRanking() async {
    if (_sesionActual == null || _sesionActual!.sesionId == null) return;

    final String sesionId = _sesionActual!.sesionId!;
    final topAlumnos = await _points.getTopRankingSesion(sesionId, limit: 5);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Podio de la Sesión - SENATI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003882),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Estudiantes con mayor participación académica en la sesión:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(),
              if (topAlumnos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No hay participaciones registradas aún.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...topAlumnos.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  final totalPuntos = item['totalPuntos'] ?? 0;
                  final intervenciones = item['totalIntervenciones'] ?? 0;

                  Color medallaColor;
                  IconData medallaIcon;
                  if (i == 1) {
                    medallaColor = const Color(0xFFFFD700); // Oro
                    medallaIcon = Icons.military_tech;
                  } else if (i == 2) {
                    medallaColor = const Color(0xFFC0C0C0); // Plata
                    medallaIcon = Icons.military_tech;
                  } else if (i == 3) {
                    medallaColor = const Color(0xFFCD7F32); // Bronce
                    medallaIcon = Icons.military_tech;
                  } else {
                    medallaColor = const Color(0xFF003882);
                    medallaIcon = Icons.star_border;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: i <= 3 ? 2 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: i <= 3 ? BorderSide(color: medallaColor, width: 1.2) : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: medallaColor.withValues(alpha: 0.15),
                        child: Icon(medallaIcon, color: medallaColor),
                      ),
                      title: Text(
                        '${item['apellidos']}, ${item['nombres']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        'Cód: ${item['codigoInstitucional']} • $intervenciones intervención(es)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF007A33)),
                        ),
                        child: Text(
                          '$totalPuntos pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A33),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntuación Rápida'),
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer último punto',
            onPressed: _deshacerUltimoPunto,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Ver Podio / Ranking',
            onPressed: _mostrarModalRanking,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Historial de puntos',
            onPressed: _mostrarModalHistorial,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selectores de Grupo y Sesión responsivos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<Grupo>(
                  isExpanded: true,
                  value: _grupoActual,
                  decoration: const InputDecoration(
                    labelText: 'Grupo SENATI',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      _cargarSesionesYPuntos(g.grupoId!);
                    }
                  },
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<Sesion>(
                  isExpanded: true,
                  value: _sesionActual,
                  decoration: const InputDecoration(
                    labelText: 'Sesión Activa',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  items: _sesiones.map((s) {
                    return DropdownMenuItem<Sesion>(
                      value: s,
                      child: Text(
                        'Sesión ${s.numeroSesion}: ${s.tema}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (s) {
                    if (s != null && s.sesionId != null) {
                      setState(() => _sesionActual = s);
                      _refrescarPuntajes(s.sesionId!);
                    }
                  },
                ),
                const SizedBox(height: 6),
                // Selector de actividad con isExpanded
                DropdownButtonFormField<Actividad>(
                  isExpanded: true,
                  value: _actividadSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Criterio / Actividad de Participación',
                    prefixIcon: Icon(Icons.stars, color: Color(0xFF003882)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  items: _actividades.map((a) {
                    return DropdownMenuItem<Actividad>(
                      value: a,
                      child: Text(
                        '${a.nombre} (+${a.valorDefecto} pts)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (a) {
                    if (a != null) {
                      setState(() => _actividadSeleccionada = a);
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Barra rápida de acciones secundarias con scroll horizontal responsivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFFF1F5F9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFC05621),
                      side: const BorderSide(color: Color(0xFFDD6B20)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.undo, size: 15),
                    label: const Text('Deshacer', style: TextStyle(fontSize: 12)),
                    onPressed: _deshacerUltimoPunto,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.emoji_events, size: 16),
                    label: const Text('Top Ranking', style: TextStyle(fontSize: 12)),
                    onPressed: _mostrarModalRanking,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF003882),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Bitácora', style: TextStyle(fontSize: 12)),
                    onPressed: _mostrarModalHistorial,
                  ),
                ],
              ),
            ),
          ),

          // Lista de Estudiantes para Puntuación Rápida
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _estudiantesPuntajes.isEmpty
                    ? Center(
                        child: Text(
                          _sesionActual == null
                              ? 'Seleccione o cree una sesión para asignar puntos'
                              : 'No hay alumnos registrados en este grupo',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        itemCount: _estudiantesPuntajes.length,
                        itemBuilder: (context, index) {
                          final item = _estudiantesPuntajes[index];
                          final String estId = item['estudianteId'] as String;
                          final int totalPuntos = item['totalPuntos'] as int? ?? 0;
                          final String estadoAsist = item['estadoAsistencia'] as String? ?? 'Presente';

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Badge de puntos totales
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: totalPuntos > 0
                                          ? const Color(0xFFE8F5E9)
                                          : totalPuntos < 0
                                              ? const Color(0xFFFFEBEE)
                                              : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: totalPuntos > 0
                                            ? const Color(0xFF007A33)
                                            : totalPuntos < 0
                                                ? Colors.red
                                                : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$totalPuntos',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: totalPuntos > 0
                                              ? const Color(0xFF007A33)
                                              : totalPuntos < 0
                                                  ? Colors.red
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nombres y estado de asistencia
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['apellidos']}, ${item['nombres']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Total: $totalPuntos pts • $estadoAsist',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                            color: Color(0xFF003882),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botones de acción rápida compactos y responsivos
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _botonAccionRapida(
                                        texto: '+1',
                                        color: const Color(0xFF007A33),
                                        onTap: () => _asignarPuntos(estId, 1),
                                      ),
                                      const SizedBox(width: 3),
                                      _botonAccionRapida(
                                        texto: '+2',
                                        color: const Color(0xFF003882),
                                        onTap: () => _asignarPuntos(estId, 2),
                                      ),
                                      const SizedBox(width: 3),
                                      _botonAccionRapida(
                                        texto: '-1',
                                        color: const Color(0xFFDC2626),
                                        onTap: () => _asignarPuntos(estId, -1),
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

  Widget _botonAccionRapida({
    required String texto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        minimumSize: const Size(32, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 1,
      ),
      onPressed: onTap,
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
