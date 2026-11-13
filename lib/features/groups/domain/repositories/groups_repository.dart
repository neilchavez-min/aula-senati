import '../entities/estudiante.dart';
import '../entities/grupo.dart';
import '../entities/instructor.dart';

abstract interface class GroupsRepository {
  Future<List<Instructor>> getInstructores();
  Future<List<Grupo>> getGrupos();
  Future<String> insertGrupo(Grupo grupo);
  Future<int> deleteGrupo(String grupoId);
  Future<List<Estudiante>> getEstudiantesByGrupo(String grupoId);
  Future<String> exportarAlumnosACsv(String grupoId);
  Future<Map<String, int>> importarAlumnosDesdeCsv({
    required String grupoId,
    required String csvContenido,
  });
}