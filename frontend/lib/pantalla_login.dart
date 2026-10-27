// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Importamos los dashboards a los que el login va a redirigir
import 'dashboard_admin.dart';
import 'dashboard_tecnico.dart';
import 'dashboard_recolector.dart';

// ==========================================
// PALETA DE COLORES (ESTÉTICA AZUL PIZARRA)
// ==========================================
const Color colorPrincipal = Color(0xFF475569); // Slate Blue Clásico
const Color colorFondo = Color(0xFFF8FAFC); // Gris Perla suave
const Color colorAcento = Color(0xFF3B82F6); // Azul brillante para botones

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({Key? key}) : super(key: key);

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;
  bool _ocultarPassword = true;

  Future<void> iniciarSesion() async {
    if (_correoController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena todos los campos'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _cargando = true);

    try {
    
    
    
      final url = Uri.parse('https://2bbbf2bad08053.lhr.life/token');
      // FastAPI OAuth2 espera datos de formulario (x-www-form-urlencoded), NO un JSON
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _correoController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String token = data['access_token'];
        final String rol = data['rol'];
        final String nombre = data['nombre'];

        if (mounted) {
          // El "Semáforo" que dirige a cada empleado a su área
          if (rol == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardAdmin(token: token, nombre: nombre)));
          } else if (rol == 'tecnico') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardTecnico(token: token, nombre: nombre)));
          } else if (rol == 'recolector') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardRecolector(token: token, nombre: nombre)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol no reconocido en el sistema'), backgroundColor: Colors.red));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo o contraseña incorrectos'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión con el servidor'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Ancho fijo para que se vea como una tarjeta elegante en PC
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO O ÍCONO INSTITUCIONAL
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: colorPrincipal,
                  child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gobierno Digital e Innovación',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorPrincipal),
                ),
                const SizedBox(height: 5),
                Text('Sistema de Helpdesk y Taller', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 30),
                
                // CAMPOS DE TEXTO
                TextField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email, color: colorPrincipal),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorAcento, width: 2)),
                  ),
                  onSubmitted: (_) => iniciarSesion(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: colorPrincipal),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: colorAcento, width: 2)),
                  ),
                  onSubmitted: (_) => iniciarSesion(),
                ),
                const SizedBox(height: 30),
                
                // BOTÓN DE ACCESO
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAcento,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: _cargando ? null : iniciarSesion,
                    child: _cargando 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


















