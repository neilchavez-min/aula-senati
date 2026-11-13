import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/entities/sesion.dart';
import '../../domain/repositories/sessions_repository.dart';

class SqliteSessionsRepository implements SessionsRepository {
  SqliteSessionsRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<List<Sesion>> getSesionesByGrupo(String grupoId) =>
      _database.getSesionesByGrupo(grupoId);

  @override
  Future<String> insertSesion(Sesion sesion) => _database.insertSesion(sesion);

  @override
  Future<int> deleteSesion(String sesionId) => _database.deleteSesion(sesionId);
}