import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/entities/actividad.dart';
import '../../domain/repositories/points_repository.dart';

class SqlitePointsRepository implements PointsRepository {
  SqlitePointsRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<List<Actividad>> getActividades() => _database.getActividades();

  @override
  Future<List<Map<String, dynamic>>> getEstudiantesConPuntosEnSesion(String sesionId) =>
      _database.getEstudiantesConPuntosEnSesion(sesionId);

  @override
  Future<String> registrarParticipacion({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
    String? uuidTransaccion,
  }) => _database.registrarParticipacion(
        sesionId: sesionId,
        estudianteId: estudianteId,
        actividadId: actividadId,
        puntos: puntos,
        uuidTransaccion: uuidTransaccion,
      );

  @override
  Future<Map<String, dynamic>?> deshacerUltimaParticipacion(String sesionId) =>
      _database.deshacerUltimaParticipacion(sesionId);

  @override
  Future<int> eliminarParticipacion(String participacionId) =>
      _database.eliminarParticipacion(participacionId);

  @override
  Future<List<Map<String, dynamic>>> getHistorialParticipacionesBySesion(String sesionId) =>
      _database.getHistorialParticipacionesBySesion(sesionId);

  @override
  Future<List<Map<String, dynamic>>> getTopRankingSesion(String sesionId, {int limit = 5}) =>
      _database.getTopRankingSesion(sesionId, limit: limit);
}