// Autor: URIEL GUTIÉRREZ CASTILLO
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