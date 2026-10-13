// Autor: URIEL GUTIÉRREZ CASTILLO
import 'pdf_generator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'recepcion_screen.dart';
import 'main.dart'; 

// ==========================================
// DASHBOARD DEL RECOLECTOR (LA MUDANZA)
// ==========================================
class DashboardRecolector extends StatefulWidget {
  final String token;
  final String nombre;
  const DashboardRecolector({Key? key, required this.token, required this.nombre}) : super(key: key);
  @override
  State<DashboardRecolector> createState() => _DashboardRecolectorState();
}

class _DashboardRecolectorState extends State<DashboardRecolector> {
  final TextEditingController _idController = TextEditingController();
  String _mensaje = "Ingresa o escanea el ID del equipo para registrar su entrada.";
  
  final _folioNuevoController = TextEditingController();
  final _deptoNuevoController = TextEditingController();
  final _ipNuevoController = TextEditingController();
  final _caracteristicasNuevoController = TextEditingController();
  final _tipoNuevoController = TextEditingController();
  final _marcaNuevoController = TextEditingController();
  final _modeloNuevoController = TextEditingController();

  Future<void> buscarEquipo() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    
    final url = Uri.parse('http://127.0.0.1:8000/equipos/buscar/$id'); 
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      setState(() {
        if (response.statusCode == 200) {
          final equipoData = json.decode(response.body);
          _mensaje = "¡Equipo encontrado!";
          
          if (mounted) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => RecepcionScreen(
                   folioEquipo: equipoData['folio_inventario'],
                   equipoId: equipoData['id'], 
                   token: widget.token, 
                   tipoEquipo: equipoData['tipo_equipo'] ?? 'N/A',
                   marca: equipoData['marca'] ?? 'N/A',
                   modelo: equipoData['modelo'] ?? 'N/A',
                   departamento: equipoData['departamento'] ?? 'N/A',
                 ),
               ),
             ).then((_) {
                 _idController.clear();
                 setState(() => _mensaje = "Ingresa o escanea otro equipo.");
             });
          }
        } else if (response.statusCode == 401) {
          _mensaje = "Tu sesión ha expirado.";
        } else {
          _mensaje = "El equipo no existe. Regístralo en el botón flotante.";
        }
      });
    } catch (e) {
      setState(() { _mensaje = "Error de conexión."; });
    }
  }

  void _abrirEscaner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escanea la etiqueta del equipo', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300, height: 300,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? codigo = barcodes.first.rawValue;
                if (codigo != null) {
                  Navigator.pop(context); 
                  _idController.text = codigo; 
                  buscarEquipo(); 
                }
              }
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red)))],
      ),
    );
  }

  Future<void> registrarEquipoNuevo() async {
    if (_folioNuevoController.text.isEmpty || _tipoNuevoController.text.isEmpty) return;
    final url = Uri.parse('http://127.0.0.1:8000/equipos/');
    try {
      final response = await http.post(
        url,
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}' },
        body: jsonEncode({
          "folio_inventario": _folioNuevoController.text.trim(),
          "departamento": _deptoNuevoController.text.trim(),
          "ip": _ipNuevoController.text.trim().isEmpty ? "DHCP / No asignada" : _ipNuevoController.text.trim(),
          "caracteristicas": _caracteristicasNuevoController.text.trim(),
          "tipo_equipo": _tipoNuevoController.text.trim(),
          "marca": _marcaNuevoController.text.trim(),
          "modelo": _modeloNuevoController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Equipo agregado al inventario!'), backgroundColor: Colors.green));
        
        _idController.text = _folioNuevoController.text;
        buscarEquipo(); 
        
        _folioNuevoController.clear(); _deptoNuevoController.clear(); _ipNuevoController.clear();
        _caracteristicasNuevoController.clear(); _tipoNuevoController.clear(); _marcaNuevoController.clear(); _modeloNuevoController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalNuevoEquipo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alta de Nuevo Equipo', style: TextStyle(color: Colors.blue)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _folioNuevoController, decoration: const InputDecoration(labelText: 'Folio de Inventario *', prefixIcon: Icon(Icons.qr_code))),
                TextField(controller: _tipoNuevoController, decoration: const InputDecoration(labelText: 'Tipo (Ej. CPU) *')),
                TextField(controller: _marcaNuevoController, decoration: const InputDecoration(labelText: 'Marca')),
                TextField(controller: _modeloNuevoController, decoration: const InputDecoration(labelText: 'Modelo')),
                TextField(controller: _deptoNuevoController, decoration: const InputDecoration(labelText: 'Departamento Destino')),
                TextField(controller: _ipNuevoController, decoration: const InputDecoration(labelText: 'Dirección IP (Opcional)')),
                TextField(controller: _caracteristicasNuevoController, decoration: const InputDecoration(labelText: 'Características')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: registrarEquipoNuevo,
            child: const Text('Guardar Equipo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recepción | ${widget.nombre}'), backgroundColor: Colors.blue, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin())))]
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevoEquipo, backgroundColor: Colors.blue, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_queue), label: const Text('Registrar Equipo Nuevo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.inventory, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Módulo de Recepción', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Escanea o teclea el folio para recibir un equipo en el taller.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: TextField(controller: _idController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Folio del Equipo'))),
                const SizedBox(width: 10),
                IconButton(icon: const Icon(Icons.qr_code_scanner, size: 45, color: Colors.blue), onPressed: _abrirEscaner, tooltip: 'Escanear QR'),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: buscarEquipo, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('Buscar')),
              ],
            ),
            const SizedBox(height: 20),
            Text(_mensaje, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}




















// ==========================================
// DASHBOARD DEL ADMIN (PANEL DE CONTROL)
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
  Timer? _temporizador; // <-- NUEVO: Variable para el reloj interno
@override
  void initState() {
    super.initState();
    cargarDatos();
    
    // <-- CAMBIO: Ahora dice "minutes: 1"
    _temporizador = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarDatos();
    });
  }

  // <-- NUEVO: Función para destruir el reloj cuando cierras sesión
  @override
  void dispose() {
    _temporizador?.cancel();
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
        setState(() {
          _tickets = json.decode(respTickets.body);
          _tecnicos = json.decode(respTecnicos.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
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























// --- FUNCIÓN ACTUALIZADA Y LIMPIA: CIERRE Y ENTREGA DE EQUIPO ---
  Future<void> entregarEquipo(Map<String, dynamic> ticket) async {
    try {
      // 1. Primero obtenemos los detalles del equipo (Marca, modelo, etc.)
      final urlEquipo = Uri.parse('http://127.0.0.1:8000/equipos/${ticket['equipo_id']}');
      final respEquipo = await http.get(urlEquipo, headers: {'Authorization': 'Bearer ${widget.token}'});
      
      if (respEquipo.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar datos del equipo'), backgroundColor: Colors.red));
        return;
      }
      final equipo = json.decode(respEquipo.body);

      // 2. Cerramos el ticket en la base de datos
      final urlTicket = Uri.parse('http://127.0.0.1:8000/tickets/${ticket['id']}');
      final response = await http.put(
        urlTicket,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({"estatus": "Entregado"}),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo entregado y ticket cerrado'), backgroundColor: Colors.green));
        cargarDatos(); // Recargamos la lista
        
        // 3. Generamos el PDF de salida automáticamente (El import de esto ya debe estar en la línea 1 del archivo)
        await PdfGenerator.generarPdfSalida(
          folio: equipo['folio_inventario'],
          departamento: ticket['departamento'],
          tipoEquipo: equipo['tipo_equipo'] ?? 'N/A',
          marca: equipo['marca'] ?? 'N/A',
          modelo: equipo['modelo'] ?? 'N/A',
          diagnostico: ticket['diagnostico_inicial'],
          ejecucionServicio: ticket['ejecucion_servicio'] ?? 'Mantenimiento realizado',
          refacciones: ticket['requerimiento_refaccion'] ?? 'Ninguna',
          quienEntrega: widget.nombre, // El administrador actual
          quienRecibe: ticket['nombre_entrega'], // Quien lo trajo originalmente
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
appBar: AppBar(
        title: Text('Panel de Control | ${widget.nombre}'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
        actions: [
          // <-- NUEVO: BOTÓN DE ACTUALIZAR MANUAL -->
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tickets en Cola (Taller de TICs)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        final bool esNuevo = t['estatus'] == 'Recibido';
                        final bool esReparado = t['estatus'] == 'Reparado'; // NUEVO: Identificador de equipo listo
                        
                        return Card(
                          elevation: esNuevo ? 4 : 1, margin: const EdgeInsets.only(bottom: 15),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: CircleAvatar(
                              backgroundColor: esNuevo ? Colors.orange : (esReparado ? Colors.green : Colors.blueGrey), 
                              child: const Icon(Icons.computer, color: Colors.white)
                            ),
                            title: Text('Ticket #${t['id']} - Depto: ${t['departamento']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Falla: ${t['diagnostico_inicial']}\nEstatus: ${t['estatus']}'),
                            // --- NUEVA LÓGICA DE BOTONES ---
                            trailing: esNuevo 
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.assignment_ind, size: 18), label: const Text('Asignar Técnico'),
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
              ),
            ),
    );
  }
}















    


// ==========================================
// DASHBOARD DEL TÉCNICO (EL TALLER)
// ==========================================
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

  @override
  void initState() {
    super.initState();
    cargarMisTickets();
  }

  Future<void> cargarMisTickets() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/tickets/mis-asignaciones');
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});

      if (response.statusCode == 200) {
        setState(() {
          _misTickets = json.decode(response.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
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
        if(mounted) Navigator.pop(context); // Cierra el modal
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

    final List<String> opcionesEstatus = ["Asignado", "En Diagnóstico", "Espera de Piezas", "Reparado", "Baja Definitiva"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Ticket #${ticket['id']} - ${ticket['departamento']}', style: const TextStyle(color: Colors.orange)),
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
                      value: opcionesEstatus.contains(estatusSeleccionado) ? estatusSeleccionado : "Asignado",
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
      appBar: AppBar(
        title: Text('Taller | ${widget.nombre}'), backgroundColor: Colors.orange, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin())))]
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis Equipos Asignados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _misTickets.isEmpty 
                        ? const Center(child: Text('No tienes tickets pendientes.', style: TextStyle(color: Colors.grey, fontSize: 18)))
                        : ListView.builder(
                            itemCount: _misTickets.length,
                            itemBuilder: (context, index) {
                              final t = _misTickets[index];
                              return Card(
                                elevation: 3, margin: const EdgeInsets.only(bottom: 15),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.build, color: Colors.white)),
                                  title: Text('Ticket #${t['id']} - Depto: ${t['departamento']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Estatus: ${t['estatus']}'),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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









