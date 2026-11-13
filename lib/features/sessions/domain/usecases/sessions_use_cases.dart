import '../entities/sesion.dart';
import '../repositories/sessions_repository.dart';

class SessionsUseCases {
  const SessionsUseCases(this._repository);

  final SessionsRepository _repository;

  Future<List<Sesion>> getSesionesByGrupo(String grupoId) =>
      _repository.getSesionesByGrupo(grupoId);
  Future<String> insertSesion(Sesion sesion) => _repository.insertSesion(sesion);
  Future<int> deleteSesion(String sesionId) => _repository.deleteSesion(sesionId);
}