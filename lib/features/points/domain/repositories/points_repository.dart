import '../entities/actividad.dart';

abstract interface class PointsRepository {
  Future<List<Actividad>> getActividades();
  Future<List<Map<String, dynamic>>> getEstudiantesConPuntosEnSesion(String sesionId);
  Future<String> registrarParticipacion({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
    String? uuidTransaccion,
  });
  Future<Map<String, dynamic>?> deshacerUltimaParticipacion(String sesionId);
  Future<int> eliminarParticipacion(String participacionId);
  Future<List<Map<String, dynamic>>> getHistorialParticipacionesBySesion(String sesionId);
  Future<List<Map<String, dynamic>>> getTopRankingSesion(String sesionId, {int limit});
}