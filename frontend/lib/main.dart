import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_admin.dart';
import 'dashboard_recolector.dart';
import 'dashboard_tecnico.dart';
import 'recepcion_screen.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart'; 

void main() => runApp(const HelpdeskApp());

class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helpdesk Ayuntamiento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A1C33), 
          primary: const Color(0xFF7A1C33),
          secondary: Colors.blueGrey.shade800, 
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7A1C33), 
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A1C33),
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), 
            borderSide: BorderSide(color: Colors.grey.shade300)
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), 
            borderSide: const BorderSide(color: Color(0xFF7A1C33), width: 2)
          ),
          prefixIconColor: Colors.blueGrey.shade600,
        ),
      ),
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
        
        final String rolUsuario = data['rol'] ?? 'recolector'; 
        final String nombreUsuario = data['nombre'] ?? 'Usuario';
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PantallaPrincipal(token: tokenDeAcceso, nombre: nombreUsuario, rol: rolUsuario)
          ));
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
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white, 
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            child: Image.asset(
              'assets/logo_ayuntamiento.jpeg', 
              height: 80, 
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.all(30),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings, size: 80, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 20),
                        const Text('H. Ayuntamiento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Gobierno Digital', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _correoController,
                          decoration: const InputDecoration(labelText: 'Correo Institucional', prefixIcon: Icon(Icons.email)),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : iniciarSesion,
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
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL 
// ==========================================
class PantallaPrincipal extends StatefulWidget {
  final String token; 
  final String nombre; 
  final String rol;    
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
  final TextEditingController _tecnicoController = TextEditingController(); 
  
  Map<String, dynamic>? _equipoData;
  String _mensaje = "Listo para buscar.";

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
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Equipo agregado!'), backgroundColor: Colors.green));
        _idController.text = _folioNuevoController.text;
        buscarEquipo(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalNuevoEquipo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alta de Nuevo Equipo', style: TextStyle(color: Color(0xFF7A1C33))),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _folioNuevoController, decoration: const InputDecoration(labelText: 'Folio de Inventario *', prefixIcon: Icon(Icons.qr_code))),
                const SizedBox(height: 10),
                TextField(controller: _tipoNuevoController, decoration: const InputDecoration(labelText: 'Tipo (Ej. CPU, Impresora) *')),
                const SizedBox(height: 10),
                TextField(controller: _marcaNuevoController, decoration: const InputDecoration(labelText: 'Marca')),
                const SizedBox(height: 10),
                TextField(controller: _modeloNuevoController, decoration: const InputDecoration(labelText: 'Modelo')),
                const SizedBox(height: 10),
                TextField(controller: _deptoNuevoController, decoration: const InputDecoration(labelText: 'Departamento Destino')),
                const SizedBox(height: 10),
                TextField(controller: _ipNuevoController, decoration: const InputDecoration(labelText: 'Dirección IP (Opcional)')),
                const SizedBox(height: 10),
                TextField(controller: _caracteristicasNuevoController, decoration: const InputDecoration(labelText: 'Características (Ej. Core i5, 8GB RAM)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: registrarEquipoNuevo, child: const Text('Guardar Equipo')),
        ],
      ),
    );
  }

  Future<void> buscarEquipo() async {
    final id = _idController.text.trim(); 
    if (id.isEmpty) return;
    final url = Uri.parse('http://127.0.0.1:8000/equipos/buscar/$id'); 
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
      setState(() {
        if (response.statusCode == 200) {
          _equipoData = json.decode(response.body);
          _mensaje = "¡Equipo encontrado!";
        } else {
          _equipoData = null;
          _mensaje = "Equipo no existe.";
        }
      });
    } catch (e) {
      setState(() { _equipoData = null; _mensaje = "Error de conexión."; });
    }
  }

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

  Future<void> levantarTicket() async {
    final url = Uri.parse('http://127.0.0.1:8000/tickets/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({
          "equipo_id": _equipoData!['id'],
          "falla_reportada": _fallaController.text,
          "tecnico_asignado": _tecnicoController.text
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Ticket creado con éxito!'), backgroundColor: Colors.green));
        _fallaController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear ticket'), backgroundColor: Colors.red));
    }
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
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al obtener historial'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gestión'), 
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              accountName: Text(widget.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text('Rol: ${widget.rol.toUpperCase()}'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF7A1C33)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Recepción y Búsqueda'),
              onTap: () => Navigator.pop(context), 
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Estadísticas y Reportes'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Módulo en construcción...')));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin()));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevoEquipo,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_queue),
        label: const Text('Nuevo Equipo'),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Búsqueda de Equipos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Ingresa el ID o Folio'))),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner, size: 40, color: Theme.of(context).colorScheme.primary),
                          onPressed: _abrirEscaner,
                          tooltip: 'Escanear QR',
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: buscarEquipo, 
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar')
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_mensaje, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
                  // CORRECCIÓN 1: 'side' en lugar de 'borderSide'
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Folio: ${_equipoData!['folio_inventario']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7A1C33))),
                          // CORRECCIÓN 2: Se quitó el 'const' que provocaba error en el texto y color
                          Chip(
                            label: const Text('Encontrado'), 
                            backgroundColor: Colors.green.shade100, 
                            labelStyle: TextStyle(color: Colors.green.shade800)
                          ),
                        ],
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.business),
                        title: const Text('Departamento / Área'),
                        subtitle: Text('${_equipoData!['departamento']}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.network_wifi),
                        title: const Text('Dirección IP'),
                        subtitle: Text('${_equipoData!['ip']}'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: verHistorialTickets,
                            icon: const Icon(Icons.history),
                            label: const Text('Historial'),
                          ),
                          ElevatedButton.icon(
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
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Generar Ticket / Evidencia'),
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