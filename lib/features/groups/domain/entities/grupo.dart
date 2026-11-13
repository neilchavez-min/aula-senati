class Grupo {
  final String? grupoId;
  final String codigo;
  final String nombre;
  final String programa;
  final String asignatura;
  final String periodo;
  final String seccion;
  final String? instructorId;

  Grupo({
    this.grupoId,
    required this.codigo,
    required this.nombre,
    required this.programa,
    required this.asignatura,
    required this.periodo,
    required this.seccion,
    this.instructorId,
  });

  Map<String, dynamic> toMap() => {
        if (grupoId != null) 'grupoId': grupoId,
        'codigo': codigo,
        'nombre': nombre,
        'programa': programa,
        'asignatura': asignatura,
        'periodo': periodo,
        'seccion': seccion,
        'instructorId': instructorId,
      };

  factory Grupo.fromMap(Map<String, dynamic> map) => Grupo(
        grupoId: map['grupoId'] as String?,
        codigo: map['codigo'] as String? ?? '',
        nombre: map['nombre'] as String? ?? '',
        programa: map['programa'] as String? ?? '',
        asignatura: map['asignatura'] as String? ?? '',
        periodo: map['periodo'] as String? ?? '',
        seccion: map['seccion'] as String? ?? '',
        instructorId: map['instructorId'] as String?,
      );
}