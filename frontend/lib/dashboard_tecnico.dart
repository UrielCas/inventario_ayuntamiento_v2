// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // <-- IMPORTANTE PARA EL RELOJ AUTOMÁTICO
import 'pantalla_login.dart'; 

// ==========================================
// PALETA DE COLORES (ESTÉTICA AZUL PIZARRA)
// ==========================================
const Color colorPrincipal = Color(0xFF475569); 
const Color colorFondo = Color(0xFFF8FAFC); 
const Color colorAcento = Color(0xFF3B82F6); 

class DashboardTecnico extends StatefulWidget {
  final String token;
  final String nombre;
  const DashboardTecnico({Key? key, required this.token, required this.nombre}) : super(key: key);
  @override
  State<DashboardTecnico> createState() => _DashboardTecnicoState();
}

class _DashboardTecnicoState extends State<DashboardTecnico> {
  List<dynamic> _misTickets = [];
  bool _cargando = true;
  Timer? _temporizador; // <-- EL MOTOR DE AUTO-RECARGA

  @override
  void initState() {
    super.initState();
    cargarMisTickets();
    // Auto-recarga cada 60 segundos
    _temporizador = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarMisTickets();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel(); // Apagamos el reloj si cierra sesión
    super.dispose();
  }

  Future<void> cargarMisTickets() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/tickets/mis-asignaciones');
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        if(mounted) {
          setState(() {
            List<dynamic> ticketsDescargados = json.decode(response.body);
            _misTickets = ticketsDescargados.where((t) => t['estatus'] != 'Entregado').toList();
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if(mounted) setState(() => _cargando = false);
    }
  }

  Future<void> actualizarTrabajo(int ticketId, String nuevoEstatus, String trabajo, String piezas) async {
    final url = Uri.parse('http://127.0.0.1:8000/tickets/$ticketId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({
          "estatus": nuevoEstatus,
          "ejecucion_servicio": trabajo,
          "requerimiento_refaccion": piezas
        }),
      );
      if (response.statusCode == 200) {
        if(mounted) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trabajo guardado'), backgroundColor: Colors.green));
        cargarMisTickets(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalTrabajo(Map<String, dynamic> ticket) {
    String estatusSeleccionado = ticket['estatus'];
    final _trabajoController = TextEditingController(text: ticket['ejecucion_servicio'] ?? '');
    final _piezasController = TextEditingController(text: ticket['requerimiento_refaccion'] ?? '');
    final List<String> opcionesEstatus = ["En Reparación", "En Diagnóstico", "Espera de Piezas", "Reparado", "Baja Definitiva"];    

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Ticket #${ticket['id']} - ${ticket['departamento']}', style: const TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Falla reportada:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(ticket['diagnostico_inicial'], style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cambiar Estatus', border: OutlineInputBorder()),
                      value: opcionesEstatus.contains(estatusSeleccionado) ? estatusSeleccionado : "En Reparación",
                      items: opcionesEstatus.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setModalState(() => estatusSeleccionado = val!),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _trabajoController, maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Ejecución del Servicio (Lo que se le hizo)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _piezasController, maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Piezas requeridas / usadas (Opcional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorAcento, foregroundColor: Colors.white),
                onPressed: () => actualizarTrabajo(ticket['id'], estatusSeleccionado, _trabajoController.text, _piezasController.text),
                child: const Text('Guardar Avance'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo, 
      appBar: AppBar(
        title: Text('Taller | ${widget.nombre}'), 
        backgroundColor: colorPrincipal, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // === BOTÓN MANUAL DE RECARGA ===
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: 'Actualizar ahora',
            onPressed: () {
              setState(() => _cargando = true);
              cargarMisTickets(); 
            }
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin())))
        ]
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator(color: colorAcento))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis Equipos Asignados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _misTickets.isEmpty 
                        ? Center(child: Text('No tienes tickets pendientes.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)))
                        : ListView.builder(
                            itemCount: _misTickets.length,
                            itemBuilder: (context, index) {
                              final t = _misTickets[index];
                              return Card(
                                elevation: 2, 
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: const CircleAvatar(backgroundColor: colorAcento, child: Icon(Icons.build, color: Colors.white)),
                                  title: Text('Ticket #${t['id']} - Depto: ${t['departamento']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Estatus: ${t['estatus']}'),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: colorAcento, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.edit, size: 18), label: const Text('Trabajar'),
                                    onPressed: () => _mostrarModalTrabajo(t),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}