-- ============================================
-- ALAIA - Consultorios, Promos, Sesiones por zona
-- ============================================

-- Consultorios (3 agendas paralelas)
CREATE TABLE IF NOT EXISTS consultorios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL, -- 'Consultorio 1', 'Consultorio 2', 'Consultorio 3'
  orden INTEGER DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed consultorios
INSERT INTO consultorios (nombre, orden) VALUES
  ('Consultorio 1', 1),
  ('Consultorio 2', 2),
  ('Consultorio 3', 3)
ON CONFLICT DO NOTHING;

-- Agregar consultorio_id a turnos
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS consultorio_id UUID REFERENCES consultorios(id);

-- Agregar consultorio_id a bloqueos
ALTER TABLE bloqueos ADD COLUMN IF NOT EXISTS consultorio_id UUID REFERENCES consultorios(id);

-- ============================================
-- PROMOS (paquetes de zonas con tiempo y precio fijo)
-- ============================================
CREATE TABLE IF NOT EXISTS promos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL, -- 'Axila + Acabado', 'Promo 3 zonas', etc.
  descripcion TEXT DEFAULT '',
  zonas_ids UUID[] DEFAULT '{}', -- zonas incluidas
  zonas_nombres TEXT DEFAULT '', -- para mostrar rapido
  duracion_minutos INTEGER NOT NULL DEFAULT 15,
  precio_efectivo NUMERIC(10,2) NOT NULL DEFAULT 0,
  precio_tarjeta NUMERIC(10,2) NOT NULL DEFAULT 0,
  activa BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger updated_at
CREATE TRIGGER tr_promos_updated BEFORE UPDATE ON promos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- PRECIOS DUALES en zonas (efectivo y tarjeta)
-- ============================================
ALTER TABLE zonas ADD COLUMN IF NOT EXISTS precio_tarjeta NUMERIC(10,2) DEFAULT 0;
-- La columna 'precio' existente pasa a ser precio_efectivo
-- Renombrar para claridad
ALTER TABLE zonas RENAME COLUMN precio TO precio_efectivo;

-- ============================================
-- SESIONES POR ZONA POR PACIENTE
-- (Cada zona tiene su propio contador de sesiones)
-- ============================================
CREATE TABLE IF NOT EXISTS paciente_zona_sesiones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  zona_id UUID NOT NULL REFERENCES zonas(id) ON DELETE CASCADE,
  numero_sesion INTEGER NOT NULL DEFAULT 0,
  ultima_fecha DATE,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(paciente_id, zona_id)
);

-- ============================================
-- SEÑA con vencimiento
-- ============================================
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS sena_vencimiento DATE;
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS pago_tarjeta NUMERIC(10,2) DEFAULT 0;

-- Agregar promo_id al turno (si el turno es de una promo)
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS promo_id UUID REFERENCES promos(id);

-- ============================================
-- SLOTS cada 5 minutos (configuracion)
-- ============================================
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS intervalo_minutos INTEGER DEFAULT 5;

-- ============================================
-- RLS para nuevas tablas
-- ============================================
ALTER TABLE consultorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE paciente_zona_sesiones ENABLE ROW LEVEL SECURITY;

-- Consultorios: todos leen, super_admin modifica
CREATE POLICY "consultorios_select_all" ON consultorios FOR SELECT USING (true);
CREATE POLICY "consultorios_modify_admin" ON consultorios FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- Promos: todos leen (publico ve promos), super_admin modifica
CREATE POLICY "promos_select_all" ON promos FOR SELECT USING (true);
CREATE POLICY "promos_modify_admin" ON promos FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE rol = 'super_admin' AND activo = true)
);

-- Sesiones por zona: solo admin
CREATE POLICY "sesiones_zona_select_admin" ON paciente_zona_sesiones FOR SELECT USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);
CREATE POLICY "sesiones_zona_modify_admin" ON paciente_zona_sesiones FOR ALL USING (
  auth.uid() IN (SELECT auth_user_id FROM usuarios WHERE activo = true)
);

-- ============================================
-- FUNCION: Incrementar sesion por zona al completar turno
-- ============================================
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

-- ============================================
-- FUNCION: Obtener sesiones de un paciente por zona
-- ============================================
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
