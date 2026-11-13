class Sesion {
  final String? sesionId;
  final String grupoId;
  final int numeroSesion;
  final String fecha;
  final String tema;
  final String tipoSesion;
  final int duracionHoras;
  final String observaciones;

  Sesion({
    this.sesionId,
    required this.grupoId,
    required this.numeroSesion,
    required this.fecha,
    required this.tema,
    required this.tipoSesion,
    required this.duracionHoras,
    required this.observaciones,
  });

  Map<String, dynamic> toMap() => {
        if (sesionId != null) 'sesionId': sesionId,
        'grupoId': grupoId,
        'numeroSesion': numeroSesion,
        'fecha': fecha,
        'tema': tema,
        'tipoSesion': tipoSesion,
        'duracionHoras': duracionHoras,
        'observaciones': observaciones,
      };

  factory Sesion.fromMap(Map<String, dynamic> map) => Sesion(
        sesionId: map['sesionId'] as String?,
        grupoId: map['grupoId'] as String? ?? '',
        numeroSesion: map['numeroSesion'] as int? ?? 1,
        fecha: map['fecha'] as String? ?? '',
        tema: map['tema'] as String? ?? '',
        tipoSesion: map['tipoSesion'] as String? ?? 'Teoría',
        duracionHoras: map['duracionHoras'] as int? ?? 2,
        observaciones: map['observaciones'] as String? ?? '',
      );
}