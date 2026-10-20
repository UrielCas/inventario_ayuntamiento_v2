import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_admin.dart';
import 'dashboard_recolector.dart';
import 'dashboard_tecnico.dart';
import 'recepcion_screen.dart'; // Importamos la nueva pantalla
import 'package:mobile_scanner/mobile_scanner.dart'; // NUEVO: Librería del escáner

void main() => runApp(const HelpdeskApp());

class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helpdesk Ayuntamiento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: const PantallaLogin(), 
    );
  }
}

// ==========================================
// PANTALLA: LOGIN
// ==========================================
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;










Future<void> iniciarSesion() async {
    setState(() => _cargando = true);
    
    final url = Uri.parse('http://127.0.0.1:8000/token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _correoController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String tokenDeAcceso = data['access_token'];
        
        // --- Atrapamos el rol y el nombre ---
        final String rolUsuario = data['rol'] ?? 'recolector'; 
        final String nombreUsuario = data['nombre'] ?? 'Usuario';

        if (mounted) {
          // --- EL SEMÁFORO DE PANTALLAS ---
          if (rolUsuario == 'admin') {
             // Va al nuevo Dashboard del Admin
             Navigator.pushReplacement(context, MaterialPageRoute(
               builder: (context) => DashboardAdmin(token: tokenDeAcceso, nombre: nombreUsuario)
             ));
          } 
          else if (rolUsuario == 'tecnico') {
             // Va al nuevo Dashboard del Técnico
             Navigator.pushReplacement(context, MaterialPageRoute(
               builder: (context) => DashboardTecnico(token: tokenDeAcceso, nombre: nombreUsuario)
             ));
          } 
          else {
             // Va al nuevo Dashboard del Recolector
             Navigator.pushReplacement(context, MaterialPageRoute(
               builder: (context) => DashboardRecolector(token: tokenDeAcceso, nombre: nombreUsuario)
             ));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correo o contraseña incorrectos'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con el servidor'), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(30),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),
                  const Text('H. Ayuntamiento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Portal de TICs', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: 'Correo Institucional', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : iniciarSesion,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: _cargando 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ==========================================
// PANTALLA PRINCIPAL (CON ROLES)
// ==========================================
class PantallaPrincipal extends StatefulWidget {
  final String token; 
  final String nombre; // NUEVO: Recibe el nombre
  final String rol;    // NUEVO: Recibe el rol

  const PantallaPrincipal({
    super.key, 
    required this.token,
    required this.nombre,
    required this.rol,
  });
  
  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}










class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _fallaController = TextEditingController();
  
  // Borramos el texto fijo, ahora el técnico se asignará automáticamente en el backend
  final TextEditingController _tecnicoController = TextEditingController(); 
  
  Map<String, dynamic>? _equipoData;
  String _mensaje = "Ingresa o escanea el ID del equipo";







// --- VARIABLES PARA EL NUEVO EQUIPO ---
  final _folioNuevoController = TextEditingController();
  final _deptoNuevoController = TextEditingController();
  final _ipNuevoController = TextEditingController();
  final _caracteristicasNuevoController = TextEditingController();
  final _tipoNuevoController = TextEditingController();
  final _marcaNuevoController = TextEditingController();
  final _modeloNuevoController = TextEditingController();

  Future<void> registrarEquipoNuevo() async {
    if (_folioNuevoController.text.isEmpty || _tipoNuevoController.text.isEmpty) return;

    final url = Uri.parse('http://127.0.0.1:8000/equipos/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
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
        if (mounted) Navigator.pop(context); // Cierra el modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Equipo agregado al inventario!'), backgroundColor: Colors.green)
        );
        
        // Magia pura: Pega el folio en el buscador y lo busca automáticamente
        _idController.text = _folioNuevoController.text;
        buscarEquipo(); 
        
        // Limpiamos los campos
        _folioNuevoController.clear();
        _deptoNuevoController.clear();
        _ipNuevoController.clear();
        _caracteristicasNuevoController.clear();
        _tipoNuevoController.clear();
        _marcaNuevoController.clear();
        _modeloNuevoController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar. ¿El folio ya existe?'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con el servidor'), backgroundColor: Colors.red)
      );
    }
  }

  void _mostrarModalNuevoEquipo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alta de Nuevo Equipo', style: TextStyle(color: Colors.teal)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _folioNuevoController, decoration: const InputDecoration(labelText: 'Folio de Inventario *', prefixIcon: Icon(Icons.qr_code))),
                TextField(controller: _tipoNuevoController, decoration: const InputDecoration(labelText: 'Tipo (Ej. CPU, Impresora) *')),
                TextField(controller: _marcaNuevoController, decoration: const InputDecoration(labelText: 'Marca')),
                TextField(controller: _modeloNuevoController, decoration: const InputDecoration(labelText: 'Modelo')),
                TextField(controller: _deptoNuevoController, decoration: const InputDecoration(labelText: 'Departamento Destino')),
                TextField(controller: _ipNuevoController, decoration: const InputDecoration(labelText: 'Dirección IP (Opcional)')),
                TextField(controller: _caracteristicasNuevoController, decoration: const InputDecoration(labelText: 'Características (Ej. Core i5, 8GB RAM)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: registrarEquipoNuevo,
            child: const Text('Guardar Equipo'),
          ),
        ],
      ),
    );
  }





Future<void> buscarEquipo() async {
    final id = _idController.text.trim(); // Agregamos .trim() por si se va un espacio
    if (id.isEmpty) return;
    
    final url = Uri.parse('http://127.0.0.1:8000/equipos/buscar/$id'); 
    
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      setState(() {
        if (response.statusCode == 200) {
          _equipoData = json.decode(response.body);
          _mensaje = "¡Equipo encontrado!";
          
          if (mounted) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => RecepcionScreen(
                   folioEquipo: _equipoData!['folio_inventario'],
                   equipoId: _equipoData!['id'], 
                   token: widget.token, 
                   // --- EXTRAEMOS LOS DATOS Y LOS ENVIAMOS ---
                   tipoEquipo: _equipoData!['tipo_equipo'] ?? 'N/A',
                   marca: _equipoData!['marca'] ?? 'N/A',
                   modelo: _equipoData!['modelo'] ?? 'N/A',
                   departamento: _equipoData!['departamento'] ?? 'N/A',
                 ),
               ),
             );
          }
          
        } else if (response.statusCode == 401) {
          _equipoData = null;
          _mensaje = "Tu sesión ha expirado.";
        } else {
          _equipoData = null;
          _mensaje = "Equipo no existe.";
        }
      });
    } catch (e) {
      setState(() { _equipoData = null; _mensaje = "Error de conexión."; });
    }
  }














  // --- NUEVO: FUNCIÓN PARA ABRIR LA CÁMARA ---
  void _abrirEscaner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escanea la etiqueta del equipo', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? codigo = barcodes.first.rawValue;
                if (codigo != null) {
                  Navigator.pop(context); // Cierra el modal de la cámara
                  _idController.text = codigo; // Pega el ID leído en la caja de texto
                  buscarEquipo(); // Lanza la búsqueda automáticamente
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

  Future<void> levantarTicket() async {
    final url = Uri.parse('http://127.0.0.1:8000/tickets/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}' 
        },
        body: jsonEncode({
          "equipo_id": _equipoData!['id'],
          "falla_reportada": _fallaController.text,
          "tecnico_asignado": _tecnicoController.text
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Ticket creado con éxito!'), backgroundColor: Colors.green)
        );
        _fallaController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear ticket'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> verHistorialTickets() async {
    final url = Uri.parse('http://127.0.0.1:8000/equipos/${_equipoData!['id']}/tickets');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'}, 
      );
      if (response.statusCode == 200) {
        final List<dynamic> tickets = json.decode(response.body);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Historial: ${_equipoData!['folio_inventario']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: tickets.isEmpty 
                  ? const Text('Este equipo está impecable. No tiene reportes previos.')
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
                          title: Text(t['falla_reportada'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Estatus: ${t['estatus']}\nTécnico: ${t['tecnico_asignado']}'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al obtener historial'), backgroundColor: Colors.red));
    }
  }

  void mostrarModalTicket() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Falla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _fallaController, decoration: const InputDecoration(labelText: 'Descripción de la falla')),
            const SizedBox(height: 10),
            TextField(controller: _tecnicoController, decoration: const InputDecoration(labelText: 'Técnico Asignado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: levantarTicket, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Enviar Reporte')
          ),
        ],
      ),
    );
  }






@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // NUEVO: El título cambia según quién inicie sesión
        title: Text('${widget.rol.toUpperCase()} | ${widget.nombre}'), 
        backgroundColor: widget.rol == 'admin' 
            ? Colors.deepPurple.shade100 // Color distinto si es jefe
            : Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin()));
            },
          )
        ],
      ),
      // --- NUEVO BOTÓN FLOTANTE ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevoEquipo,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_queue),
        label: const Text('Nuevo Equipo'),
      ),
      // ... (El resto de tu body con el escáner se queda igual)




      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _idController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'ID Equipo'))),
                const SizedBox(width: 10),
                // --- NUEVO: BOTÓN DE LA CÁMARA ---
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 45, color: Colors.teal),
                  onPressed: _abrirEscaner,
                  tooltip: 'Escanear QR',
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: buscarEquipo, 
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: const Text('Buscar')
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_mensaje, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            if (_equipoData != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(top: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Folio: ${_equipoData!['folio_inventario']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Text('Depto: ${_equipoData!['departamento']}', style: const TextStyle(fontSize: 16)),
                      Text('IP: ${_equipoData!['ip']}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: verHistorialTickets,
                            icon: const Icon(Icons.history, color: Colors.white),
                            label: const Text('Ver Historial', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)),
                          ),
                          ElevatedButton.icon(
                            onPressed: mostrarModalTicket,
                            icon: const Icon(Icons.warning, color: Colors.white),
                            label: const Text('Reportar Falla', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}