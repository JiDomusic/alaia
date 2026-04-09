import 'package:flutter/material.dart';

class AppConfig {
  // Supabase - keys via --dart-define (nunca hardcoded)
  static const String supabaseUrl = 'https://pgeoxdcrugpbuyipobrr.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment('ANON_KEY');
  static const String supabaseSRK = String.fromEnvironment('SRK');

  // Firebase hosting
  static const String firebaseDomain = 'https://alaia-depilacion.web.app';

  // Branding
  static const String nombreCentro = 'Alaía';
  static const String subtitulo = 'Depilación Definitiva';
  static const String whatsappSoporte = '3413363551';
  static const String empresa = 'Programación JJ';

  // Paleta de colores - elegante y premium
  static const Color colorPrimario = Color(0xFF1A1A1A);       // Negro elegante
  static const Color colorSecundario = Color(0xFFE8D5C4);     // Beige/cream
  static const Color colorAcento = Color(0xFFD4AF37);         // Dorado
  static const Color colorFondo = Color(0xFFF5F0EB);          // Fondo crema
  static const Color colorTexto = Color(0xFF2C2C2C);          // Texto oscuro
  static const Color colorTextoClaro = Color(0xFF8A8A8A);     // Texto secundario
  static const Color colorExito = Color(0xFF4CAF50);          // Verde - pagado
  static const Color colorPendiente = Color(0xFFE53935);      // Rojo - pendiente
  static const Color colorEnAtencion = Color(0xFFFF9800);     // Naranja - en atencion
  static const Color colorMercadoPago = Color(0xFF00B4FF);    // Azul MP

  // Descuentos por zonas (default, se cargan desde DB)
  static const Map<int, double> descuentosDefault = {
    2: 15.0,
    3: 20.0,
    4: 25.0,
    5: 30.0, // 5 o mas
  };

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrimario,
        brightness: Brightness.light,
        surface: colorFondo,
      ),
      scaffoldBackgroundColor: colorFondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
