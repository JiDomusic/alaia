-- ============================================
-- ALAIA - RESET COMPLETO Y RECREAR TODO
-- Este script borra todas las tablas, funciones, triggers y policies
-- y las recrea desde cero (equivalente a 001-007)
-- ============================================
-- EJECUTAR EN SUPABASE SQL EDITOR DE UNA SOLA VEZ

-- ============================================
-- PASO 1: BORRAR TODO LO EXISTENTE
-- ============================================

-- Desactivar RLS temporalmente para poder borrar
ALTER TABLE IF EXISTS caja_movimientos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS caja_diaria DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS paciente_zona_sesiones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS paciente_observaciones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS turnos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS bloqueos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS promos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS consultorios DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS descuentos_zonas DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS horarios_operativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS zonas DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pacientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS configuracion DISABLE ROW LEVEL SECURITY;

-- Borrar policies (ignorar errores si no existen)
DO $$ BEGIN
  -- configuracion
  DROP POLICY IF EXISTS "configuracion_select_all" ON configuracion;
  DROP POLICY IF EXISTS "configuracion_update_admin" ON configuracion;
  -- usuarios
  DROP POLICY IF EXISTS "usuarios_select_auth" ON usuarios;
  DROP POLICY IF EXISTS "usuarios_insert_super" ON usuarios;
  DROP POLICY IF EXISTS "usuarios_update_super" ON usuarios;
  DROP POLICY IF EXISTS "usuarios_delete_super" ON usuarios;
  -- zonas
  DROP POLICY IF EXISTS "zonas_select_all" ON zonas;
  DROP POLICY IF EXISTS "zonas_modify_admin" ON zonas;
  -- pacientes
  DROP POLICY IF EXISTS "pacientes_select_admin" ON pacientes;
  DROP POLICY IF EXISTS "pacientes_insert_admin" ON pacientes;
  DROP POLICY IF EXISTS "pacientes_update_admin" ON pacientes;
  DROP POLICY IF EXISTS "pacientes_delete_super" ON pacientes;
  -- observaciones
  DROP POLICY IF EXISTS "observaciones_select_admin" ON paciente_observaciones;
  DROP POLICY IF EXISTS "observaciones_insert_admin" ON paciente_observaciones;
  DROP POLICY IF EXISTS "observaciones_update_admin" ON paciente_observaciones;
  -- turnos
  DROP POLICY IF EXISTS "turnos_select_all" ON turnos;
  DROP POLICY IF EXISTS "turnos_insert_anon" ON turnos;
  DROP POLICY IF EXISTS "turnos_update_admin" ON turnos;
  DROP POLICY IF EXISTS "turnos_delete_admin" ON turnos;
  -- horarios
  DROP POLICY IF EXISTS "horarios_select_all" ON horarios_operativos;
  DROP POLICY IF EXISTS "horarios_modify_admin" ON horarios_operativos;
  -- bloqueos
  DROP POLICY IF EXISTS "bloqueos_select_all" ON bloqueos;
  DROP POLICY IF EXISTS "bloqueos_modify_admin" ON bloqueos;
  -- caja
  DROP POLICY IF EXISTS "caja_diaria_select_super" ON caja_diaria;
  DROP POLICY IF EXISTS "caja_diaria_modify_super" ON caja_diaria;
  DROP POLICY IF EXISTS "caja_movimientos_select_super" ON caja_movimientos;
  DROP POLICY IF EXISTS "caja_movimientos_modify_super" ON caja_movimientos;
  -- descuentos
  DROP POLICY IF EXISTS "descuentos_select_all" ON descuentos_zonas;
  DROP POLICY IF EXISTS "descuentos_modify_super" ON descuentos_zonas;
  -- consultorios
  DROP POLICY IF EXISTS "consultorios_select_all" ON consultorios;
  DROP POLICY IF EXISTS "consultorios_modify_admin" ON consultorios;
  -- promos
  DROP POLICY IF EXISTS "promos_select_all" ON promos;
  DROP POLICY IF EXISTS "promos_modify_admin" ON promos;
  -- sesiones
  DROP POLICY IF EXISTS "sesiones_zona_select_admin" ON paciente_zona_sesiones;
  DROP POLICY IF EXISTS "sesiones_zona_modify_admin" ON paciente_zona_sesiones;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Borrar triggers
DROP TRIGGER IF EXISTS tr_configuracion_updated ON configuracion;
DROP TRIGGER IF EXISTS tr_usuarios_updated ON usuarios;
DROP TRIGGER IF EXISTS tr_zonas_updated ON zonas;
DROP TRIGGER IF EXISTS tr_pacientes_updated ON pacientes;
DROP TRIGGER IF EXISTS tr_turnos_updated ON turnos;
DROP TRIGGER IF EXISTS tr_caja_diaria_updated ON caja_diaria;
DROP TRIGGER IF EXISTS tr_promos_updated ON promos;

-- Borrar funciones
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS get_user_rol() CASCADE;
DROP FUNCTION IF EXISTS crear_usuario_admin(TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS calcular_descuento_zonas(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS resumen_caja(DATE) CASCADE;
DROP FUNCTION IF EXISTS seed_super_admin(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS registrar_usuario(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS incrementar_sesiones_zona(UUID, UUID[]) CASCADE;
DROP FUNCTION IF EXISTS get_sesiones_paciente(UUID) CASCADE;

-- Borrar tablas (orden por dependencias)
DROP TABLE IF EXISTS caja_movimientos CASCADE;
DROP TABLE IF EXISTS caja_diaria CASCADE;
DROP TABLE IF EXISTS paciente_zona_sesiones CASCADE;
DROP TABLE IF EXISTS paciente_observaciones CASCADE;
DROP TABLE IF EXISTS turnos CASCADE;
DROP TABLE IF EXISTS bloqueos CASCADE;
DROP TABLE IF EXISTS promos CASCADE;
DROP TABLE IF EXISTS consultorios CASCADE;
DROP TABLE IF EXISTS descuentos_zonas CASCADE;
DROP TABLE IF EXISTS horarios_operativos CASCADE;
DROP TABLE IF EXISTS zonas CASCADE;
DROP TABLE IF EXISTS pacientes CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS configuracion CASCADE;

-- Borrar indices
DROP INDEX IF EXISTS idx_turnos_fecha;
DROP INDEX IF EXISTS idx_turnos_paciente;
DROP INDEX IF EXISTS idx_turnos_estado;

-- ============================================
-- PASO 2: RECREAR TODO (001 + 005 + 007)
-- ============================================

-- Tabla de configuracion del centro (una sola fila)
CREATE TABLE configuracion (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  nombre_centro TEXT NOT NULL DEFAULT 'Alaía Depilación Definitiva',
  subtitulo TEXT DEFAULT 'Depilación Láser',
  slogan TEXT DEFAULT '',
  telefono TEXT DEFAULT '',
  whatsapp TEXT DEFAULT '',
  email TEXT DEFAULT '',
  direccion TEXT DEFAULT '',
  direccion_maps_url TEXT DEFAULT '',
  logo_url TEXT DEFAULT '',
  instagram TEXT DEFAULT '',
  color_primario TEXT DEFAULT '#1A1A1A',
  color_secundario TEXT DEFAULT '#E8D5C4',
  color_acento TEXT DEFAULT '#D4AF37',
  min_anticipacion_horas INTEGER DEFAULT 2,
  max_dias_adelanto INTEGER DEFAULT 30,
  duracion_turno_minutos INTEGER DEFAULT 20,
  hora_inicio TIME DEFAULT '08:00',
  hora_fin TIME DEFAULT '21:00',
  mensaje_bienvenida TEXT DEFAULT '',
  banner_imagen_url TEXT DEFAULT '',
  onboarding_completed BOOLEAN DEFAULT false,
  -- Campos de 005
  intervalo_minutos INTEGER DEFAULT 5,
  -- Campos de 007
  banner_video_url TEXT DEFAULT '',
  banner_tipo TEXT DEFAULT 'imagen' CHECK (banner_tipo IN ('imagen', 'video')),
  color_fondo TEXT DEFAULT '#F5F0EB',
  color_texto TEXT DEFAULT '#2C2C2C',
  color_boton_texto TEXT DEFAULT '#FFFFFF',
  mostrar_zonas_publico BOOLEAN DEFAULT true,
  mostrar_descuentos_publico BOOLEAN DEFAULT true,
  mostrar_precios_publico BOOLEAN DEFAULT false,
  facebook TEXT DEFAULT '',
  tiktok TEXT DEFAULT '',
  texto_hero TEXT DEFAULT 'Depilación láser de última generación',
  texto_cta TEXT DEFAULT 'Reservar Turno',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO configuracion (id) VALUES (1) ON CONFLICT DO NOTHING;

-- Tabla de usuarios admin
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('super_admin', 'operadora')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Zonas de tratamiento (con precios duales desde 005)
CREATE TABLE zonas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  precio_efectivo NUMERIC(10,2) NOT NULL DEFAULT 0,
  precio_tarjeta NUMERIC(10,2) DEFAULT 0,
  duracion_minutos INTEGER DEFAULT 20,
  descripcion TEXT DEFAULT '',
  activa BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Pacientes
CREATE TABLE pacientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  telefono TEXT DEFAULT '',
  email TEXT DEFAULT '',
  cvu TEXT DEFAULT '',
  fecha_nacimiento DATE,
  notas TEXT DEFAULT '',
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Observaciones clinicas
CREATE TABLE paciente_observaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES usuarios(id),
  texto TEXT NOT NULL,
  tipo TEXT DEFAULT 'general' CHECK (tipo IN ('general', 'clinica', 'alerta')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Consultorios (3 agendas paralelas)
CREATE TABLE consultorios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  orden INTEGER DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO consultorios (nombre, orden) VALUES
  ('Consultorio 1', 1),
  ('Consultorio 2', 2),
  ('Consultorio 3', 3)
ON CONFLICT DO NOTHING;

-- Promos (paquetes de zonas con tiempo y precio fijo)
CREATE TABLE promos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  descripcion TEXT DEFAULT '',
  zonas_ids UUID[] DEFAULT '{}',
  zonas_nombres TEXT DEFAULT '',
  duracion_minutos INTEGER NOT NULL DEFAULT 15,
  precio_efectivo NUMERIC(10,2) NOT NULL DEFAULT 0,
  precio_tarjeta NUMERIC(10,2) NOT NULL DEFAULT 0,
  activa BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Turnos / Agenda (con consultorios, promos, seña vencimiento de 005)
CREATE TABLE turnos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE SET NULL,
  nombre_paciente TEXT NOT NULL DEFAULT '',
  telefono_paciente TEXT DEFAULT '',
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  consultorio_id UUID REFERENCES consultorios(id),
  zonas_ids UUID[] DEFAULT '{}',
  zonas_nombres TEXT DEFAULT '',
  numero_sesion INTEGER DEFAULT 1,
  tiempo_sesion_minutos INTEGER DEFAULT 20,
  promo_id UUID REFERENCES promos(id),
  -- Precios y pagos
  precio NUMERIC(10,2) DEFAULT 0,
  descuento_porcentaje NUMERIC(5,2) DEFAULT 0,
  precio_final NUMERIC(10,2) DEFAULT 0,
  sena NUMERIC(10,2) DEFAULT 0,
  sena_metodo TEXT DEFAULT '' CHECK (sena_metodo IN ('', 'efectivo', 'mercado_pago')),
  sena_vencimiento DATE,
  pago_efectivo NUMERIC(10,2) DEFAULT 0,
  pago_mercado_pago NUMERIC(10,2) DEFAULT 0,
  pago_tarjeta NUMERIC(10,2) DEFAULT 0,
  resta_pagar NUMERIC(10,2) DEFAULT 0,
  -- Sena proxima sesion
  sena_proxima NUMERIC(10,2) DEFAULT 0,
  sena_proxima_metodo TEXT DEFAULT '' CHECK (sena_proxima_metodo IN ('', 'efectivo', 'mercado_pago')),
  -- Estado
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN (
    'pendiente', 'confirmado', 'en_atencion', 'completado', 'cancelado', 'no_show',
    'no_dar_turno', 'practica'
  )),
  pago_estado TEXT DEFAULT 'pendiente' CHECK (pago_estado IN ('pendiente', 'pagado', 'parcial')),
  observaciones TEXT DEFAULT '',
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_turnos_fecha ON turnos(fecha);
CREATE INDEX idx_turnos_paciente ON turnos(paciente_id);
CREATE INDEX idx_turnos_estado ON turnos(estado);

-- Horarios operativos
CREATE TABLE horarios_operativos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  activo BOOLEAN DEFAULT true,
  UNIQUE(dia_semana)
);

INSERT INTO horarios_operativos (dia_semana, hora_inicio, hora_fin, activo) VALUES
  (0, '08:00', '21:00', true),
  (1, '08:00', '21:00', true),
  (2, '08:00', '21:00', true),
  (3, '08:00', '21:00', true),
  (4, '08:00', '21:00', true),
  (5, '08:00', '14:00', true),
  (6, '08:00', '14:00', false)
ON CONFLICT DO NOTHING;

-- Bloqueos de horarios (con consultorio de 005)
CREATE TABLE bloqueos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL,
  hora_inicio TIME,
  hora_fin TIME,
  dia_completo BOOLEAN DEFAULT false,
  motivo TEXT DEFAULT '',
  consultorio_id UUID REFERENCES consultorios(id),
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Caja diaria
CREATE TABLE caja_diaria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL UNIQUE,
  cambio_inicio NUMERIC(10,2) DEFAULT 0,
  cambio_fin NUMERIC(10,2) DEFAULT 0,
  total_efectivo NUMERIC(10,2) DEFAULT 0,
  total_mercado_pago NUMERIC(10,2) DEFAULT 0,
  total_senas NUMERIC(10,2) DEFAULT 0,
  total_senas_proxima NUMERIC(10,2) DEFAULT 0,
  total_retiros NUMERIC(10,2) DEFAULT 0,
  total_gastos NUMERIC(10,2) DEFAULT 0,
  efectivo_real NUMERIC(10,2) DEFAULT 0,
  diferencia NUMERIC(10,2) DEFAULT 0,
  cerrada BOOLEAN DEFAULT false,
  cerrada_por UUID REFERENCES usuarios(id),
  cerrada_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Movimientos de caja
CREATE TABLE caja_movimientos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id UUID NOT NULL REFERENCES caja_diaria(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('retiro', 'gasto')),
  descripcion TEXT NOT NULL DEFAULT '',
  monto NUMERIC(10,2) NOT NULL DEFAULT 0,
  responsable TEXT DEFAULT '',
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Descuentos por cantidad de zonas
CREATE TABLE descuentos_zonas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cantidad_zonas INTEGER NOT NULL UNIQUE,
  porcentaje_descuento NUMERIC(5,2) NOT NULL,
  activo BOOLEAN DEFAULT true
);

INSERT INTO descuentos_zonas (cantidad_zonas, porcentaje_descuento) VALUES
  (2, 15.00),
  (3, 20.00),
  (4, 25.00),
  (5, 30.00)
ON CONFLICT DO NOTHING;

-- Sesiones por zona por paciente
CREATE TABLE paciente_zona_sesiones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  zona_id UUID NOT NULL REFERENCES zonas(id) ON DELETE CASCADE,
  numero_sesion INTEGER NOT NULL DEFAULT 0,
  ultima_fecha DATE,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(paciente_id, zona_id)
);

-- ============================================
-- PASO 3: FUNCIONES
-- ============================================

-- Funcion para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers de updated_at
CREATE TRIGGER tr_configuracion_updated BEFORE UPDATE ON configuracion
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_usuarios_updated BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_zonas_updated BEFORE UPDATE ON zonas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_pacientes_updated BEFORE UPDATE ON pacientes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_turnos_updated BEFORE UPDATE ON turnos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_caja_diaria_updated BEFORE UPDATE ON caja_diaria
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_promos_updated BEFORE UPDATE ON promos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Funcion para obtener el rol del usuario actual
CREATE OR REPLACE FUNCTION get_user_rol()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT rol FROM usuarios
    WHERE auth_user_id = auth.uid() AND activo = true
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para crear usuario admin
CREATE OR REPLACE FUNCTION crear_usuario_admin(
  p_email TEXT,
  p_password TEXT,
  p_nombre TEXT,
  p_rol TEXT DEFAULT 'operadora'
)
RETURNS JSON AS $$
DECLARE
  v_auth_user_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM usuarios
    WHERE auth_user_id = auth.uid() AND rol = 'super_admin' AND activo = true
  ) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  IF p_rol NOT IN ('super_admin', 'operadora') THEN
    RAISE EXCEPTION 'Rol invalido: %', p_rol;
  END IF;

  v_auth_user_id := extensions.uuid_generate_v4();

  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    aud, role, confirmation_token
  ) VALUES (
    v_auth_user_id,
    '00000000-0000-0000-0000-000000000000',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('nombre', p_nombre, 'rol', p_rol),
    'authenticated', 'authenticated', ''
  );

  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) VALUES (
    v_auth_user_id, v_auth_user_id, p_email,
    jsonb_build_object('sub', v_auth_user_id, 'email', p_email),
    'email', now(), now(), now()
  );

  INSERT INTO usuarios (auth_user_id, nombre, email, rol)
  VALUES (v_auth_user_id, p_nombre, p_email, p_rol);

  RETURN json_build_object(
    'success', true,
    'user_id', v_auth_user_id,
    'email', p_email,
    'rol', p_rol
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para calcular descuento por zonas
CREATE OR REPLACE FUNCTION calcular_descuento_zonas(p_cantidad_zonas INTEGER)
RETURNS NUMERIC AS $$
DECLARE
  v_descuento NUMERIC := 0;
BEGIN
  IF p_cantidad_zonas >= 5 THEN
    SELECT porcentaje_descuento INTO v_descuento
    FROM descuentos_zonas WHERE cantidad_zonas = 5 AND activo = true;
  ELSE
    SELECT porcentaje_descuento INTO v_descuento
    FROM descuentos_zonas WHERE cantidad_zonas = p_cantidad_zonas AND activo = true;
  END IF;
  RETURN COALESCE(v_descuento, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para resumen de caja
CREATE OR REPLACE FUNCTION resumen_caja(p_fecha DATE)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM usuarios
    WHERE auth_user_id = auth.uid() AND rol = 'super_admin' AND activo = true
  ) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  SELECT json_build_object(
    'total_precio', COALESCE(SUM(precio_final), 0),
    'total_sena', COALESCE(SUM(sena), 0),
    'total_efectivo', COALESCE(SUM(pago_efectivo), 0),
    'total_mercado_pago', COALESCE(SUM(pago_mercado_pago), 0),
    'total_resta', COALESCE(SUM(resta_pagar), 0),
    'total_sena_proxima', COALESCE(SUM(sena_proxima), 0),
    'cantidad_turnos', COUNT(*),
    'completados', COUNT(*) FILTER (WHERE estado = 'completado'),
    'cancelados', COUNT(*) FILTER (WHERE estado = 'cancelado'),
    'no_show', COUNT(*) FILTER (WHERE estado = 'no_show')
  ) INTO v_result
  FROM turnos
  WHERE fecha = p_fecha AND estado NOT IN ('no_dar_turno', 'practica');

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para seed primer super admin
CREATE OR REPLACE FUNCTION seed_super_admin(
  p_email TEXT,
  p_password TEXT,
  p_nombre TEXT
)
RETURNS JSON AS $$
DECLARE
  v_auth_user_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM usuarios LIMIT 1) THEN
    RAISE EXCEPTION 'Ya existe al menos un usuario. Use crear_usuario_admin.';
  END IF;

  v_auth_user_id := extensions.uuid_generate_v4();

  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    aud, role, confirmation_token
  ) VALUES (
    v_auth_user_id,
    '00000000-0000-0000-0000-000000000000',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('nombre', p_nombre, 'rol', 'super_admin'),
    'authenticated', 'authenticated', ''
  );

  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) VALUES (
    v_auth_user_id, v_auth_user_id, p_email,
    jsonb_build_object('sub', v_auth_user_id, 'email', p_email),
    'email', now(), now(), now()
  );

  INSERT INTO usuarios (auth_user_id, nombre, email, rol)
  VALUES (v_auth_user_id, p_nombre, p_email, 'super_admin');

  RETURN json_build_object(
    'success', true,
    'message', 'Super admin creado',
    'user_id', v_auth_user_id,
    'email', p_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para auto-registro de usuarios
CREATE OR REPLACE FUNCTION registrar_usuario(
  p_nombre TEXT,
  p_rol TEXT DEFAULT 'operadora'
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_email TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  IF p_rol NOT IN ('super_admin', 'operadora') THEN
    RAISE EXCEPTION 'Rol invalido';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;

  IF EXISTS (SELECT 1 FROM usuarios WHERE auth_user_id = v_user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Ya registrado');
  END IF;

  INSERT INTO usuarios (auth_user_id, nombre, email, rol)
  VALUES (v_user_id, p_nombre, v_email, p_rol);

  RETURN json_build_object(
    'success', true,
    'message', 'Usuario registrado',
    'user_id', v_user_id,
    'email', v_email,
    'rol', p_rol
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para incrementar sesion por zona
CREATE OR REPLACE FUNCTION incrementar_sesiones_zona(
  p_paciente_id UUID,
  p_zonas_ids UUID[]
)
RETURNS void AS $$
DECLARE
  v_zona_id UUID;
BEGIN
  FOREACH v_zona_id IN ARRAY p_zonas_ids
  LOOP
    INSERT INTO paciente_zona_sesiones (paciente_id, zona_id, numero_sesion, ultima_fecha)
    VALUES (p_paciente_id, v_zona_id, 1, CURRENT_DATE)
    ON CONFLICT (paciente_id, zona_id)
    DO UPDATE SET
      numero_sesion = paciente_zona_sesiones.numero_sesion + 1,
      ultima_fecha = CURRENT_DATE,
      updated_at = now();
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para obtener sesiones de un paciente
CREATE OR REPLACE FUNCTION get_sesiones_paciente(p_paciente_id UUID)
RETURNS TABLE(zona_id UUID, zona_nombre TEXT, numero_sesion INTEGER, ultima_fecha DATE) AS $$
BEGIN
  RETURN QUERY
    SELECT
      pzs.zona_id,
      z.nombre AS zona_nombre,
      pzs.numero_sesion,
      pzs.ultima_fecha
    FROM paciente_zona_sesiones pzs
    JOIN zonas z ON z.id = pzs.zona_id
    WHERE pzs.paciente_id = p_paciente_id
    ORDER BY z.nombre;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 4: RLS POLICIES
-- ============================================

-- Habilitar RLS
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
ALTER TABLE consultorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE paciente_zona_sesiones ENABLE ROW LEVEL SECURITY;

-- CONFIGURACION
CREATE POLICY "configuracion_select_all" ON configuracion FOR SELECT USING (true);
CREATE POLICY "configuracion_update_admin" ON configuracion FOR UPDATE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- USUARIOS
CREATE POLICY "usuarios_select_auth" ON usuarios FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "usuarios_insert_super" ON usuarios FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);
CREATE POLICY "usuarios_update_super" ON usuarios FOR UPDATE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);
CREATE POLICY "usuarios_delete_super" ON usuarios FOR DELETE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- ZONAS
CREATE POLICY "zonas_select_all" ON zonas FOR SELECT USING (true);
CREATE POLICY "zonas_modify_admin" ON zonas FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- PACIENTES
CREATE POLICY "pacientes_select_admin" ON pacientes FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "pacientes_insert_admin" ON pacientes FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "pacientes_update_admin" ON pacientes FOR UPDATE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "pacientes_delete_super" ON pacientes FOR DELETE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- OBSERVACIONES
CREATE POLICY "observaciones_select_admin" ON paciente_observaciones FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "observaciones_insert_admin" ON paciente_observaciones FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "observaciones_update_admin" ON paciente_observaciones FOR UPDATE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);

-- TURNOS (anon puede crear para reservar)
CREATE POLICY "turnos_select_all" ON turnos FOR SELECT USING (true);
CREATE POLICY "turnos_insert_anon" ON turnos FOR INSERT WITH CHECK (true);
CREATE POLICY "turnos_update_admin" ON turnos FOR UPDATE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "turnos_delete_admin" ON turnos FOR DELETE USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- HORARIOS
CREATE POLICY "horarios_select_all" ON horarios_operativos FOR SELECT USING (true);
CREATE POLICY "horarios_modify_admin" ON horarios_operativos FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- BLOQUEOS
CREATE POLICY "bloqueos_select_all" ON bloqueos FOR SELECT USING (true);
CREATE POLICY "bloqueos_modify_admin" ON bloqueos FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- CAJA (solo super_admin)
CREATE POLICY "caja_diaria_select_super" ON caja_diaria FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);
CREATE POLICY "caja_diaria_modify_super" ON caja_diaria FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);
CREATE POLICY "caja_movimientos_select_super" ON caja_movimientos FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);
CREATE POLICY "caja_movimientos_modify_super" ON caja_movimientos FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- DESCUENTOS
CREATE POLICY "descuentos_select_all" ON descuentos_zonas FOR SELECT USING (true);
CREATE POLICY "descuentos_modify_super" ON descuentos_zonas FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- CONSULTORIOS
CREATE POLICY "consultorios_select_all" ON consultorios FOR SELECT USING (true);
CREATE POLICY "consultorios_modify_admin" ON consultorios FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- PROMOS
CREATE POLICY "promos_select_all" ON promos FOR SELECT USING (true);
CREATE POLICY "promos_modify_admin" ON promos FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- SESIONES POR ZONA
CREATE POLICY "sesiones_zona_select_admin" ON paciente_zona_sesiones FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "sesiones_zona_modify_admin" ON paciente_zona_sesiones FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);

-- ============================================
-- LISTO! Ahora ejecuta tu seed_super_admin si necesitas:
-- SELECT seed_super_admin('tu@email.com', 'tupassword', 'Tu Nombre');
-- ============================================
