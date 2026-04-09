import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'admin/admin_login_screen.dart';
import 'booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? config;
  const HomeScreen({super.key, this.config});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _zonas = [];
  late Map<String, dynamic> _config;
  List<Map<String, dynamic>> _descuentos = [];
  bool _cargando = true;

  // Colores dinámicos del centro
  Color get _colorPrimario => AppConfig.hexToColor(_config['color_primario'] ?? '#1A1A1A');
  Color get _colorSecundario => AppConfig.hexToColor(_config['color_secundario'] ?? '#E8D5C4');
  Color get _colorAcento => AppConfig.hexToColor(_config['color_acento'] ?? '#D4AF37');
  Color get _colorFondo => AppConfig.hexToColor(_config['color_fondo'] ?? '#F5F0EB');
  Color get _colorTexto => AppConfig.hexToColor(_config['color_texto'] ?? '#2C2C2C');

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? {};
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final zonas = await SupabaseService.instance.loadZonas();
      if (_config.isEmpty) {
        _config = await SupabaseService.instance.loadConfiguracion();
      }
      final descuentos = await SupabaseService.instance.loadDescuentos();
      if (mounted) {
        setState(() {
          _zonas = zonas;
          _descuentos = descuentos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irAlAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  void _irAReservar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingScreen(config: _config)),
    );
  }

  Future<void> _abrirWhatsApp() async {
    final whatsapp = _config['whatsapp'] ?? AppConfig.whatsappSoporte;
    final url = Uri.parse('https://wa.me/54$whatsapp');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 600;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === HERO SECTION ===
            _buildHero(esMovil),
            // === ZONAS / SERVICIOS ===
            if (_zonas.isNotEmpty) _buildZonasSection(esMovil),
            // === DESCUENTOS ===
            if (_descuentos.isNotEmpty) _buildDescuentosSection(esMovil),
            // === FOOTER ===
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool esMovil) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 24 : 80,
        vertical: esMovil ? 60 : 100,
      ),
      decoration: BoxDecoration(
        color: _colorPrimario,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nav bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alaía',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _colorSecundario,
                ),
              ),
              TextButton.icon(
                onPressed: _irAlAdmin,
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Admin'),
                style: TextButton.styleFrom(
                  foregroundColor: _colorSecundario.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: esMovil ? 40 : 80),
          // Logo / imagen si existe
          if (_config['logo_url'] != null && (_config['logo_url'] as String).isNotEmpty)
            Container(
              width: 120,
              height: 120,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(_config['logo_url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Text(
            _config['nombre_centro'] ?? 'Alaía',
            style: GoogleFonts.playfairDisplay(
              fontSize: esMovil ? 36 : 56,
              fontWeight: FontWeight.bold,
              color: _colorSecundario,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'DEPILACIÓN DEFINITIVA',
            style: GoogleFonts.inter(
              fontSize: esMovil ? 12 : 16,
              fontWeight: FontWeight.w300,
              color: _colorSecundario.withValues(alpha: 0.6),
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 24),
          if (_config['slogan'] != null && (_config['slogan'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                _config['slogan'],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: _colorSecundario.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // CTA - Reservar
          ElevatedButton(
            onPressed: _irAReservar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAcento,
              foregroundColor: _colorPrimario,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Reservar Turno'),
          ),
          const SizedBox(height: 16),
          // WhatsApp
          TextButton.icon(
            onPressed: _abrirWhatsApp,
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Consultanos por WhatsApp'),
            style: TextButton.styleFrom(
              foregroundColor: _colorSecundario.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonasSection(bool esMovil) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 24 : 80,
        vertical: 60,
      ),
      color: _colorFondo,
      child: Column(
        children: [
          Text(
            'Zonas de Tratamiento',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _colorTexto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Depilación láser de última generación',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _colorTexto.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _zonas.map((zona) => _buildZonaCard(zona, esMovil)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildZonaCard(Map<String, dynamic> zona, bool esMovil) {
    return Container(
      width: esMovil ? double.infinity : 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on,
            color: _colorAcento,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            zona['nombre'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _colorTexto,
            ),
            textAlign: TextAlign.center,
          ),
          if (zona['duracion_minutos'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${zona['duracion_minutos']} min',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _colorTexto.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescuentosSection(bool esMovil) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 24 : 80,
        vertical: 60,
      ),
      color: _colorPrimario,
      child: Column(
        children: [
          Text(
            'Combina zonas y ahorrá',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _colorSecundario,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _descuentos.map((d) {
              final cantZonas = d['cantidad_zonas'] as int;
              final descuento = d['porcentaje_descuento'];
              final label = cantZonas >= 5 ? '5 O MÁS ZONAS' : '$cantZonas ZONAS';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _colorAcento.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _colorSecundario,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${descuento.toStringAsFixed(0)}% OFF',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _colorAcento,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: _colorPrimario,
      child: Column(
        children: [
          Divider(color: _colorSecundario.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Developed by ${AppConfig.empresa}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _colorSecundario.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
