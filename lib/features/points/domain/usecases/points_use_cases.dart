import '../entities/actividad.dart';
import '../repositories/points_repository.dart';

class PointsUseCases {
  const PointsUseCases(this._repository);

  final PointsRepository _repository;

  Future<List<Actividad>> getActividades() => _repository.getActividades();
  Future<List<Map<String, dynamic>>> getEstudiantesConPuntosEnSesion(String sesionId) =>
      _repository.getEstudiantesConPuntosEnSesion(sesionId);
  Future<String> registrarParticipacion({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
    String? uuidTransaccion,
  }) => _repository.registrarParticipacion(
        sesionId: sesionId,
        estudianteId: estudianteId,
        actividadId: actividadId,
        puntos: puntos,
        uuidTransaccion: uuidTransaccion,
      );
  Future<Map<String, dynamic>?> deshacerUltimaParticipacion(String sesionId) =>
      _repository.deshacerUltimaParticipacion(sesionId);
  Future<int> eliminarParticipacion(String participacionId) =>
      _repository.eliminarParticipacion(participacionId);
  Future<List<Map<String, dynamic>>> getHistorialParticipacionesBySesion(String sesionId) =>
      _repository.getHistorialParticipacionesBySesion(sesionId);
  Future<List<Map<String, dynamic>>> getTopRankingSesion(String sesionId, {int limit = 5}) =>
      _repository.getTopRankingSesion(sesionId, limit: limit);
}