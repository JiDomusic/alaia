-- ============================================
-- ALAIA - Row Level Security
-- Solo admins autenticados pueden modificar
-- Usuarios anonimos solo pueden leer config publica y crear turnos
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE configuracion ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE zonas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE paciente_observaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE turnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE horarios_operativos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bloqueos ENABLE ROW LEVEL SECURITY;
ALTER TABLE caja_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE caja_movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE descuentos_zonas ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CONFIGURACION - todos leen, solo admin modifica
-- ============================================
CREATE POLICY "configuracion_select_all" ON configuracion
  FOR SELECT USING (true);

CREATE POLICY "configuracion_update_admin" ON configuracion
  FOR UPDATE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- USUARIOS - solo admins autenticados
-- ============================================
CREATE POLICY "usuarios_select_auth" ON usuarios
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "usuarios_insert_super" ON usuarios
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

CREATE POLICY "usuarios_update_super" ON usuarios
  FOR UPDATE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

CREATE POLICY "usuarios_delete_super" ON usuarios
  FOR DELETE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- ZONAS - todos leen (para reservar), admin modifica
-- ============================================
CREATE POLICY "zonas_select_all" ON zonas
  FOR SELECT USING (true);

CREATE POLICY "zonas_modify_admin" ON zonas
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- PACIENTES - solo admin lee/modifica
-- ============================================
CREATE POLICY "pacientes_select_admin" ON pacientes
  FOR SELECT USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "pacientes_insert_admin" ON pacientes
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "pacientes_update_admin" ON pacientes
  FOR UPDATE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "pacientes_delete_super" ON pacientes
  FOR DELETE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- OBSERVACIONES - ambos roles leen/escriben
-- ============================================
CREATE POLICY "observaciones_select_admin" ON paciente_observaciones
  FOR SELECT USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "observaciones_insert_admin" ON paciente_observaciones
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "observaciones_update_admin" ON paciente_observaciones
  FOR UPDATE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

-- ============================================
-- TURNOS - anon puede crear (reservar), admin todo
-- ============================================
CREATE POLICY "turnos_select_all" ON turnos
  FOR SELECT USING (true);

CREATE POLICY "turnos_insert_anon" ON turnos
  FOR INSERT WITH CHECK (true);

CREATE POLICY "turnos_update_admin" ON turnos
  FOR UPDATE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
  );

CREATE POLICY "turnos_delete_admin" ON turnos
  FOR DELETE USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- HORARIOS - todos leen (para reservar), admin modifica
-- ============================================
CREATE POLICY "horarios_select_all" ON horarios_operativos
  FOR SELECT USING (true);

CREATE POLICY "horarios_modify_admin" ON horarios_operativos
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- BLOQUEOS - todos leen, admin modifica
-- ============================================
CREATE POLICY "bloqueos_select_all" ON bloqueos
  FOR SELECT USING (true);

CREATE POLICY "bloqueos_modify_admin" ON bloqueos
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- CAJA - SOLO super_admin (la operadora no ve plata)
-- ============================================
CREATE POLICY "caja_diaria_select_super" ON caja_diaria
  FOR SELECT USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

CREATE POLICY "caja_diaria_modify_super" ON caja_diaria
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

CREATE POLICY "caja_movimientos_select_super" ON caja_movimientos
  FOR SELECT USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

CREATE POLICY "caja_movimientos_modify_super" ON caja_movimientos
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );

-- ============================================
-- DESCUENTOS - todos leen, admin modifica
-- ============================================
CREATE POLICY "descuentos_select_all" ON descuentos_zonas
  FOR SELECT USING (true);

CREATE POLICY "descuentos_modify_super" ON descuentos_zonas
  FOR ALL USING (
    auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
  );
