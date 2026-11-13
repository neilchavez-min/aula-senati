abstract interface class AttendanceRepository {
  Future<List<Map<String, dynamic>>> getAsistenciasDetalladasBySesion(String sesionId);
  Future<Map<String, int>> getResumenAsistenciaBySesion(String sesionId);
  Future<void> registrarOActualizarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String estado,
    String observacion,
  });
}