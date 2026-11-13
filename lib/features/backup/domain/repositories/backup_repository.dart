abstract interface class BackupRepository {
  Future<String> getDatabasePathString();
  Future<int> getDatabaseFileSize();
  Future<Map<String, int>> getDashboardMetrics();
  Future<Map<String, dynamic>> exportarBackupCompleto();
  Future<Map<String, int>> restaurarDesdeBackup(Map<String, dynamic> backupData);
  Future<void> reiniciarBaseDeDatos();
}