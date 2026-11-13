import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/repositories/backup_repository.dart';

class SqliteBackupRepository implements BackupRepository {
  const SqliteBackupRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<String> getDatabasePathString() => _database.getDatabasePathString();

  @override
  Future<int> getDatabaseFileSize() => _database.getDatabaseFileSize();

  @override
  Future<Map<String, int>> getDashboardMetrics() => _database.getDashboardMetrics();

  @override
  Future<Map<String, dynamic>> exportarBackupCompleto() =>
      _database.exportarBackupCompleto();

  @override
  Future<Map<String, int>> restaurarDesdeBackup(Map<String, dynamic> backupData) =>
      _database.restaurarDesdeBackup(backupData);

  @override
  Future<void> reiniciarBaseDeDatos() => _database.reiniciarBaseDeDatos();
}