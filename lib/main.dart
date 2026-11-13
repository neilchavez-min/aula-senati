import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/database/database_helper.dart';
import 'features/backup/data/repositories/sqlite_backup_repository.dart';
import 'features/backup/domain/usecases/backup_use_cases.dart';
import 'features/attendance/data/repositories/sqlite_attendance_repository.dart';
import 'features/attendance/domain/usecases/attendance_use_cases.dart';
import 'features/dashboard/data/repositories/sqlite_dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_metrics.dart';
import 'features/groups/data/repositories/sqlite_groups_repository.dart';
import 'features/groups/domain/usecases/groups_use_cases.dart';
import 'features/points/data/repositories/sqlite_points_repository.dart';
import 'features/points/domain/usecases/points_use_cases.dart';
import 'features/reports/data/repositories/sqlite_reports_repository.dart';
import 'features/reports/domain/usecases/reports_use_cases.dart';
import 'features/sessions/data/repositories/sqlite_sessions_repository.dart';
import 'features/sessions/domain/usecases/sessions_use_cases.dart';
import 'features/dashboard/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización multiplataforma para SQLite: Web, Escritorio (Windows/Linux/macOS) y Móvil
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar y precargar base de datos local de forma segura
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('Nota de inicio de base de datos: $e');
  }

  final database = DatabaseHelper.instance;
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => BackupUseCases(SqliteBackupRepository(database))),
        Provider(create: (_) => GroupsUseCases(SqliteGroupsRepository(database))),
        Provider(create: (_) => SessionsUseCases(SqliteSessionsRepository(database))),
        Provider(create: (_) => AttendanceUseCases(SqliteAttendanceRepository(database))),
        Provider(create: (_) => PointsUseCases(SqlitePointsRepository(database))),
        Provider(create: (_) => ReportsUseCases(SqliteReportsRepository(database))),
        Provider(create: (_) => GetDashboardMetrics(SqliteDashboardRepository(database))),
      ],
      child: const AulaPuntosSenatiApp(),
    ),
  );
}

class AulaPuntosSenatiApp extends StatelessWidget {
  const AulaPuntosSenatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta de colores institucional SENATI
    const Color senatiAzul = Color(0xFF003882);
    const Color senatiCeleste = Color(0xFF0B5CAD);

    return MaterialApp(
      title: 'Aula Puntos - SENATI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: senatiAzul,
          primary: senatiAzul,
          secondary: senatiCeleste,
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: senatiAzul,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
