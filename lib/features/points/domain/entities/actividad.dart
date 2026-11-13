class Actividad {
  final String? actividadId;
  final String nombre;
  final String descripcion;
  final int valorDefecto;

  Actividad({
    this.actividadId,
    required this.nombre,
    required this.descripcion,
    this.valorDefecto = 1,
  });

  Map<String, dynamic> toMap() => {
        if (actividadId != null) 'actividadId': actividadId,
        'nombre': nombre,
        'descripcion': descripcion,
        'valorDefecto': valorDefecto,
      };

  factory Actividad.fromMap(Map<String, dynamic> map) => Actividad(
        actividadId: map['actividadId'] as String?,
        nombre: map['nombre'] as String? ?? '',
        descripcion: map['descripcion'] as String? ?? '',
        valorDefecto: map['valorDefecto'] as int? ?? 1,
      );
}