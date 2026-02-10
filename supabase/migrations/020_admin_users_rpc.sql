-- ============================================
-- RPC: get_admin_users
-- Permet aux admins de récupérer les profils AVEC les emails (depuis auth.users)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_admin_users()
RETURNS TABLE (
  id UUID,
  display_name TEXT,
  email VARCHAR, -- Type from auth.users
  phone TEXT,    -- From auth.users if needed, or profiles (deprecated)
  role public.user_role,
  created_at TIMESTAMPTZ,
  avatar_url TEXT,
  level INTEGER,
  points INTEGER
) 
SECURITY DEFINER -- Exécuté avec les privilèges du créateur (pour lire auth.users)
SET search_path = public, auth -- Sécurité: Définir le search_path
AS $$
BEGIN
  -- 1. Sécurité : Vérifier que l'utilisateur est ADMIN ou SUPER_ADMIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('ADMIN', 'SUPER_ADMIN')
  ) THEN
    RAISE EXCEPTION 'Access Denied: You are not an Admin';
  END IF;

  -- 2. Retourner la jointure
  RETURN QUERY
  SELECT 
    p.id,
    p.display_name,
    u.email::VARCHAR,
    COALESCE(u.phone, p.phone), -- Fallback to profile phone for now
    p.role,
    p.created_at,
    p.avatar_url,
    p.level,
    p.points
  FROM public.profiles p
  JOIN auth.users u ON p.id = u.id
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute to authenticated (security check is inside function)
GRANT EXECUTE ON FUNCTION public.get_admin_users TO authenticated;
