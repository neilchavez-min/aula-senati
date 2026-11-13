class Estudiante {
  final String? estudianteId;
  final String codigoInstitucional;
  final String nombres;
  final String apellidos;

  Estudiante({
    this.estudianteId,
    required this.codigoInstitucional,
    required this.nombres,
    required this.apellidos,
  });

  Map<String, dynamic> toMap() => {
        if (estudianteId != null) 'estudianteId': estudianteId,
        'codigoInstitucional': codigoInstitucional,
        'nombres': nombres,
        'apellidos': apellidos,
      };

  factory Estudiante.fromMap(Map<String, dynamic> map) => Estudiante(
        estudianteId: map['estudianteId'] as String?,
        codigoInstitucional: map['codigoInstitucional'] as String? ?? '',
        nombres: map['nombres'] as String? ?? '',
        apellidos: map['apellidos'] as String? ?? '',
      );

  String get nombreCompleto => '$apellidos, $nombres';
}