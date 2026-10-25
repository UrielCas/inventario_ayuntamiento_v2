// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';

// Importamos nuestra nueva pantalla de login (la puerta de entrada)
import 'pantalla_login.dart';

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
        // Aplicamos la base de nuestra nueva estética Azul Pizarra globalmente
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF475569), 
          primary: const Color(0xFF475569),
          secondary: const Color(0xFF3B82F6), 
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
      ),
      // La aplicación arranca directamente en nuestro nuevo archivo
      home: const PantallaLogin(), 
    );
  }
}