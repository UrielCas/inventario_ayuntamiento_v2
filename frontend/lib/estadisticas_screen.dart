import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EstadisticasScreen extends StatefulWidget {
  final String token;
  const EstadisticasScreen({super.key, required this.token});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int totalEquipos = 0;
  int ticketsAbiertos = 0;
  int ticketsResueltos = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerEstadisticas();
  }

  Future<void> _obtenerEstadisticas() async {
    final url = Uri.parse('http://127.0.0.1:8000/estadisticas/');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            totalEquipos = data['total_equipos'] ?? 0;
            ticketsAbiertos = data['tickets_abiertos'] ?? 0;
            ticketsResueltos = data['tickets_resueltos'] ?? 0;
            _cargando = false;
          });
        }
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos matemáticos para los porcentajes reales de la gráfica
    double totalTickets = (ticketsAbiertos + ticketsResueltos).toDouble();
    double pctAbiertos = totalTickets > 0 ? (ticketsAbiertos / totalTickets * 100) : 0;
    double pctResueltos = totalTickets > 0 ? (ticketsResueltos / totalTickets * 100) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas y Reportes'),
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen Global del Sistema',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7A1C33)),
            ),
            const SizedBox(height: 20),
            
            // === TARJETAS CONECTADAS AL BACKEND ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard(context, 'Total Equipos', totalEquipos.toString(), Icons.computer, Colors.blueGrey),
                _buildSummaryCard(context, 'Tickets Abiertos', ticketsAbiertos.toString(), Icons.warning_amber_rounded, Colors.orange),
                _buildSummaryCard(context, 'Tickets Resueltos', ticketsResueltos.toString(), Icons.check_circle_outline, Colors.green),
              ],
            ),
            const SizedBox(height: 30),

            // === GRÁFICA DE PASTEL DINÁMICA ===
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Estado de Tickets (Histórico)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: totalTickets == 0 
                        ? const Center(child: Text('No hay tickets registrados aún', style: TextStyle(color: Colors.grey)))
                        : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              if (pctResueltos > 0)
                                PieChartSectionData(color: Colors.green, value: pctResueltos, title: '${pctResueltos.toStringAsFixed(1)}%\nResueltos', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              if (pctAbiertos > 0)
                                PieChartSectionData(color: Colors.orange, value: pctAbiertos, title: '${pctAbiertos.toStringAsFixed(1)}%\nPendientes', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // GRÁFICA DE BARRAS: FALLAS MÁS COMUNES (Mantenida estática por ahora)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Fallas Más Comunes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Text('Red/IP', style: TextStyle(fontSize: 12));
                                    case 1: return const Text('Hardware', style: TextStyle(fontSize: 12));
                                    case 2: return const Text('Software', style: TextStyle(fontSize: 12));
                                    case 3: return const Text('Impresora', style: TextStyle(fontSize: 12));
                                    default: return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: Colors.blueGrey, width: 20, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: const Color(0xFF7A1C33), width: 20, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.teal, width: 20, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: Colors.orange, width: 20, borderRadius: BorderRadius.circular(4))]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 5),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}





