import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/repositories/reports_repository.dart';

class SqliteReportsRepository implements ReportsRepository {
  SqliteReportsRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<List<Map<String, dynamic>>> getConsolidadoReporte({
    required String grupoId,
    String? sesionId,
  }) => _database.getConsolidadoReporte(
        grupoId: grupoId,
        sesionId: sesionId,
      );
}