import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/features/attendance/presentation/asistencia_screen.dart';
import 'package:aula_puntos_senati/features/backup/presentation/backup_screen.dart';
import 'package:aula_puntos_senati/features/dashboard/domain/usecases/get_dashboard_metrics.dart';
import 'package:aula_puntos_senati/features/groups/presentation/grupos_screen.dart';
import 'package:aula_puntos_senati/features/points/presentation/puntuacion_screen.dart';
import 'package:aula_puntos_senati/features/reports/presentation/reportes_screen.dart';
import 'package:aula_puntos_senati/features/sessions/presentation/sesiones_screen.dart';
import 'package:aula_puntos_senati/widgets/connectivity_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  GetDashboardMetrics get _dashboardMetrics => context.read<GetDashboardMetrics>();

  Map<String, int> _metricas = {
    'grupos': 0,
    'estudiantes': 0,
    'sesiones': 0,
    'participaciones': 0,
    'totalPuntos': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() => _isLoading = true);
    final m = await _dashboardMetrics();
    setState(() {
      _metricas = m;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003882),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AULA PUNTOS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1),
            ),
            Text(
              'SENATI - Escuela de Tecnologías de la Información',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'Copia de Seguridad y Restauración (SQLite)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ).then((_) => _cargarMetricas());
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: ConnectivityBadge()),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          if (idx == 0) {
            setState(() => _currentIndex = 0);
            _cargarMetricas();
          } else if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GruposScreen()))
                .then((_) => _cargarMetricas());
          } else if (idx == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SesionesScreen()))
                .then((_) => _cargarMetricas());
          } else if (idx == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen()))
                .then((_) => _cargarMetricas());
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF003882)),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: Color(0xFF003882)),
            label: 'Mis Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note, color: Color(0xFF003882)),
            label: 'Sesiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF003882)),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 640 ? 4 : 2;
    final double childAspectRatio = screenWidth < 360 ? 1.0 : (screenWidth > 640 ? 1.3 : 1.15);

    return RefreshIndicator(
      onRefresh: _cargarMetricas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de bienvenida con resumen de control académico
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF003882),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel de Control del Instructor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestión offline centralizada de asistencia y gamificación de puntos.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta de métricas rápidas con soporte responsivo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _metricaItem(
                                  'Grupos',
                                  '${_metricas['grupos']}',
                                  Icons.folder_shared,
                                  const Color(0xFF003882),
                                ),
                              ),
                              Expanded(
                                child: _metricaItem(
                                  'Sesiones',
                                  '${_metricas['sesiones']}',
                                  Icons.calendar_today,
                                  const Color(0xFF0B5CAD),
                                ),
                              ),
                              Expanded(
                                child: _metricaItem(
                                  'Alumnos',
                                  '${_metricas['estudiantes']}',
                                  Icons.person,
                                  const Color(0xFF007A33),
                                ),
                              ),
                              Expanded(
                                child: _metricaItem(
                                  'Puntos',
                                  '${_metricas['totalPuntos']}',
                                  Icons.stars,
                                  const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Accesos rápidos en cuadrícula adaptativa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accesos Rápidos del Instructor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _cardAccesoRapido(
                        titulo: 'Gestionar Grupos',
                        subtitulo: 'NRC, Asignatura y Secciones',
                        icono: Icons.groups,
                        color: const Color(0xFF003882),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GruposScreen()),
                          ).then((_) => _cargarMetricas());
                        },
                      ),
                      _cardAccesoRapido(
                        titulo: 'Control Asistencia',
                        subtitulo: 'Registro interactivo P/T/F/J',
                        icono: Icons.how_to_reg,
                        color: const Color(0xFF007A33),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
                          ).then((_) => _cargarMetricas());
                        },
                      ),
                      _cardAccesoRapido(
                        titulo: 'Puntuación Rápida',
                        subtitulo: 'Gamificación +1, +2, -1 pts',
                        icono: Icons.star_rate_rounded,
                        color: const Color(0xFFD97706),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PuntuacionScreen()),
                          ).then((_) => _cargarMetricas());
                        },
                      ),
                      _cardAccesoRapido(
                        titulo: 'Reportes y PDF',
                        subtitulo: 'Membrete oficial y Excel',
                        icono: Icons.picture_as_pdf,
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportesScreen()),
                          ).then((_) => _cargarMetricas());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Banner interactivo SENATI Offline-First con acceso a Backup
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BackupScreen()),
                      ).then((_) => _cargarMetricas());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.offline_bolt, color: Color(0xFF003882), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Arquitectura Offline-First & Respaldo SQLite',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF003882),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Toca aquí para exportar o restaurar una copia de seguridad completa de tus asistencias y notas.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF003882)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaItem(String titulo, String valor, IconData icono, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
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
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _cardAccesoRapido({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 16,
              child: Icon(icono, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
