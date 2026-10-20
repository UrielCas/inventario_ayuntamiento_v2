// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para el temporizador automático
import 'main.dart'; // Para regresar al login
import 'pdf_generator.dart'; // Para generar la orden de salida

// ==========================================
// DASHBOARD DEL ADMIN (PANEL DE CONTROL Y ESTADÍSTICAS)
// ==========================================
class DashboardAdmin extends StatefulWidget {
  final String token;
  final String nombre;
  const DashboardAdmin({Key? key, required this.token, required this.nombre}) : super(key: key);
  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  List<dynamic> _tickets = [];
  List<dynamic> _tecnicos = [];
  bool _cargando = true;
  Timer? _temporizador; 
  int _indiceNavegacion = 0; // Controla qué pestaña estamos viendo

  @override
  void initState() {
    super.initState();
    cargarDatos();
    // Recarga invisible cada 60 segundos
    _temporizador = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarDatos();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel(); // Apagamos el reloj al salir
    super.dispose();
  }

  Future<void> cargarDatos() async {
    try {
      final urlTickets = Uri.parse('http://127.0.0.1:8000/tickets/todos');
      final urlTecnicos = Uri.parse('http://127.0.0.1:8000/usuarios/tecnicos');
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final respTickets = await http.get(urlTickets, headers: headers);
      final respTecnicos = await http.get(urlTecnicos, headers: headers);
      if (respTickets.statusCode == 200 && respTecnicos.statusCode == 200) {
        if (mounted) {
          setState(() {
            _tickets = json.decode(respTickets.body);
            _tecnicos = json.decode(respTecnicos.body);
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> asignarTecnico(int ticketId, String tecnicoIdStr) async {
    final url = Uri.parse('http://127.0.0.1:8000/tickets/$ticketId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({"estatus": "Asignado", "tecnico_asignado": tecnicoIdStr}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Técnico asignado exitosamente'), backgroundColor: Colors.green));
        cargarDatos(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al asignar'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red));
    }
  }

  Future<void> entregarEquipo(Map<String, dynamic> ticket) async {
    try {
      final urlEquipo = Uri.parse('http://127.0.0.1:8000/equipos/${ticket['equipo_id']}');
      final respEquipo = await http.get(urlEquipo, headers: {'Authorization': 'Bearer ${widget.token}'});
      
      if (respEquipo.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar datos del equipo'), backgroundColor: Colors.red));
        return;
      }
      final equipo = json.decode(respEquipo.body);

      final urlTicket = Uri.parse('http://127.0.0.1:8000/tickets/${ticket['id']}');
      final response = await http.put(
        urlTicket,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({"estatus": "Entregado"}),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo entregado y ticket cerrado'), backgroundColor: Colors.green));
        cargarDatos(); 
        
        await PdfGenerator.generarPdfSalida(
          folio: equipo['folio_inventario'],
          departamento: ticket['departamento'],
          tipoEquipo: equipo['tipo_equipo'] ?? 'N/A',
          marca: equipo['marca'] ?? 'N/A',
          modelo: equipo['modelo'] ?? 'N/A',
          diagnostico: ticket['diagnostico_inicial'],
          ejecucionServicio: ticket['ejecucion_servicio'] ?? 'Mantenimiento realizado',
          refacciones: ticket['requerimiento_refaccion'] ?? 'Ninguna',
          quienEntrega: widget.nombre, 
          quienRecibe: ticket['nombre_entrega'], 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cerrar el ticket'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalAsignacion(int ticketId, String falla) {
    String? tecnicoSeleccionado;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Asignar Técnico al Ticket', style: TextStyle(color: Colors.deepPurple)),
            content: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Falla reportada: $falla', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Selecciona un Técnico', border: OutlineInputBorder()),
                  value: tecnicoSeleccionado,
                  items: _tecnicos.map((t) { return DropdownMenuItem<String>(value: t['id'].toString(), child: Text(t['nombre'])); }).toList(),
                  onChanged: (val) => setModalState(() => tecnicoSeleccionado = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                onPressed: tecnicoSeleccionado == null ? null : () { Navigator.pop(context); asignarTecnico(ticketId, tecnicoSeleccionado!); },
                child: const Text('Asignar Trabajo'),
              ),
            ],
          );
        }
      ),
    );
  }





// ==========================================
  // VISTA 1: LA LISTA DE TICKETS (VERSIÓN FINAL COMPLETA)
  // ==========================================
  Widget _construirListaTickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tickets en Cola (Taller de TICs)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final t = _tickets[index];
              
              // --- BUSCAMOS AL TÉCNICO USANDO EL ID REAL ---
              String nombreTecnico = "";
              // Atrapamos el ID ya sea que llegue como tecnico_id o tecnico_asignado
              String idEncontrado = t['tecnico_id']?.toString() ?? t['tecnico_asignado']?.toString() ?? "";
              
              if (idEncontrado.isNotEmpty && idEncontrado != "null") {
                var tecnico = _tecnicos.firstWhere(
                  (tec) => tec['id'].toString() == idEncontrado, 
                  orElse: () => {'nombre': 'Desconocido'}
                );
                nombreTecnico = "\nTécnico: ${tecnico['nombre']}";
              }

              // --- VARIABLES DE CONTROL ---
              final bool esNuevo = t['estatus'] == 'Recibido';
              final bool esReparado = t['estatus'] == 'Reparado';
              final bool puedeReasignar = ['Asignado', 'En Diagnóstico', 'Espera de Piezas'].contains(t['estatus']);

              return Card(
                elevation: esNuevo ? 4 : 1, margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: esNuevo ? Colors.orange : (esReparado ? Colors.green : Colors.blueGrey), 
                    child: const Icon(Icons.computer, color: Colors.white)
                  ),
                  title: Text('Ticket #${t['id']} - Depto: ${t['departamento']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Falla: ${t['diagnostico_inicial']}\nEstatus: ${t['estatus']}$nombreTecnico'),
                  
                  // --- LÓGICA DEL BOTÓN REASIGNAR ---
                  trailing: esNuevo || puedeReasignar
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: esNuevo ? Colors.deepPurple : Colors.blueGrey, 
                            foregroundColor: Colors.white
                          ),
                          icon: const Icon(Icons.assignment_ind, size: 18), 
                          label: Text(esNuevo ? 'Asignar Técnico' : 'Reasignar'),
                          onPressed: () => _mostrarModalAsignacion(t['id'], t['diagnostico_inicial']),
                        )
                      : esReparado 
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check_circle, size: 18), label: const Text('Entregar Equipo'),
                              onPressed: () => entregarEquipo(t),
                            )
                          : Chip(label: Text(t['estatus'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueGrey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // ==========================================
  // VISTA 2: EL PANEL DE ESTADÍSTICAS 
  // ==========================================
  Widget _construirEstadisticas() {
    int total = _tickets.length;
    int nuevos = _tickets.where((t) => t['estatus'] == 'Recibido').length;
    int enProceso = _tickets.where((t) => ['Asignado', 'En Diagnóstico', 'Espera de Piezas'].contains(t['estatus'])).length;
    int terminados = _tickets.where((t) => ['Reparado', 'Entregado', 'Baja Definitiva'].contains(t['estatus'])).length;

    // 1. Cálculos de Departamentos
    Map<String, int> fallasPorDepto = {};
    for (var t in _tickets) {
      String depto = t['departamento'] ?? 'Desconocido';
      fallasPorDepto[depto] = (fallasPorDepto[depto] ?? 0) + 1;
    }
    var deptosOrdenados = fallasPorDepto.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 2. CORRECCIÓN: Cálculos de Carga por Técnico
    Map<String, String> mapaTecnicos = {};
    for (var tec in _tecnicos) {
      mapaTecnicos[tec['id'].toString()] = tec['nombre'];
    }

    Map<String, int> cargaPorTecnico = {};
    int totalAsignados = 0;
    for (var t in _tickets) {
      // Usamos 'tecnico_asignado' tal como viene de FastAPI
      if (t['tecnico_asignado'] != null && t['tecnico_asignado'].toString().isNotEmpty) { 
        String nombreTecnico = mapaTecnicos[t['tecnico_asignado'].toString()] ?? 'Desconocido';
        cargaPorTecnico[nombreTecnico] = (cargaPorTecnico[nombreTecnico] ?? 0) + 1;
        totalAsignados++;
      }
    }
    var tecnicosOrdenados = cargaPorTecnico.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen General del Taller', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _crearTarjetaEstadistica('Total Tickets', total.toString(), Icons.confirmation_number, Colors.blue),
              _crearTarjetaEstadistica('Nuevos (Sin Asignar)', nuevos.toString(), Icons.new_releases, Colors.orange),
            ],
          ),
          Row(
            children: [
              _crearTarjetaEstadistica('En Proceso', enProceso.toString(), Icons.build_circle, Colors.amber),
              _crearTarjetaEstadistica('Terminados', terminados.toString(), Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 30),

          const Text('Carga de Trabajo por Técnico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Card(
            elevation: 3,
            child: tecnicosOrdenados.isEmpty 
                ? const Padding(padding: EdgeInsets.all(20), child: Text('Aún no hay equipos asignados a los técnicos.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tecnicosOrdenados.length,
                    itemBuilder: (context, index) {
                      var tec = tecnicosOrdenados[index];
                      double porcentaje = totalAsignados > 0 ? tec.value / totalAsignados : 0;
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white, size: 18)),
                        title: Text(tec.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: porcentaje, backgroundColor: Colors.grey[300], color: Colors.orange),
                          ],
                        ),
                        trailing: Text('${tec.value} equipos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 30),

          const Text('Top Departamentos con más Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Card(
            elevation: 3,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deptosOrdenados.take(5).length,
              itemBuilder: (context, index) {
                var depto = deptosOrdenados[index];
                double porcentaje = total > 0 ? depto.value / total : 0;
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.business, color: Colors.white, size: 18)),
                  title: Text(depto.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      LinearProgressIndicator(value: porcentaje, backgroundColor: Colors.grey[300], color: Colors.deepPurple),
                    ],
                  ),
                  trailing: Text('${depto.value} equipos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }




  Widget _crearTarjetaEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icono, size: 40, color: color),
              const SizedBox(height: 10),
              Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Control | ${widget.nombre}'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: 'Actualizar ahora',
            onPressed: () {
              setState(() => _cargando = true);
              cargarDatos(); 
            }
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin())))
        ]
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: _indiceNavegacion == 0 ? _construirListaTickets() : _construirEstadisticas(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceNavegacion,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() {
            _indiceNavegacion = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
        ],
      ),
    );
  }
}