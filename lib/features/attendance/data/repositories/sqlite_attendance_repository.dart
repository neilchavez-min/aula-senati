import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/repositories/attendance_repository.dart';

class SqliteAttendanceRepository implements AttendanceRepository {
  SqliteAttendanceRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<List<Map<String, dynamic>>> getAsistenciasDetalladasBySesion(String sesionId) =>
      _database.getAsistenciasDetalladasBySesion(sesionId);

  @override
  Future<Map<String, int>> getResumenAsistenciaBySesion(String sesionId) =>
      _database.getResumenAsistenciaBySesion(sesionId);

  @override
  Future<void> registrarOActualizarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String estado,
    String observacion = '',
  }) => _database.registrarOActualizarAsistencia(
        sesionId: sesionId,
        estudianteId: estudianteId,
        estado: estado,
        observacion: observacion,
      );
}