// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pdf_generator.dart'; // Importante: Aquí llamamos a tu generador

class RecepcionScreen extends StatefulWidget {
  final String folioEquipo;
  final int equipoId; 
  final String token; 
  
  // --- VARIABLES QUE RECIBEN LA INFO DE LA BD ---
  final String tipoEquipo;
  final String marca;
  final String modelo;
  final String departamento;

  const RecepcionScreen({
    Key? key, 
    required this.folioEquipo,
    required this.equipoId, 
    required this.token,    
    required this.tipoEquipo,
    required this.marca,
    required this.modelo,
    required this.departamento,
  }) : super(key: key);

  @override
  _RecepcionScreenState createState() => _RecepcionScreenState();
}

class _RecepcionScreenState extends State<RecepcionScreen> {
  final _nombreEntregaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _accesoriosController = TextEditingController();
  final _estadoFisicoController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Autorellena el campo con el departamento registrado en la BD
    _departamentoController.text = widget.departamento; 
  }











  Future<void> registrarIngreso() async {
    if (_nombreEntregaController.text.isEmpty || _diagnosticoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena el Nombre y el Diagnóstico'), backgroundColor: Colors.orange)
      );
      return;
    }
    setState(() => _guardando = true);
    
    final url = Uri.parse('http://127.0.0.1:8000/tickets/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
        body: jsonEncode({
          "equipo_id": widget.equipoId,
          "nombre_entrega": _nombreEntregaController.text,
          "nombre_recibe": "Usuario en turno", // El backend pone el real
          "telefono": _telefonoController.text,
          "departamento": _departamentoController.text,
          "diagnostico_inicial": _diagnosticoController.text,
          "accesorios": _accesoriosController.text,
          "estado_fisico": _estadoFisicoController.text
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Ingreso registrado en la Base de Datos!'), backgroundColor: Colors.green)
          );
        }
        
        // --- AQUÍ ESTÁ LA CORRECCIÓN DE LA FUNCIÓN DEL PDF ---
        await PdfGenerator.generarPdfRecepcion(
          folio: widget.folioEquipo,
          departamento: _departamentoController.text,
          tipoEquipo: widget.tipoEquipo,
          marca: widget.marca,
          modelo: widget.modelo,
          diagnostico: _diagnosticoController.text,
          accesorios: _accesoriosController.text,
          estadoFisico: _estadoFisicoController.text,
          quienEntrega: _nombreEntregaController.text,
          quienRecibe: "RECOLECTOR EN TURNO", 
        );

        if (mounted) Navigator.pop(context); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar los datos'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
    
    
    
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo en el PDF: $e'), // Nos dirá el error exacto
            backgroundColor: Colors.red, 
            duration: const Duration(seconds: 6)
          )
        );
      }

    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepción de Equipo'),
        backgroundColor: Colors.teal,
        // --- AQUÍ ESTÁ LA CORRECCIÓN DE LA FUNCIÓN DEL QR ---
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2, size: 30),
            tooltip: 'Imprimir Etiqueta QR',
            onPressed: () async {
              await PdfGenerator.generarEtiquetaQR(widget.folioEquipo, widget.tipoEquipo);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipo: ${widget.folioEquipo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            const Text('Datos de quien entrega', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _nombreEntregaController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono / Extensión')),
            TextField(controller: _departamentoController, decoration: const InputDecoration(labelText: 'Departamento (Ej. Comandancia)')),
            const SizedBox(height: 20),

            const Text('Condiciones del equipo', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _accesoriosController, decoration: const InputDecoration(labelText: 'Accesorios (Ej. Teclado, Mouse)')),
            TextField(controller: _estadoFisicoController, decoration: const InputDecoration(labelText: 'Estado Físico (Ej. Rayones, golpes)')),
            TextField(controller: _diagnosticoController, maxLines: 3, decoration: const InputDecoration(labelText: 'Diagnóstico Inicial / Falla Reportada')),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _guardando ? null : registrarIngreso,
                child: _guardando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar Ingreso y Generar PDF', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}