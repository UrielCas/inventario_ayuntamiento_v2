// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

import 'dart:async'; 
import 'package:mobile_scanner/mobile_scanner.dart'; // PARA EL ESCÁNER QR
import 'recepcion_screen.dart'; // PARA CREAR TICKET DESDE LA BÚSQUEDA
import 'pantalla_login.dart'; 
import 'pdf_generator.dart'; 



// ==========================================
// PALETA DE COLORES (ESTÉTICA AZUL PIZARRA)
// ==========================================
const Color colorPrincipal = Color(0xFF475569); // Slate Blue Clásico
const Color colorFondo = Color(0xFFF8FAFC); // Gris Perla suave
const Color colorAcento = Color(0xFF3B82F6); // Azul brillante para botones activos

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
  List<dynamic> _todosLosUsuarios = []; 
  bool _cargando = true;
  Timer? _temporizador; 
  int _indiceNavegacion = 0; 

  // === VARIABLES PARA LA PESTAÑA DE BÚSQUEDA ===
  final TextEditingController _idController = TextEditingController();
  String _mensajeBusqueda = "Listo para buscar.";
  Map<String, dynamic>? _equipoData;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    _temporizador = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarDatos();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    try {
      final urlTickets = Uri.parse('http://127.0.0.1:8000/tickets/todos');
      final urlTecnicos = Uri.parse('http://127.0.0.1:8000/usuarios/tecnicos');
      final urlUsuarios = Uri.parse('http://127.0.0.1:8000/usuarios/');
      final headers = {'Authorization': 'Bearer ${widget.token}'};

      final respTickets = await http.get(urlTickets, headers: headers);
      final respTecnicos = await http.get(urlTecnicos, headers: headers);
      final respUsuarios = await http.get(urlUsuarios, headers: headers); 

      if (respTickets.statusCode == 200 && respTecnicos.statusCode == 200 && respUsuarios.statusCode == 200) {
        if (mounted) {
          setState(() {
            _tickets = json.decode(respTickets.body);
            _tecnicos = json.decode(respTecnicos.body);
            _todosLosUsuarios = json.decode(respUsuarios.body); 
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ==========================================
  // FUNCIONES DE BÚSQUEDA (NUEVO MÓDULO RECUPERADO)
  // ==========================================
  Future<void> buscarEquipo() async {
    final id = _idController.text.trim(); 
    if (id.isEmpty) return;
    final url = Uri.parse('http://127.0.0.1:8000/equipos/buscar/$id'); 
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      setState(() {
        if (response.statusCode == 200) {
          _equipoData = json.decode(response.body);
          _mensajeBusqueda = "¡Equipo encontrado!";
        } else {
          _equipoData = null;
          _mensajeBusqueda = "Equipo no existe.";
        }
      });
    } catch (e) {
      setState(() { _equipoData = null; _mensajeBusqueda = "Error de conexión."; });
    }
  }

  void _abrirEscaner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escanea la etiqueta del equipo', textAlign: TextAlign.center, style: TextStyle(color: colorPrincipal)),
        content: SizedBox(
          width: 300,
          height: 300,
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> verHistorialTickets() async {
    final url = Uri.parse('http://127.0.0.1:8000/equipos/${_equipoData!['id']}/tickets');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        final List<dynamic> tickets = json.decode(response.body);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Historial: ${_equipoData!['folio_inventario']}', style: const TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: tickets.isEmpty 
                    ? Text('Este equipo está impecable. No tiene reportes previos.', style: TextStyle(color: Colors.grey.shade600))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final t = tickets[index];
                          return ListTile(
                            leading: Icon(
                              t['estatus'] == 'Reparado' ? Icons.check_circle : Icons.build,
                              color: t['estatus'] == 'Reparado' ? Colors.green : Colors.orange,
                            ),
                            title: Text(t['diagnostico_inicial'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Estatus: ${t['estatus']}\nTécnico: ${t['tecnico_asignado'] ?? "Sin asignar"}'),
                          );
                        },
                      ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al obtener historial'), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // FUNCIONES DE GESTIÓN DE PERSONAL 
  // ==========================================
  Future<void> registrarUsuario(String nombre, String correo, String password, String rol) async {
    final url = Uri.parse('http://127.0.0.1:8000/usuarios/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({
          "nombre_completo": nombre,
          "correo": correo,
          "password": password,
          "rol": rol
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal registrado exitosamente'), backgroundColor: Colors.green));
        cargarDatos(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${json.decode(response.body)['detail']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión con el servidor'), backgroundColor: Colors.red));
    }
  }

  Future<void> eliminarUsuario(int usuarioId) async {
    final url = Uri.parse('http://127.0.0.1:8000/usuarios/eliminar_fisico/$usuarioId');
    try {
      final response = await http.delete(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal dado de baja permanentemente'), backgroundColor: Colors.redAccent));
        cargarDatos(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al dar de baja'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión con el servidor'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalNuevoPersonal() {
    final _nombreController = TextEditingController();
    final _correoController = TextEditingController();
    final _passwordController = TextEditingController();
    String rolSeleccionado = 'tecnico'; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Alta de Nuevo Personal', style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: _correoController, decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña Temporal', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Rol en el Sistema', border: OutlineInputBorder()),
                    value: rolSeleccionado,
                    items: const [
                      DropdownMenuItem(value: 'tecnico', child: Text('Técnico de Taller')),
                      DropdownMenuItem(value: 'recolector', child: Text('Personal de Recepción')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador Total')),
                    ],
                    onChanged: (val) => setModalState(() => rolSeleccionado = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorPrincipal, foregroundColor: Colors.white),
                onPressed: () {
                  if (_nombreController.text.isNotEmpty && _correoController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                    Navigator.pop(context);
                    registrarUsuario(_nombreController.text, _correoController.text, _passwordController.text, rolSeleccionado);
                  }
                },
                child: const Text('Dar de Alta'),
              ),
            ],
          );
        }
      ),
    );
  }

  // ==========================================
  // FUNCIONES DE TICKETS
  // ==========================================
  Future<void> asignarTecnico(int ticketId, String nombreTecnico) async {
    final url = Uri.parse('http://127.0.0.1:8000/tickets/$ticketId/asignar');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({"nombre_tecnico": nombreTecnico}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Técnico asignado y ticket en reparación'), backgroundColor: Colors.green));
        cargarDatos(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al asignar: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión con el servidor'), backgroundColor: Colors.red));
    }
  }

  Future<void> entregarEquipo(Map<String, dynamic> ticket) async {
    try {
      final urlEquipo = Uri.parse('http://127.0.0.1:8000/equipos/${ticket['equipo_id']}');
      final respEquipo = await http.get(urlEquipo, headers: {'Authorization': 'Bearer ${widget.token}'});
      
      if (respEquipo.statusCode != 200) return;
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
      }
    } catch (e) {}
  }

  void _mostrarModalAsignacion(int ticketId, String falla) {
    String? tecnicoSeleccionado;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Asignar Técnico al Ticket', style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Falla reportada: $falla', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Selecciona un Técnico', border: OutlineInputBorder()),
                  value: tecnicoSeleccionado,
                  items: _tecnicos.map((t) { 
                    return DropdownMenuItem<String>(
                      value: t['nombre'], 
                      child: Text(t['nombre'])
                    ); 
                  }).toList(),
                  onChanged: (val) => setModalState(() => tecnicoSeleccionado = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorAcento, foregroundColor: Colors.white),
                onPressed: tecnicoSeleccionado == null ? null : () { 
                  Navigator.pop(context); 
                  asignarTecnico(ticketId, tecnicoSeleccionado!); 
                },
                child: const Text('Asignar Trabajo'),
              ),
            ],
          );
        }
      ),
    );
  }

  // ==========================================
  // VISTAS DEL DASHBOARD
  // ==========================================
  Widget _construirListaTickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tickets en Cola (Taller de Gobierno Digital)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final t = _tickets[index];
              final bool esNuevo = t['estatus'] == 'Recibido' || t['estatus'] == 'Pendiente';
              final bool esReparado = t['estatus'] == 'Reparado';
              final bool puedeReasignar = ['Asignado', 'En Diagnóstico', 'Espera de Piezas', 'En Reparación'].contains(t['estatus']);
              
              return Card(
                elevation: esNuevo ? 4 : 1, margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: esNuevo ? colorAcento : (esReparado ? Colors.green : Colors.blueGrey.shade300), 
                    child: const Icon(Icons.computer, color: Colors.white)
                  ),
                  title: Text('Ticket #${t['id']} - Depto: ${t['departamento']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Falla: ${t['diagnostico_inicial']}'),
                        Text('Estatus: ${t['estatus']}'),
                        const SizedBox(height: 4),
                        Text(
                          'Técnico: ${(t['tecnico_asignado'] != null && t['tecnico_asignado'].toString().isNotEmpty) ? t['tecnico_asignado'] : 'Sin asignar'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (t['tecnico_asignado'] != null && t['tecnico_asignado'].toString().isNotEmpty) ? colorPrincipal : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: esNuevo || puedeReasignar
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: esNuevo ? colorPrincipal : Colors.blueGrey, foregroundColor: Colors.white),
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
                          : Chip(
                              label: Text(t['estatus'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                              backgroundColor: t['estatus'] == 'Entregado' ? Colors.green : Colors.blueGrey.shade300,
                            ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === LA PESTAÑA RECUPERADA DE BÚSQUEDA ===
  Widget _construirBusqueda() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Búsqueda de Equipos e Historial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Buscar en Base de Datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrincipal)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Ingresa el ID o Folio', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),



                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 40, color: colorAcento),
                        onPressed: _abrirEscaner,
                        tooltip: 'Escanear QR',
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrincipal, 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: buscarEquipo,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar')
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_mensajeBusqueda, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          
          if (_equipoData != null)
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(top: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), 
                side: BorderSide(color: colorPrincipal.withOpacity(0.3))
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Folio: ${_equipoData!['folio_inventario']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorPrincipal)),
                        Chip(
                          label: const Text('Encontrado'), 
                          backgroundColor: Colors.green.shade100, 
                          labelStyle: TextStyle(color: Colors.green.shade800)
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    if (_equipoData!['ruta_foto'] != null)
                      Center( 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15), 
                            child: Image.network(
                              'http://127.0.0.1:8000${_equipoData!['ruta_foto']}', 
                              height: 180, 
                              width: 180,  
                              fit: BoxFit.cover, 
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 180, width: 180, color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    ListTile(
                      leading: const Icon(Icons.business, color: colorPrincipal),
                      title: const Text('Departamento / Área', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_equipoData!['departamento']}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.network_wifi, color: colorPrincipal),
                      title: const Text('Dirección IP', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_equipoData!['ip']}'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: colorPrincipal, side: const BorderSide(color: colorPrincipal)),
                          onPressed: verHistorialTickets,
                          icon: const Icon(Icons.history),
                          label: const Text('Ver Historial'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: colorAcento, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => RecepcionScreen(
                                folioEquipo: _equipoData!['folio_inventario'],
                                equipoId: _equipoData!['id'], 
                                token: widget.token, 
                                tipoEquipo: _equipoData!['tipo_equipo'] ?? 'N/A',
                                marca: _equipoData!['marca'] ?? 'N/A',
                                modelo: _equipoData!['modelo'] ?? 'N/A',
                                departamento: _equipoData!['departamento'] ?? 'N/A',
                              ),
                            ));
                          },
                          icon: const Icon(Icons.add_to_queue),
                          label: const Text('Generar Nuevo Ticket'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _construirEstadisticas() {
    int total = _tickets.length;
    int nuevos = _tickets.where((t) => t['estatus'] == 'Recibido' || t['estatus'] == 'Pendiente').length;
    int enProceso = _tickets.where((t) => ['Asignado', 'En Reparación', 'En Diagnóstico', 'Espera de Piezas'].contains(t['estatus'])).length;
    int terminados = _tickets.where((t) => ['Reparado', 'Entregado', 'Baja Definitiva'].contains(t['estatus'])).length;

    Map<String, int> fallasPorDepto = {};
    for (var t in _tickets) {
      String depto = t['departamento'] ?? 'Desconocido';
      fallasPorDepto[depto] = (fallasPorDepto[depto] ?? 0) + 1;
    }
    var deptosOrdenados = fallasPorDepto.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    Map<String, int> cargaPorTecnico = {};
    int totalAsignados = 0;
    for (var t in _tickets) {
      if (t['tecnico_asignado'] != null && t['tecnico_asignado'].toString().isNotEmpty) { 
        String nombreTecnico = t['tecnico_asignado'];
        cargaPorTecnico[nombreTecnico] = (cargaPorTecnico[nombreTecnico] ?? 0) + 1;
        totalAsignados++;
      }
    }
    var tecnicosOrdenados = cargaPorTecnico.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen General del Taller', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
          const SizedBox(height: 20),
          Row(
            children: [
              _crearTarjetaEstadistica('Total Tickets', total.toString(), Icons.confirmation_number, colorPrincipal),
              _crearTarjetaEstadistica('Nuevos (Sin Asignar)', nuevos.toString(), Icons.new_releases, colorAcento),
            ],
          ),
          Row(
            children: [
              _crearTarjetaEstadistica('En Proceso', enProceso.toString(), Icons.build_circle, Colors.amber.shade700),
              _crearTarjetaEstadistica('Terminados', terminados.toString(), Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Carga de Trabajo por Técnico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrincipal)),
          const SizedBox(height: 15),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        leading: const CircleAvatar(backgroundColor: colorAcento, child: Icon(Icons.person, color: Colors.white, size: 18)),
                        title: Text(tec.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: porcentaje, backgroundColor: Colors.grey[200], color: colorAcento),
                          ],
                        ),
                        trailing: Text('${tec.value} equipos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorAcento)),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 30),
          const Text('Top Departamentos con más Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrincipal)),
          const SizedBox(height: 15),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deptosOrdenados.take(5).length,
              itemBuilder: (context, index) {
                var depto = deptosOrdenados[index];
                double porcentaje = total > 0 ? depto.value / total : 0;
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: colorPrincipal, child: Icon(Icons.business, color: Colors.white, size: 18)),
                  title: Text(depto.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      LinearProgressIndicator(value: porcentaje, backgroundColor: Colors.grey[200], color: colorPrincipal),
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icono, size: 40, color: color),
              const SizedBox(height: 10),
              Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirGestionPersonal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Gestión de Personal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Nuevo Personal'),
              onPressed: _mostrarModalNuevoPersonal,
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _todosLosUsuarios.length,
            itemBuilder: (context, index) {
              final user = _todosLosUsuarios[index];
              return Card(
                elevation: 1, margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['rol'] == 'admin' ? colorPrincipal : (user['rol'] == 'tecnico' ? colorAcento : Colors.orange),
                    child: Icon(user['rol'] == 'admin' ? Icons.security : (user['rol'] == 'tecnico' ? Icons.handyman : Icons.receipt), color: Colors.white, size: 20)
                  ),
                  title: Text(user['nombre_completo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['correo']} • Rol: ${user['rol'].toUpperCase()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Dar de baja',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar Baja', style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
                          content: Text('¿Estás seguro de eliminar a ${user['nombre_completo']}? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () { Navigator.pop(context); eliminarUsuario(user['id']); },
                              child: const Text('Eliminar Permanentemente'),
                            )
                          ],
                        )
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(


appBar: AppBar(
        title: Text('Panel de Control | ${widget.nombre}'), 
        backgroundColor: colorPrincipal, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          
          // === AQUÍ PEGASTE EL NUEVO BOTÓN ANIMADO ===
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, child) {
              return IconButton(
                tooltip: 'Cambiar Tema',
                onPressed: () {
                  themeNotifier.value = mode == ThemeMode.light 
                      ? ThemeMode.dark 
                      : ThemeMode.light;
                },
                icon: AnimatedRotation(
                  turns: mode == ThemeMode.light ? 0.0 : 0.5, 
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutBack, 
                  child: Image.asset(
                    'assets/dia-y-noche.png',
                    width: 26,
                    height: 26,
                    color: Colors.white, 
                  ),
                ),
              );
            }
          ),

          // LOS BOTONES QUE YA TENÍAS SE QUEDAN IGUAL
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
          ? const Center(child: CircularProgressIndicator(color: colorAcento))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              // === AQUÍ DIRIGIMOS A CADA PESTAÑA ===
              child: _indiceNavegacion == 0 
                  ? _construirListaTickets() 
                  : (_indiceNavegacion == 1 
                      ? _construirBusqueda() 
                      : (_indiceNavegacion == 2 ? _construirEstadisticas() : _construirGestionPersonal())),
            ),




      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceNavegacion,
        type: BottomNavigationBarType.fixed, // Asegura que los íconos no se muevan raro al tener más de 3
        selectedItemColor: colorAcento,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 10,
        onTap: (index) {
          setState(() {
            _indiceNavegacion = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Búsqueda'), // LA NUEVA PESTAÑA
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Personal'),
        ],
      ),
    );
  }
}



