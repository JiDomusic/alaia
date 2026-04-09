import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class ConfigTab extends StatefulWidget {
  const ConfigTab({super.key});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final _svc = SupabaseService.instance;
  Map<String, dynamic> _config = {};
  bool _cargando = true;
  bool _guardando = false;

  late TextEditingController _nombreCtrl;
  late TextEditingController _subtituloCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _mapsCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _bannerCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _subtituloCtrl = TextEditingController();
    _sloganCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _mapsCtrl = TextEditingController();
    _instagramCtrl = TextEditingController();
    _bannerCtrl = TextEditingController();
    _cargarConfig();
  }

  Future<void> _cargarConfig() async {
    setState(() => _cargando = true);
    try {
      _config = await _svc.loadConfiguracion();
      _nombreCtrl.text = _config['nombre_centro'] ?? '';
      _subtituloCtrl.text = _config['subtitulo'] ?? '';
      _sloganCtrl.text = _config['slogan'] ?? '';
      _telefonoCtrl.text = _config['telefono'] ?? '';
      _whatsappCtrl.text = _config['whatsapp'] ?? '';
      _emailCtrl.text = _config['email'] ?? '';
      _direccionCtrl.text = _config['direccion'] ?? '';
      _mapsCtrl.text = _config['direccion_maps_url'] ?? '';
      _instagramCtrl.text = _config['instagram'] ?? '';
      _bannerCtrl.text = _config['banner_imagen_url'] ?? '';
      if (mounted) setState(() => _cargando = false);
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _svc.updateConfiguracion({
        'nombre_centro': _nombreCtrl.text.trim(),
        'subtitulo': _subtituloCtrl.text.trim(),
        'slogan': _sloganCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'direccion_maps_url': _mapsCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim(),
        'banner_imagen_url': _bannerCtrl.text.trim(),
        'onboarding_completed': true,
      });
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada'), backgroundColor: AppConfig.colorExito),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  // Crear usuario admin (operadora o super_admin)
  Future<void> _crearUsuario() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    String rol = 'operadora';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Crear Usuario Admin'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Contraseña')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (ve todo + caja)')),
                    DropdownMenuItem(value: 'operadora', child: Text('Operadora (solo turnos + pacientes)')),
                  ],
                  onChanged: (v) => setDState(() => rol = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty || nombreCtrl.text.isEmpty) return;
                try {
                  await _svc.crearUsuarioAdmin(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    rol: rol,
                  );
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario creado'), backgroundColor: AppConfig.colorExito),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Configuración del Centro', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _campo('Nombre del centro', _nombreCtrl),
                  _campo('Subtítulo', _subtituloCtrl),
                  _campo('Slogan', _sloganCtrl),
                  _campo('Teléfono', _telefonoCtrl),
                  _campo('WhatsApp', _whatsappCtrl),
                  _campo('Email', _emailCtrl),
                  _campo('Dirección', _direccionCtrl),
                  _campo('URL Google Maps', _mapsCtrl),
                  _campo('Instagram (@)', _instagramCtrl),
                  _campo('URL imagen banner', _bannerCtrl),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppConfig.colorAcento,
                      foregroundColor: AppConfig.colorPrimario,
                    ),
                    child: _guardando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Guardar Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Usuarios Admin', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _crearUsuario,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Crear Usuario Admin'),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _campo(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _subtituloCtrl.dispose();
    _sloganCtrl.dispose();
    _telefonoCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _mapsCtrl.dispose();
    _instagramCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }
}
