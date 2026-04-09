-- ============================================
-- Funcion para auto-registro de usuarios admin
-- Eligen su rol al registrarse (super_admin o operadora)
-- ============================================

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

  -- Validar rol
  IF p_rol NOT IN ('super_admin', 'operadora') THEN
    RAISE EXCEPTION 'Rol invalido';
  END IF;

  -- Obtener email del usuario autenticado
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;

  -- Verificar que no exista ya
  IF EXISTS (SELECT 1 FROM usuarios WHERE auth_user_id = v_user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Ya registrado');
  END IF;

  -- Crear registro
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
