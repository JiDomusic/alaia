import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  bool _recordar = false;
  bool _mostrarPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('admin_email');
    final recordar = prefs.getBool('admin_recordar') ?? false;
    if (recordar && email != null) {
      _emailController.text = email;
      _recordar = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completá email y contraseña');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await SupabaseService.instance.signIn(email, password);

      final rol = SupabaseService.instance.userRol;
      if (rol == null) {
        await SupabaseService.instance.signOut();
        setState(() {
          _error = 'No tenés permisos de administrador';
          _cargando = false;
        });
        return;
      }

      // Guardar credenciales si quiere recordar
      final prefs = await SharedPreferences.getInstance();
      if (_recordar) {
        await prefs.setString('admin_email', email);
        await prefs.setBool('admin_recordar', true);
      } else {
        await prefs.remove('admin_email');
        await prefs.setBool('admin_recordar', false);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Email o contraseña incorrectos';
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorFondo,
      appBar: AppBar(
        title: Text(
          'Admin',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConfig.colorPrimario,
        foregroundColor: AppConfig.colorSecundario,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Alaía',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.colorPrimario,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Panel de Administración',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppConfig.colorTextoClaro,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _recordar,
                      onChanged: (v) => setState(() => _recordar = v ?? false),
                    ),
                    Text(
                      'Recordar email',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConfig.colorPendiente.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppConfig.colorPendiente, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppConfig.colorPendiente,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _login,
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Iniciar Sesión',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '¿Primera vez? Registrate',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorTextoClaro),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _cargando ? null : _mostrarRegistro,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConfig.colorAcento),
                    ),
                    child: Text(
                      'Crear Cuenta',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.colorAcento,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarRegistro() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final passConfirmCtrl = TextEditingController();
    String rol = 'operadora';
    String? regError;
    bool registrando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('Crear Cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passConfirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Seleccioná tu rol:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDState(() => rol = 'super_admin'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: rol == 'super_admin' ? AppConfig.colorAcento : Colors.grey.shade300,
                                width: rol == 'super_admin' ? 2 : 1,
                              ),
                              color: rol == 'super_admin' ? AppConfig.colorAcento.withValues(alpha: 0.08) : null,
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.admin_panel_settings, color: rol == 'super_admin' ? AppConfig.colorAcento : Colors.grey),
                                const SizedBox(height: 4),
                                Text('Admin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Ve todo + caja', style: GoogleFonts.inter(fontSize: 11, color: AppConfig.colorTextoClaro)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDState(() => rol = 'operadora'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: rol == 'operadora' ? Colors.blue : Colors.grey.shade300,
                                width: rol == 'operadora' ? 2 : 1,
                              ),
                              color: rol == 'operadora' ? Colors.blue.withValues(alpha: 0.08) : null,
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.medical_services, color: rol == 'operadora' ? Colors.blue : Colors.grey),
                                const SizedBox(height: 4),
                                Text('Operadora', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Turnos + pacientes', style: GoogleFonts.inter(fontSize: 11, color: AppConfig.colorTextoClaro)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (regError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.colorPendiente.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(regError!, style: GoogleFonts.inter(fontSize: 12, color: AppConfig.colorPendiente)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: registrando ? null : () async {
                if (nombreCtrl.text.trim().isEmpty) {
                  setDState(() => regError = 'Ingresá tu nombre');
                  return;
                }
                if (emailCtrl.text.trim().isEmpty) {
                  setDState(() => regError = 'Ingresá tu email');
                  return;
                }
                if (passCtrl.text.length < 6) {
                  setDState(() => regError = 'La contraseña debe tener al menos 6 caracteres');
                  return;
                }
                if (passCtrl.text != passConfirmCtrl.text) {
                  setDState(() => regError = 'Las contraseñas no coinciden');
                  return;
                }

                setDState(() { registrando = true; regError = null; });

                try {
                  // 1. Crear en Supabase Auth
                  final authResponse = await SupabaseService.instance.signUp(
                    emailCtrl.text.trim(),
                    passCtrl.text.trim(),
                  );

                  if (authResponse.user == null) {
                    setDState(() { regError = 'Error al crear cuenta'; registrando = false; });
                    return;
                  }

                  // 2. Registrar en tabla usuarios con rol
                  await SupabaseService.instance.registrarUsuario(
                    nombreCtrl.text.trim(),
                    rol,
                  );

                  // 3. Cargar rol
                  await SupabaseService.instance.refreshRol();

                  Navigator.pop(ctx);

                  if (mounted) {
                    // Ir al dashboard
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  }
                } catch (e) {
                  setDState(() {
                    regError = e.toString().contains('already registered')
                        ? 'Este email ya está registrado'
                        : 'Error: $e';
                    registrando = false;
                  });
                }
              },
              child: registrando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrarme'),
            ),
          ],
        ),
      ),
    );
  }
}
