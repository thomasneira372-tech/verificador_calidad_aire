import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'modelos/ciudad.dart';
import 'servicios/calidad_del_aire.dart';
import 'servicios/riesgo_exposicion.dart';
void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Calidad del Aire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const PantallaCalidadAire(),
    );
  }
}

class PantallaCalidadAire extends StatefulWidget {
  const PantallaCalidadAire({super.key});

  @override
  State<PantallaCalidadAire> createState() => _PantallaCalidadAireState();
}

class _PantallaCalidadAireState extends State<PantallaCalidadAire> {
  List<Ciudad> _ciudades = [];
  Ciudad? _ciudadElegida;

  DateTime _fecha = DateTime.now();
  final TextEditingController _controlFecha = TextEditingController();

  final TextEditingController _controlHoras =
      TextEditingController(text: '5');

  bool _consultando = false;
  ResultadoRiesgo? _resultado;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _controlFecha.text = _formatearFecha(_fecha);
    _cargarCiudades();
  }

  @override
  void dispose() {
    _controlFecha.dispose();
    _controlHoras.dispose();
    super.dispose();
  }

  Future<void> _cargarCiudades() async {
    try {
      final texto =
          await rootBundle.loadString('assets/data/ciudades_colombia.json');
      final List<dynamic> lista = jsonDecode(texto) as List<dynamic>;

      setState(() {
        _ciudades = lista
            .map((item) => Ciudad.desdeJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() {
        _mensajeError = 'No se pudieron cargar las ciudades: $e';
      });
    }
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha',
    );

    if (elegida != null) {
      setState(() {
        _fecha = elegida;
        _controlFecha.text = _formatearFecha(elegida);
      });
    }
  }

  String _formatearFecha(DateTime f) {
    final mes = f.month.toString().padLeft(2, '0');
    final dia = f.day.toString().padLeft(2, '0');
    return '${f.year}-$mes-$dia';
  }

  Future<void> _calcular() async {
    if (_ciudadElegida == null) {
      setState(() => _mensajeError = 'Por favor elige una ciudad.');
      return;
    }

    final horas = double.tryParse(_controlHoras.text.trim());
    if (horas == null || horas <= 0 || horas > 24) {
      setState(() =>
          _mensajeError = 'Escribe un número de horas entre 1 y 24.');
      return;
    }

    setState(() {
      _consultando = true;
      _mensajeError = null;
      _resultado = null;
    });

    try {
      final promedio = await CalidadDelAire().promedioPm25(
        latitud: _ciudadElegida!.latitud,
        longitud: _ciudadElegida!.longitud,
        fecha: _formatearFecha(_fecha),
      );

      final calculo = RiesgoExposicion.calcular(
        pm25Promedio: promedio,
        horasExposicion: horas,
      );

      setState(() {
        _resultado = calculo;
        _consultando = false;
      });
    } catch (e) {
      setState(() {
        _mensajeError = 'Ocurrió un problema al calcular: $e';
        _consultando = false;
      });
    }
  }

  Color _colorDelNivel(String nivel) {
    switch (nivel) {
      case 'Bajo':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Alto':
        return Colors.deepOrange;
      case 'Muy alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Calidad del Aire'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<Ciudad>(
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              value: _ciudadElegida,
              items: _ciudades
                  .map((c) => DropdownMenuItem<Ciudad>(
                        value: c,
                        child: Text(c.nombre),
                      ))
                  .toList(),
              onChanged: (valor) =>
                  setState(() => _ciudadElegida = valor),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _controlFecha,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha de consulta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _elegirFecha,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _controlHoras,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Horas de exposición diaria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _consultando ? null : _calcular,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _consultando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Calcular índice',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            if (_mensajeError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mensajeError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            if (_resultado != null) ...[
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Índice de exposición: '
                        '${_resultado!.indice.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _colorDelNivel(_resultado!.nivel),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nivel de riesgo: ${_resultado!.nivel}',
                        style: TextStyle(
                          fontSize: 18,
                          color: _colorDelNivel(_resultado!.nivel),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}