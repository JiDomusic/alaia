-- ============================================
-- ALAIA - Funciones de servidor
-- ============================================

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

-- Funcion para crear usuario admin (SECURITY DEFINER - no necesita SRK en cliente)
CREATE OR REPLACE FUNCTION crear_usuario_admin(
  p_email TEXT,
  p_password TEXT,
  p_nombre TEXT,
  p_rol TEXT DEFAULT 'operadora'
)
RETURNS JSON AS $$
DECLARE
  v_auth_user_id UUID;
  v_user_record RECORD;
BEGIN
  -- Solo super_admin puede crear usuarios
  IF NOT EXISTS (
    SELECT 1 FROM usuarios
    WHERE auth_user_id = auth.uid() AND rol = 'super_admin' AND activo = true
  ) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  -- Validar rol
  IF p_rol NOT IN ('super_admin', 'operadora') THEN
    RAISE EXCEPTION 'Rol invalido: %', p_rol;
  END IF;

  -- Crear usuario en auth.users usando extension
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

  -- Crear identidad
  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) VALUES (
    v_auth_user_id, v_auth_user_id, p_email,
    jsonb_build_object('sub', v_auth_user_id, 'email', p_email),
    'email', now(), now(), now()
  );

  -- Crear registro en tabla usuarios
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
    -- 5 o mas zonas: usar el descuento de 5
    SELECT porcentaje_descuento INTO v_descuento
    FROM descuentos_zonas WHERE cantidad_zonas = 5 AND activo = true;
  ELSE
    SELECT porcentaje_descuento INTO v_descuento
    FROM descuentos_zonas WHERE cantidad_zonas = p_cantidad_zonas AND activo = true;
  END IF;

  RETURN COALESCE(v_descuento, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcion para obtener resumen de caja del dia
CREATE OR REPLACE FUNCTION resumen_caja(p_fecha DATE)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- Solo super_admin
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

-- Funcion para seed inicial: crear primer super_admin
-- Se ejecuta UNA sola vez desde el SQL Editor de Supabase
CREATE OR REPLACE FUNCTION seed_super_admin(
  p_email TEXT,
  p_password TEXT,
  p_nombre TEXT
)
RETURNS JSON AS $$
DECLARE
  v_auth_user_id UUID;
BEGIN
  -- Solo permite si no hay usuarios
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
