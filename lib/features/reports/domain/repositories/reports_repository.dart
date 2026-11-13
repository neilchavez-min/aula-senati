abstract interface class ReportsRepository {
  Future<List<Map<String, dynamic>>> getConsolidadoReporte({
    required String grupoId,
    String? sesionId,
  });
}