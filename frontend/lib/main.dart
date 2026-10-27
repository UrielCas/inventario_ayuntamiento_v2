// Autor: URIEL GUTIÉRREZ CASTILLO
import 'package:flutter/material.dart';
import 'pantalla_login.dart';

// === EL INTERRUPTOR MAESTRO ===
// Arranca en 'light' (Modo Día) por defecto, tal como pediste
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() => runApp(const HelpdeskApp());

class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder "escucha" nuestro interruptor y redibuja la app al cambiar
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Helpdesk Ayuntamiento',
          debugShowCheckedModeBanner: false,
          
          // === TEMA CLARO ===
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF475569),
              primary: const Color(0xFF475569),
              secondary: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
          ),

          // === TEMA OSCURO ===
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF475569),
              primary: const Color(0xFF94A3B8), 
              secondary: const Color(0xFF3B82F6),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A), 
            cardColor: const Color(0xFF1E293B), 
          ),
          
          // Ahora obedece a nuestro botón, no a Windows
          themeMode: currentMode, 
          
          home: const PantallaLogin(), 
        );
      }
    );
  }
}