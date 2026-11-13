import '../repositories/attendance_repository.dart';

class AttendanceUseCases {
  const AttendanceUseCases(this._repository);

  final AttendanceRepository _repository;

  Future<List<Map<String, dynamic>>> getAsistenciasDetalladasBySesion(String sesionId) =>
      _repository.getAsistenciasDetalladasBySesion(sesionId);
  Future<Map<String, int>> getResumenAsistenciaBySesion(String sesionId) =>
      _repository.getResumenAsistenciaBySesion(sesionId);
  Future<void> registrarOActualizarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String estado,
    String observacion = '',
  }) => _repository.registrarOActualizarAsistencia(
        sesionId: sesionId,
        estudianteId: estudianteId,
        estado: estado,
        observacion: observacion,
      );
}