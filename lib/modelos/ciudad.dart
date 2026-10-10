class Ciudad {
  final String nombre;
  final double latitud;
  final double longitud;

  Ciudad({
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  factory Ciudad.desdeJson(Map<String, dynamic> json) {
    return Ciudad(
      nombre: json['nombre'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
    );
  }

  @override
  String toString() => nombre;
}