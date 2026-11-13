import '../entities/estudiante.dart';
import '../entities/grupo.dart';
import '../entities/instructor.dart';
import '../repositories/groups_repository.dart';

class GroupsUseCases {
  const GroupsUseCases(this._repository);

  final GroupsRepository _repository;

  Future<List<Instructor>> getInstructores() => _repository.getInstructores();

  Future<List<Grupo>> getGrupos() => _repository.getGrupos();
  Future<String> insertGrupo(Grupo grupo) => _repository.insertGrupo(grupo);
  Future<int> deleteGrupo(String grupoId) => _repository.deleteGrupo(grupoId);
  Future<List<Estudiante>> getEstudiantesByGrupo(String grupoId) =>
      _repository.getEstudiantesByGrupo(grupoId);
  Future<String> exportarAlumnosACsv(String grupoId) =>
      _repository.exportarAlumnosACsv(grupoId);
  Future<Map<String, int>> importarAlumnosDesdeCsv({
    required String grupoId,
    required String csvContenido,
  }) => _repository.importarAlumnosDesdeCsv(
        grupoId: grupoId,
        csvContenido: csvContenido,
      );
}