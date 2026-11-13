import '../repositories/reports_repository.dart';

class ReportsUseCases {
  const ReportsUseCases(this._repository);

  final ReportsRepository _repository;

  Future<List<Map<String, dynamic>>> getConsolidadoReporte({
    required String grupoId,
    String? sesionId,
  }) => _repository.getConsolidadoReporte(
        grupoId: grupoId,
        sesionId: sesionId,
      );
}