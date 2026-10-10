class ResultadoRiesgo {
  final double indice;
  final String nivel;

  ResultadoRiesgo({
    required this.indice,
    required this.nivel,
  });
}

class RiesgoExposicion {
  static ResultadoRiesgo calcular({
    required double pm25Promedio,
    required double horasExposicion,
  }) {
    final indice = pm25Promedio * (horasExposicion / 24.0) * 10.0;

    String nivel;
    if (indice < 50) {
      nivel = 'Bajo';
    } else if (indice < 100) {
      nivel = 'Moderado';
    } else if (indice < 150) {
      nivel = 'Alto';
    } else {
      nivel = 'Muy alto';
    }

    return ResultadoRiesgo(indice: indice, nivel: nivel);
  }
}