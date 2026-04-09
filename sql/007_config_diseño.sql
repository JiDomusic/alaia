
-- ============================================
-- Campos de diseño en configuracion (como Bella Color)
-- ============================================

-- Video banner
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS banner_video_url TEXT DEFAULT '';
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS banner_tipo TEXT DEFAULT 'imagen' CHECK (banner_tipo IN ('imagen', 'video'));

-- Colores adicionales
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS color_fondo TEXT DEFAULT '#F5F0EB';
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS color_texto TEXT DEFAULT '#2C2C2C';
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS color_boton_texto TEXT DEFAULT '#FFFFFF';

-- Mostrar/ocultar secciones
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS mostrar_zonas_publico BOOLEAN DEFAULT true;
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS mostrar_descuentos_publico BOOLEAN DEFAULT true;
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS mostrar_precios_publico BOOLEAN DEFAULT false;

-- Redes sociales
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS facebook TEXT DEFAULT '';
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS tiktok TEXT DEFAULT '';

-- Textos personalizables
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS texto_hero TEXT DEFAULT 'Depilación láser de última generación';
ALTER TABLE configuracion ADD COLUMN IF NOT EXISTS texto_cta TEXT DEFAULT 'Reservar Turno';
