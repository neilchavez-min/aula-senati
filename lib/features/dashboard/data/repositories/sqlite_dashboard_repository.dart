import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/repositories/dashboard_repository.dart';

class SqliteDashboardRepository implements DashboardRepository {
  const SqliteDashboardRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<Map<String, int>> getDashboardMetrics() => _database.getDashboardMetrics();
}