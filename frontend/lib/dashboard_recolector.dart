// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart'; 
import 'recepcion_screen.dart';
import 'pantalla_login.dart';
import 'main.dart'; // Para el interruptor maestro de Modo Oscuro

// ==========================================
// PALETA DE COLORES
// ==========================================
const Color colorPrincipal = Color(0xFF475569); 
const Color colorAcento = Color(0xFF3B82F6); 

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

  XFile? _fotoSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // === MAGIA DE RED: Detecta la IP real de la computadora host ===
 String get apiUrl => 'https://2bbbf2bad08053.lhr.life';

  Future<void> buscarEquipo() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    
    final url = Uri.parse('$apiUrl/equipos/buscar/$id'); 
    
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
      setState(() { _mensaje = "Error de conexión con el servidor."; });
    }
  }

  void _abrirEscaner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escanea el QR', textAlign: TextAlign.center, style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
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
    final url = Uri.parse('$apiUrl/equipos/');
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      
      request.fields['folio_inventario'] = _folioNuevoController.text.trim();
      request.fields['departamento'] = _deptoNuevoController.text.trim();
      request.fields['ip'] = _ipNuevoController.text.trim().isEmpty ? "DHCP / No asignada" : _ipNuevoController.text.trim();
      request.fields['caracteristicas'] = _caracteristicasNuevoController.text.trim();
      request.fields['tipo_equipo'] = _tipoNuevoController.text.trim();
      request.fields['marca'] = _marcaNuevoController.text.trim();
      request.fields['modelo'] = _modeloNuevoController.text.trim();

      if (_fotoSeleccionada != null) {
        final bytes = await _fotoSeleccionada!.readAsBytes();
        final fileName = _fotoSeleccionada!.name.isNotEmpty ? _fotoSeleccionada!.name : 'foto.jpg';
        request.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: fileName));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Equipo agregado al inventario!'), backgroundColor: Colors.green));
        
        _idController.text = _folioNuevoController.text;
        _fotoSeleccionada = null; 
        buscarEquipo(); 
        
        _folioNuevoController.clear(); _deptoNuevoController.clear(); _ipNuevoController.clear();
        _caracteristicasNuevoController.clear(); _tipoNuevoController.clear(); _marcaNuevoController.clear(); _modeloNuevoController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${response.statusCode}: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red));
    }
  }

  void _mostrarModalNuevoEquipo() {
    _fotoSeleccionada = null; 
    // Variable para detectar si es celular (pantalla pequeña)
    bool esMovil = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text('Nuevo Equipo', style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.bold)),
            insetPadding: esMovil ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            content: SizedBox(
              width: esMovil ? double.maxFinite : 400, // Ajuste automático de ancho
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _folioNuevoController, decoration: const InputDecoration(labelText: 'Folio *', prefixIcon: Icon(Icons.qr_code, color: colorPrincipal))),
                    const SizedBox(height: 10),
                    TextField(controller: _tipoNuevoController, decoration: const InputDecoration(labelText: 'Tipo (Ej. CPU) *')),
                    const SizedBox(height: 10),
                    TextField(controller: _marcaNuevoController, decoration: const InputDecoration(labelText: 'Marca')),
                    const SizedBox(height: 10),
                    TextField(controller: _modeloNuevoController, decoration: const InputDecoration(labelText: 'Modelo')),
                    const SizedBox(height: 10),
                    TextField(controller: _deptoNuevoController, decoration: const InputDecoration(labelText: 'Depto. Destino')),
                    const SizedBox(height: 10),
                    TextField(controller: _ipNuevoController, decoration: const InputDecoration(labelText: 'IP (Opcional)')),
                    const SizedBox(height: 10),
                    TextField(controller: _caracteristicasNuevoController, decoration: const InputDecoration(labelText: 'Características')),
                    
                    const SizedBox(height: 20),
                    if (_fotoSeleccionada != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_fotoSeleccionada!.path, height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? foto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                        if (foto != null) {
                          setStateModal(() => _fotoSeleccionada = foto);
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_fotoSeleccionada == null ? 'Tomar Foto' : 'Cambiar Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _fotoSeleccionada == null ? colorPrincipal : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorAcento, foregroundColor: Colors.white),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardando...'), duration: Duration(seconds: 1)));
                  await registrarEquipoNuevo();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === DETECTOR DE PANTALLA ===
    bool esMovil = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(esMovil ? 'Recepción' : 'Recepción | ${widget.nombre}'), 
        backgroundColor: colorPrincipal, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, child) {
              return IconButton(
                tooltip: 'Cambiar Tema',
                onPressed: () {
                  themeNotifier.value = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                },
                icon: AnimatedRotation(
                  turns: mode == ThemeMode.light ? 0.0 : 0.5, 
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutBack, 
                  child: Image.asset('assets/dia-y-noche.png', width: 26, height: 26, color: Colors.white),
                ),
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              _idController.clear();
              setState(() => _mensaje = "Ingresa o escanea el ID del equipo.");
            }
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin())))
        ]
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevoEquipo, 
        backgroundColor: colorAcento, 
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_queue), 
        label: Text(esMovil ? 'Nuevo' : 'Registrar Equipo Nuevo'), // Más corto en celular
      ),
      body: Padding(
        padding: EdgeInsets.all(esMovil ? 10.0 : 20.0), // Menos margen en celular
        child: SingleChildScrollView(
          child: Column(
            children: [
              Icon(Icons.inventory, size: esMovil ? 50 : 80, color: colorPrincipal),
              const SizedBox(height: 10),
              Text('Módulo de Recepción', style: TextStyle(fontSize: esMovil ? 20 : 24, fontWeight: FontWeight.bold, color: colorPrincipal)),
              Text('Escanea o teclea el folio.', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(esMovil ? 10.0 : 20.0),
                  child: Column(
                    children: [
                      // La fila se adapta: En celular los botones son más compactos
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _idController, decoration: InputDecoration(border: const OutlineInputBorder(), labelText: 'Folio', prefixIcon: esMovil ? null : const Icon(Icons.search, color: colorPrincipal)))),
                          const SizedBox(width: 5),
                          IconButton(icon: const Icon(Icons.qr_code_scanner, size: 35, color: colorAcento), onPressed: _abrirEscaner),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: buscarEquipo, 
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(esMovil ? 15 : 20), 
                              backgroundColor: colorAcento, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ), 
                            child: esMovil ? const Icon(Icons.search) : const Text('Buscar') // En celular solo muestra lupa
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(_mensaje, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: esMovil ? 14 : 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}