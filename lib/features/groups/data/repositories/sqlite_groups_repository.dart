import 'package:aula_puntos_senati/core/database/database_helper.dart';
import '../../domain/entities/estudiante.dart';
import '../../domain/entities/grupo.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/repositories/groups_repository.dart';

class SqliteGroupsRepository implements GroupsRepository {
  SqliteGroupsRepository(this._database);

  final DatabaseHelper _database;

  @override
  Future<List<Instructor>> getInstructores() => _database.getInstructores();

  @override
  Future<List<Grupo>> getGrupos() => _database.getGrupos();

  @override
  Future<String> insertGrupo(Grupo grupo) => _database.insertGrupo(grupo);

  @override
  Future<int> deleteGrupo(String grupoId) => _database.deleteGrupo(grupoId);

  @override
  Future<List<Estudiante>> getEstudiantesByGrupo(String grupoId) =>
      _database.getEstudiantesByGrupo(grupoId);

  @override
  Future<String> exportarAlumnosACsv(String grupoId) =>
      _database.exportarAlumnosACsv(grupoId);

  @override
  Future<Map<String, int>> importarAlumnosDesdeCsv({
    required String grupoId,
    required String csvContenido,
  }) => _database.importarAlumnosDesdeCsv(
        grupoId: grupoId,
        csvContenido: csvContenido,
      );
}