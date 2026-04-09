-- ============================================
-- ALAIA - Depilacion Definitiva
-- Schema principal
-- ============================================

-- Tabla de configuracion del centro (una sola fila)
CREATE TABLE IF NOT EXISTS configuracion (
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
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar fila por defecto
INSERT INTO configuracion (id) VALUES (1) ON CONFLICT DO NOTHING;

-- Tabla de usuarios admin (vinculada a auth.users)
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('super_admin', 'operadora')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Zonas de tratamiento
CREATE TABLE IF NOT EXISTS zonas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  precio NUMERIC(10,2) NOT NULL DEFAULT 0,
  duracion_minutos INTEGER DEFAULT 20,
  descripcion TEXT DEFAULT '',
  activa BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Pacientes
CREATE TABLE IF NOT EXISTS pacientes (
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

-- Observaciones clinicas por paciente
CREATE TABLE IF NOT EXISTS paciente_observaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES usuarios(id),
  texto TEXT NOT NULL,
  tipo TEXT DEFAULT 'general' CHECK (tipo IN ('general', 'clinica', 'alerta')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Turnos / Agenda
CREATE TABLE IF NOT EXISTS turnos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE SET NULL,
  nombre_paciente TEXT NOT NULL DEFAULT '',
  telefono_paciente TEXT DEFAULT '',
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  -- Zonas del turno (puede ser multi-zona)
  zonas_ids UUID[] DEFAULT '{}',
  zonas_nombres TEXT DEFAULT '',
  numero_sesion INTEGER DEFAULT 1,
  tiempo_sesion_minutos INTEGER DEFAULT 20,
  -- Precios y pagos
  precio NUMERIC(10,2) DEFAULT 0,
  descuento_porcentaje NUMERIC(5,2) DEFAULT 0,
  precio_final NUMERIC(10,2) DEFAULT 0,
  sena NUMERIC(10,2) DEFAULT 0,
  sena_metodo TEXT DEFAULT '' CHECK (sena_metodo IN ('', 'efectivo', 'mercado_pago')),
  pago_efectivo NUMERIC(10,2) DEFAULT 0,
  pago_mercado_pago NUMERIC(10,2) DEFAULT 0,
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
  -- Observaciones del turno
  observaciones TEXT DEFAULT '',
  -- Metadata
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indices para busquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_turnos_fecha ON turnos(fecha);
CREATE INDEX IF NOT EXISTS idx_turnos_paciente ON turnos(paciente_id);
CREATE INDEX IF NOT EXISTS idx_turnos_estado ON turnos(estado);

-- Horarios operativos (dia de la semana)
CREATE TABLE IF NOT EXISTS horarios_operativos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6), -- 0=lunes, 6=domingo
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  activo BOOLEAN DEFAULT true,
  UNIQUE(dia_semana)
);

-- Insertar horarios por defecto (lunes a viernes 8-21, sabado 8-14)
INSERT INTO horarios_operativos (dia_semana, hora_inicio, hora_fin, activo) VALUES
  (0, '08:00', '21:00', true),  -- Lunes
  (1, '08:00', '21:00', true),  -- Martes
  (2, '08:00', '21:00', true),  -- Miercoles
  (3, '08:00', '21:00', true),  -- Jueves
  (4, '08:00', '21:00', true),  -- Viernes
  (5, '08:00', '14:00', true),  -- Sabado
  (6, '08:00', '14:00', false)  -- Domingo (cerrado)
ON CONFLICT DO NOTHING;

-- Bloqueos de horarios
CREATE TABLE IF NOT EXISTS bloqueos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL,
  hora_inicio TIME,
  hora_fin TIME,
  dia_completo BOOLEAN DEFAULT false,
  motivo TEXT DEFAULT '',
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Caja diaria
CREATE TABLE IF NOT EXISTS caja_diaria (
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

-- Movimientos de caja (retiros, gastos)
CREATE TABLE IF NOT EXISTS caja_movimientos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id UUID NOT NULL REFERENCES caja_diaria(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('retiro', 'gasto')),
  descripcion TEXT NOT NULL DEFAULT '',
  monto NUMERIC(10,2) NOT NULL DEFAULT 0,
  responsable TEXT DEFAULT '', -- DRA SECRE, DRA OP, NK, etc.
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Descuentos por cantidad de zonas
CREATE TABLE IF NOT EXISTS descuentos_zonas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cantidad_zonas INTEGER NOT NULL UNIQUE,
  porcentaje_descuento NUMERIC(5,2) NOT NULL,
  activo BOOLEAN DEFAULT true
);

-- Insertar descuentos por defecto
INSERT INTO descuentos_zonas (cantidad_zonas, porcentaje_descuento) VALUES
  (2, 15.00),
  (3, 20.00),
  (4, 25.00),
  (5, 30.00)  -- 5 o mas
ON CONFLICT DO NOTHING;

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
