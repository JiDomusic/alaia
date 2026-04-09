import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  String _estado = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      setState(() => _estado = 'Conectando...');
      // Verificar conexion cargando configuracion
      await SupabaseService.instance.loadConfiguracion();
      setState(() => _estado = 'Listo');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _estado = 'Error de conexión');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorPrimario,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alaía',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.colorSecundario,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'DEPILACIÓN DEFINITIVA',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: AppConfig.colorSecundario.withValues(alpha: 0.7),
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConfig.colorAcento,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _estado,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConfig.colorSecundario.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
