class Participacion {
  final String? participacionId;
  final String sesionId;
  final String estudianteId;
  final String actividadId;
  final int puntos;
  final String fecha;
  final String uuidTransaccion;

  Participacion({
    this.participacionId,
    required this.sesionId,
    required this.estudianteId,
    required this.actividadId,
    required this.puntos,
    required this.fecha,
    required this.uuidTransaccion,
  });

  Map<String, dynamic> toMap() => {
        if (participacionId != null) 'participacionId': participacionId,
        'sesionId': sesionId,
        'estudianteId': estudianteId,
        'actividadId': actividadId,
        'puntos': puntos,
        'fecha': fecha,
        'uuidTransaccion': uuidTransaccion,
      };

  factory Participacion.fromMap(Map<String, dynamic> map) => Participacion(
        participacionId: map['participacionId'] as String?,
        sesionId: map['sesionId'] as String? ?? '',
        estudianteId: map['estudianteId'] as String? ?? '',
        actividadId: map['actividadId'] as String? ?? '',
        puntos: map['puntos'] as int? ?? 0,
        fecha: map['fecha'] as String? ?? '',
        uuidTransaccion: map['uuidTransaccion'] as String? ?? '',
      );
}