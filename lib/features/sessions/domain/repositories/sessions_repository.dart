import '../entities/sesion.dart';

abstract interface class SessionsRepository {
  Future<List<Sesion>> getSesionesByGrupo(String grupoId);
  Future<String> insertSesion(Sesion sesion);
  Future<int> deleteSesion(String sesionId);
}