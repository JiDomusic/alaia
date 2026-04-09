import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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
  String _seccionActiva = 'datos';

  // Controladores por sección
  // Datos
  late TextEditingController _nombreCtrl;
  late TextEditingController _subtituloCtrl;
  late TextEditingController _sloganCtrl;
  // Contacto
  late TextEditingController _telefonoCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _mapsCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _tiktokCtrl;
  // Diseño
  late TextEditingController _logoCtrl;
  late TextEditingController _bannerImgCtrl;
  late TextEditingController _bannerVideoCtrl;
  late TextEditingController _colorPrimarioCtrl;
  late TextEditingController _colorSecundarioCtrl;
  late TextEditingController _colorAcentoCtrl;
  late TextEditingController _colorFondoCtrl;
  late TextEditingController _colorTextoCtrl;
  // Textos
  late TextEditingController _textoHeroCtrl;
  late TextEditingController _textoCtaCtrl;
  late TextEditingController _mensajeBienvenidaCtrl;

  String _bannerTipo = 'imagen';
  bool _mostrarZonas = true;
  bool _mostrarDescuentos = true;
  bool _mostrarPrecios = false;

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
    _facebookCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    _logoCtrl = TextEditingController();
    _bannerImgCtrl = TextEditingController();
    _bannerVideoCtrl = TextEditingController();
    _colorPrimarioCtrl = TextEditingController();
    _colorSecundarioCtrl = TextEditingController();
    _colorAcentoCtrl = TextEditingController();
    _colorFondoCtrl = TextEditingController();
    _colorTextoCtrl = TextEditingController();
    _textoHeroCtrl = TextEditingController();
    _textoCtaCtrl = TextEditingController();
    _mensajeBienvenidaCtrl = TextEditingController();
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
      _facebookCtrl.text = _config['facebook'] ?? '';
      _tiktokCtrl.text = _config['tiktok'] ?? '';
      _logoCtrl.text = _config['logo_url'] ?? '';
      _bannerImgCtrl.text = _config['banner_imagen_url'] ?? '';
      _bannerVideoCtrl.text = _config['banner_video_url'] ?? '';
      _colorPrimarioCtrl.text = _config['color_primario'] ?? '#1A1A1A';
      _colorSecundarioCtrl.text = _config['color_secundario'] ?? '#E8D5C4';
      _colorAcentoCtrl.text = _config['color_acento'] ?? '#D4AF37';
      _colorFondoCtrl.text = _config['color_fondo'] ?? '#F5F0EB';
      _colorTextoCtrl.text = _config['color_texto'] ?? '#2C2C2C';
      _textoHeroCtrl.text = _config['texto_hero'] ?? '';
      _textoCtaCtrl.text = _config['texto_cta'] ?? 'Reservar Turno';
      _mensajeBienvenidaCtrl.text = _config['mensaje_bienvenida'] ?? '';
      _bannerTipo = _config['banner_tipo'] ?? 'imagen';
      _mostrarZonas = _config['mostrar_zonas_publico'] ?? true;
      _mostrarDescuentos = _config['mostrar_descuentos_publico'] ?? true;
      _mostrarPrecios = _config['mostrar_precios_publico'] ?? false;
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
        'facebook': _facebookCtrl.text.trim(),
        'tiktok': _tiktokCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim(),
        'banner_imagen_url': _bannerImgCtrl.text.trim(),
        'banner_video_url': _bannerVideoCtrl.text.trim(),
        'banner_tipo': _bannerTipo,
        'color_primario': _colorPrimarioCtrl.text.trim(),
        'color_secundario': _colorSecundarioCtrl.text.trim(),
        'color_acento': _colorAcentoCtrl.text.trim(),
        'color_fondo': _colorFondoCtrl.text.trim(),
        'color_texto': _colorTextoCtrl.text.trim(),
        'texto_hero': _textoHeroCtrl.text.trim(),
        'texto_cta': _textoCtaCtrl.text.trim(),
        'mensaje_bienvenida': _mensajeBienvenidaCtrl.text.trim(),
        'mostrar_zonas_publico': _mostrarZonas,
        'mostrar_descuentos_publico': _mostrarDescuentos,
        'mostrar_precios_publico': _mostrarPrecios,
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
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Navegación de secciones
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chipSeccion('datos', 'Datos', Icons.store),
                _chipSeccion('contacto', 'Contacto', Icons.phone),
                _chipSeccion('diseno', 'Diseño', Icons.palette),
                _chipSeccion('banner', 'Banner', Icons.image),
                _chipSeccion('textos', 'Textos', Icons.text_fields),
                _chipSeccion('publico', 'Vista Pública', Icons.visibility),
                _chipSeccion('usuarios', 'Usuarios', Icons.people),
              ],
            ),
          ),
        ),
        // Contenido
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_seccionActiva == 'datos') _buildDatos(),
                  if (_seccionActiva == 'contacto') _buildContacto(),
                  if (_seccionActiva == 'diseno') _buildDiseno(),
                  if (_seccionActiva == 'banner') _buildBanner(),
                  if (_seccionActiva == 'textos') _buildTextos(),
                  if (_seccionActiva == 'publico') _buildVistaPublica(),
                  if (_seccionActiva == 'usuarios') _buildUsuarios(),
                  if (_seccionActiva != 'usuarios') ...[
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppConfig.colorAcento,
                        foregroundColor: AppConfig.colorPrimario,
                      ),
                      child: _guardando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Guardar Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipSeccion(String id, String label, IconData icon) {
    final activa = _seccionActiva == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: activa,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: activa ? AppConfig.colorPrimario : AppConfig.colorTextoClaro),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selectedColor: AppConfig.colorAcento.withValues(alpha: 0.2),
        onSelected: (_) => setState(() => _seccionActiva = id),
      ),
    );
  }

  // === DATOS ===
  Widget _buildDatos() {
    return _seccionCard('Datos del Centro', Icons.store, [
      _campo('Nombre del centro', _nombreCtrl),
      _campo('Subtítulo', _subtituloCtrl),
      _campo('Slogan', _sloganCtrl),
    ]);
  }

  // === CONTACTO ===
  Widget _buildContacto() {
    return _seccionCard('Contacto', Icons.phone, [
      _campo('Teléfono', _telefonoCtrl),
      _campo('WhatsApp', _whatsappCtrl),
      _campo('Email', _emailCtrl),
      _campo('Dirección', _direccionCtrl),
      _campo('URL Google Maps', _mapsCtrl),
      _campo('Instagram (@)', _instagramCtrl),
      _campo('Facebook', _facebookCtrl),
      _campo('TikTok (@)', _tiktokCtrl),
    ]);
  }

  // === UPLOAD HELPER ===
  Future<void> _subirArchivo(String tipo, TextEditingController ctrl, {List<String>? extensiones}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: extensiones != null ? FileType.custom : FileType.image,
        allowedExtensions: extensiones,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final ext = file.extension ?? 'jpg';
      final path = '$tipo/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final mime = ext == 'mp4' ? 'video/mp4'
          : ext == 'webm' ? 'video/webm'
          : ext == 'png' ? 'image/png'
          : ext == 'webp' ? 'image/webp'
          : 'image/jpeg';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo archivo...')),
        );
      }

      final url = await SupabaseService.instance.uploadFile(path, Uint8List.fromList(bytes), mime);

      if (mounted) {
        setState(() => ctrl.text = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo subido'), backgroundColor: AppConfig.colorExito),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Widget _uploadField(String label, TextEditingController ctrl, String tipo, {List<String>? extensiones, bool esVideo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: 'URL o subir archivo',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _subirArchivo(tipo, ctrl, extensiones: extensiones),
                icon: Icon(esVideo ? Icons.video_library : Icons.upload, size: 18),
                label: const Text('Subir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorAcento,
                  foregroundColor: AppConfig.colorPrimario,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ],
          ),
          if (!esVideo && ctrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ctrl.text,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // === DISEÑO (COLORES) ===
  Widget _buildDiseno() {
    return _seccionCard('Diseño y Colores', Icons.palette, [
      _uploadField('Logo (imagen redonda)', _logoCtrl, 'logo'),
      if (_logoCtrl.text.isNotEmpty) ...[
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              image: DecorationImage(
                image: NetworkImage(_logoCtrl.text),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      _colorField('Color Primario (fondo hero)', _colorPrimarioCtrl),
      _colorField('Color Secundario (textos hero)', _colorSecundarioCtrl),
      _colorField('Color Acento (botones, dorado)', _colorAcentoCtrl),
      _colorField('Color Fondo (cuerpo)', _colorFondoCtrl),
      _colorField('Color Texto', _colorTextoCtrl),
      const SizedBox(height: 16),
      Text('Paletas sugeridas:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _paletaPreset('Elegante Oscura', '#1A1A1A', '#E8D5C4', '#D4AF37', '#F5F0EB', '#2C2C2C'),
          _paletaPreset('Rosa Premium', '#1A1720', '#E8A0BF', '#D4AF37', '#FFF5F8', '#2C2C2C'),
          _paletaPreset('Blanco Limpio', '#FFFFFF', '#1A1A1A', '#C9A96E', '#F5F5F5', '#333333'),
          _paletaPreset('Azul Clínico', '#0D1B2A', '#E0E1DD', '#00B4D8', '#F8F9FA', '#1B263B'),
        ],
      ),
    ]);
  }

  // === BANNER ===
  Widget _buildBanner() {
    return _seccionCard('Banner Hero', Icons.image, [
      Row(
        children: [
          Text('Tipo de banner:', style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Imagen'),
            selected: _bannerTipo == 'imagen',
            onSelected: (_) => setState(() => _bannerTipo = 'imagen'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Video'),
            selected: _bannerTipo == 'video',
            onSelected: (_) => setState(() => _bannerTipo = 'video'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_bannerTipo == 'imagen') ...[
        _uploadField('Imagen Banner', _bannerImgCtrl, 'banner'),
        if (_bannerImgCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _bannerImgCtrl.text,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey.shade200,
                child: const Center(child: Text('Error al cargar imagen')),
              ),
            ),
          ),
        ],
      ] else ...[
        _uploadField('Video Banner (.mp4)', _bannerVideoCtrl, 'banner', extensiones: ['mp4', 'webm'], esVideo: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El video se reproduce automáticamente sin sonido en loop. Usá un link directo al archivo .mp4',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  // === TEXTOS ===
  Widget _buildTextos() {
    return _seccionCard('Textos Personalizables', Icons.text_fields, [
      _campo('Texto hero (debajo del nombre)', _textoHeroCtrl),
      _campo('Texto botón principal', _textoCtaCtrl),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _mensajeBienvenidaCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Mensaje de bienvenida',
            alignLabelWithHint: true,
          ),
        ),
      ),
    ]);
  }

  // === VISTA PUBLICA ===
  Widget _buildVistaPublica() {
    return _seccionCard('Vista Pública', Icons.visibility, [
      SwitchListTile(
        title: const Text('Mostrar zonas de tratamiento'),
        subtitle: const Text('Las zonas se ven en la web pública'),
        value: _mostrarZonas,
        onChanged: (v) => setState(() => _mostrarZonas = v),
      ),
      SwitchListTile(
        title: const Text('Mostrar descuentos por zonas'),
        subtitle: const Text('La sección de "2 zonas 15% OFF, etc."'),
        value: _mostrarDescuentos,
        onChanged: (v) => setState(() => _mostrarDescuentos = v),
      ),
      SwitchListTile(
        title: const Text('Mostrar precios en público'),
        subtitle: const Text('Si se muestran los precios de cada zona'),
        value: _mostrarPrecios,
        onChanged: (v) => setState(() => _mostrarPrecios = v),
      ),
    ]);
  }

  // === USUARIOS ===
  Widget _buildUsuarios() {
    return _seccionCard('Usuarios Admin', Icons.people, [
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: _crearUsuario,
        icon: const Icon(Icons.person_add),
        label: const Text('Crear Usuario Admin'),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roles:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            _rolInfo(Icons.admin_panel_settings, 'Super Admin', 'Ve todo: turnos, pacientes, caja, zonas, promos, horarios, bloqueos, configuración', AppConfig.colorAcento),
            const SizedBox(height: 8),
            _rolInfo(Icons.medical_services, 'Operadora', 'Solo ve: turnos (check-in, completar) y pacientes (observaciones). NO ve precios ni caja.', Colors.blue),
          ],
        ),
      ),
    ]);
  }

  Widget _rolInfo(IconData icon, String titulo, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppConfig.colorTextoClaro)),
            ],
          ),
        ),
      ],
    );
  }

  // === HELPERS ===
  Widget _seccionCard(String titulo, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConfig.colorAcento, size: 24),
                const SizedBox(width: 8),
                Text(titulo, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            ...children,
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

  Widget _colorField(String label, TextEditingController ctrl) {
    Color? previewColor;
    try {
      previewColor = AppConfig.hexToColor(ctrl.text);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: previewColor ?? Colors.grey,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: label,
                hintText: '#1A1A1A',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletaPreset(String nombre, String prim, String sec, String acc, String fondo, String texto) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _colorPrimarioCtrl.text = prim;
          _colorSecundarioCtrl.text = sec;
          _colorAcentoCtrl.text = acc;
          _colorFondoCtrl.text = fondo;
          _colorTextoCtrl.text = texto;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniColor(prim),
            _miniColor(sec),
            _miniColor(acc),
            const SizedBox(width: 6),
            Text(nombre, style: GoogleFonts.inter(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _miniColor(String hex) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: AppConfig.hexToColor(hex),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
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
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    _logoCtrl.dispose();
    _bannerImgCtrl.dispose();
    _bannerVideoCtrl.dispose();
    _colorPrimarioCtrl.dispose();
    _colorSecundarioCtrl.dispose();
    _colorAcentoCtrl.dispose();
    _colorFondoCtrl.dispose();
    _colorTextoCtrl.dispose();
    _textoHeroCtrl.dispose();
    _textoCtaCtrl.dispose();
    _mensajeBienvenidaCtrl.dispose();
    super.dispose();
  }
}
