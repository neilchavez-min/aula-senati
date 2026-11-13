import '../repositories/dashboard_repository.dart';

class GetDashboardMetrics {
  const GetDashboardMetrics(this._repository);

  final DashboardRepository _repository;

  Future<Map<String, int>> call() => _repository.getDashboardMetrics();
}