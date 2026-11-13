class Instructor {
  final String? instructorId;
  final String nombres;
  final String apellidos;
  final String correo;

  Instructor({
    this.instructorId,
    required this.nombres,
    required this.apellidos,
    required this.correo,
  });

  Map<String, dynamic> toMap() => {
        if (instructorId != null) 'instructorId': instructorId,
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
      };

  factory Instructor.fromMap(Map<String, dynamic> map) => Instructor(
        instructorId: map['instructorId'] as String?,
        nombres: map['nombres'] as String? ?? '',
        apellidos: map['apellidos'] as String? ?? '',
        correo: map['correo'] as String? ?? '',
      );

  String get nombreCompleto => '$apellidos, $nombres';
}