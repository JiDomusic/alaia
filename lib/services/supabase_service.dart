import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  String? _userRol;
  String? get userRol => _userRol;
  bool get isSuperAdmin => _userRol == 'super_admin';
  bool get isOperadora => _userRol == 'operadora';

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // ============================================
  // AUTH
  // ============================================

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await _loadUserRol();
    }
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    _userRol = null;
  }

  Future<void> _loadUserRol() async {
    if (currentUser == null) return;
    final data = await client
        .from('usuarios')
        .select('rol')
        .eq('auth_user_id', currentUser!.id)
        .eq('activo', true)
        .maybeSingle();
    _userRol = data?['rol'];
  }

  Future<void> refreshRol() async => _loadUserRol();

  // ============================================
  // CONFIGURACION
  // ============================================

  Future<Map<String, dynamic>> loadConfiguracion() async {
    final data = await client.from('configuracion').select().eq('id', 1).single();
    return data;
  }

  Future<void> updateConfiguracion(Map<String, dynamic> updates) async {
    await client.from('configuracion').update(updates).eq('id', 1);
  }

  // ============================================
  // ZONAS
  // ============================================

  Future<List<Map<String, dynamic>>> loadZonas({bool soloActivas = true}) async {
    var query = client.from('zonas').select();
    if (soloActivas) query = query.eq('activa', true);
    return await query.order('orden');
  }

  Future<void> createZona(Map<String, dynamic> zona) async {
    await client.from('zonas').insert(zona);
  }

  Future<void> updateZona(String id, Map<String, dynamic> updates) async {
    await client.from('zonas').update(updates).eq('id', id);
  }

  Future<void> deleteZona(String id) async {
    await client.from('zonas').delete().eq('id', id);
  }

  // ============================================
  // PACIENTES
  // ============================================

  Future<List<Map<String, dynamic>>> loadPacientes() async {
    return await client.from('pacientes').select().eq('activo', true).order('nombre');
  }

  Future<Map<String, dynamic>> createPaciente(Map<String, dynamic> paciente) async {
    final data = await client.from('pacientes').insert(paciente).select().single();
    return data;
  }

  Future<void> updatePaciente(String id, Map<String, dynamic> updates) async {
    await client.from('pacientes').update(updates).eq('id', id);
  }

  Future<void> deletePaciente(String id) async {
    await client.from('pacientes').update({'activo': false}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> buscarPaciente(String query) async {
    return await client
        .from('pacientes')
        .select()
        .eq('activo', true)
        .ilike('nombre', '%$query%')
        .order('nombre')
        .limit(20);
  }

  // ============================================
  // OBSERVACIONES
  // ============================================

  Future<List<Map<String, dynamic>>> loadObservaciones(String pacienteId) async {
    return await client
        .from('paciente_observaciones')
        .select('*, usuarios(nombre)')
        .eq('paciente_id', pacienteId)
        .order('created_at', ascending: false);
  }

  Future<void> createObservacion(Map<String, dynamic> obs) async {
    await client.from('paciente_observaciones').insert(obs);
  }

  // ============================================
  // TURNOS
  // ============================================

  Future<List<Map<String, dynamic>>> loadTurnosPorFecha(DateTime fecha) async {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    return await client
        .from('turnos')
        .select('*, pacientes(nombre, telefono)')
        .eq('fecha', fechaStr)
        .order('hora');
  }

  Future<List<Map<String, dynamic>>> loadTurnosPaciente(String pacienteId) async {
    return await client
        .from('turnos')
        .select()
        .eq('paciente_id', pacienteId)
        .order('fecha', ascending: false)
        .order('hora', ascending: false);
  }

  Future<Map<String, dynamic>> createTurno(Map<String, dynamic> turno) async {
    final data = await client.from('turnos').insert(turno).select().single();
    return data;
  }

  Future<void> updateTurno(String id, Map<String, dynamic> updates) async {
    await client.from('turnos').update(updates).eq('id', id);
  }

  Future<void> deleteTurno(String id) async {
    await client.from('turnos').delete().eq('id', id);
  }

  // ============================================
  // HORARIOS OPERATIVOS
  // ============================================

  Future<List<Map<String, dynamic>>> loadHorarios() async {
    return await client.from('horarios_operativos').select().order('dia_semana');
  }

  Future<void> updateHorario(String id, Map<String, dynamic> updates) async {
    await client.from('horarios_operativos').update(updates).eq('id', id);
  }

  // ============================================
  // BLOQUEOS
  // ============================================

  Future<List<Map<String, dynamic>>> loadBloqueos({DateTime? desde, DateTime? hasta}) async {
    var query = client.from('bloqueos').select();
    if (desde != null) {
      final desdeStr = '${desde.year}-${desde.month.toString().padLeft(2, '0')}-${desde.day.toString().padLeft(2, '0')}';
      query = query.gte('fecha', desdeStr);
    }
    if (hasta != null) {
      final hastaStr = '${hasta.year}-${hasta.month.toString().padLeft(2, '0')}-${hasta.day.toString().padLeft(2, '0')}';
      query = query.lte('fecha', hastaStr);
    }
    return await query.order('fecha').order('hora_inicio');
  }

  Future<void> createBloqueo(Map<String, dynamic> bloqueo) async {
    await client.from('bloqueos').insert(bloqueo);
  }

  Future<void> deleteBloqueo(String id) async {
    await client.from('bloqueos').delete().eq('id', id);
  }

  // ============================================
  // CAJA
  // ============================================

  Future<Map<String, dynamic>?> loadCajaDiaria(DateTime fecha) async {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    return await client
        .from('caja_diaria')
        .select()
        .eq('fecha', fechaStr)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> getOrCreateCajaDiaria(DateTime fecha) async {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    var caja = await loadCajaDiaria(fecha);
    if (caja == null) {
      caja = await client
          .from('caja_diaria')
          .insert({'fecha': fechaStr})
          .select()
          .single();
    }
    return caja;
  }

  Future<void> updateCajaDiaria(String id, Map<String, dynamic> updates) async {
    await client.from('caja_diaria').update(updates).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> loadCajaMovimientos(String cajaId) async {
    return await client
        .from('caja_movimientos')
        .select()
        .eq('caja_id', cajaId)
        .order('created_at');
  }

  Future<void> createCajaMovimiento(Map<String, dynamic> mov) async {
    await client.from('caja_movimientos').insert(mov);
  }

  Future<void> deleteCajaMovimiento(String id) async {
    await client.from('caja_movimientos').delete().eq('id', id);
  }

  // ============================================
  // DESCUENTOS
  // ============================================

  Future<List<Map<String, dynamic>>> loadDescuentos() async {
    return await client
        .from('descuentos_zonas')
        .select()
        .eq('activo', true)
        .order('cantidad_zonas');
  }

  // ============================================
  // RPC (funciones servidor)
  // ============================================

  Future<Map<String, dynamic>> resumenCaja(DateTime fecha) async {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final data = await client.rpc('resumen_caja', params: {'p_fecha': fechaStr});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> crearUsuarioAdmin({
    required String email,
    required String password,
    required String nombre,
    String rol = 'operadora',
  }) async {
    final data = await client.rpc('crear_usuario_admin', params: {
      'p_email': email,
      'p_password': password,
      'p_nombre': nombre,
      'p_rol': rol,
    });
    return Map<String, dynamic>.from(data);
  }
}
