import 'dart:convert';
import 'package:http/http.dart' as http;

class CalidadDelAire {
  static const String _urlBase =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  Future<double> promedioPm25({
    required double latitud,
    required double longitud,
    required String fecha,
  }) async {
    final uri = Uri.parse(_urlBase).replace(queryParameters: {
      'latitude': latitud.toString(),
      'longitude': longitud.toString(),
      'hourly': 'pm2_5',
      'start_date': fecha,
      'end_date': fecha,
      'timezone': 'America/Bogota',
    });

    final respuesta = await http.get(uri);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo consultar la API (código ${respuesta.statusCode}).',
      );
    }

    final Map<String, dynamic> datos =
        jsonDecode(respuesta.body) as Map<String, dynamic>;

    final List<dynamic>? valores =
        datos['hourly']?['pm2_5'] as List<dynamic>?;

    if (valores == null || valores.isEmpty) {
      throw Exception('La API no devolvió datos para esa fecha.');
    }

    final numeros =
        valores.whereType<num>().map((v) => v.toDouble()).toList();

    if (numeros.isEmpty) {
      throw Exception('No hay valores de PM2.5 válidos para esa fecha.');
    }

    final suma = numeros.reduce((a, b) => a + b);
    return suma / numeros.length;
  }
}