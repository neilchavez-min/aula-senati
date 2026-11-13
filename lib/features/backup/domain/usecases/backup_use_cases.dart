import '../repositories/backup_repository.dart';

class BackupUseCases {
  const BackupUseCases(this._repository);

  final BackupRepository _repository;

  Future<String> getDatabasePathString() => _repository.getDatabasePathString();
  Future<int> getDatabaseFileSize() => _repository.getDatabaseFileSize();
  Future<Map<String, int>> getDashboardMetrics() => _repository.getDashboardMetrics();
  Future<Map<String, dynamic>> exportarBackupCompleto() =>
      _repository.exportarBackupCompleto();
  Future<Map<String, int>> restaurarDesdeBackup(Map<String, dynamic> backupData) =>
      _repository.restaurarDesdeBackup(backupData);
  Future<void> reiniciarBaseDeDatos() => _repository.reiniciarBaseDeDatos();
}