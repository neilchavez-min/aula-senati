class Asistencia {
  final String? asistenciaId;
  final String sesionId;
  final String estudianteId;
  final String estado;
  final String fechaRegistro;
  final String observacion;

  static const List<String> estadosValidos = [
    'Presente',
    'Tardanza',
    'Falta',
    'Justificado',
  ];

  Asistencia({
    this.asistenciaId,
    required this.sesionId,
    required this.estudianteId,
    required this.estado,
    required this.fechaRegistro,
    this.observacion = '',
  }) {
    if (!estadosValidos.contains(estado)) {
      throw ArgumentError('Estado inválido: $estado. Debe ser uno de $estadosValidos');
    }
  }

  Map<String, dynamic> toMap() => {
        if (asistenciaId != null) 'asistenciaId': asistenciaId,
        'sesionId': sesionId,
        'estudianteId': estudianteId,
        'estado': estado,
        'fechaRegistro': fechaRegistro,
        'observacion': observacion,
      };

  factory Asistencia.fromMap(Map<String, dynamic> map) => Asistencia(
        asistenciaId: map['asistenciaId'] as String?,
        sesionId: map['sesionId'] as String? ?? '',
        estudianteId: map['estudianteId'] as String? ?? '',
        estado: map['estado'] as String? ?? 'Falta',
        fechaRegistro: map['fechaRegistro'] as String? ?? '',
        observacion: map['observacion'] as String? ?? '',
      );
}