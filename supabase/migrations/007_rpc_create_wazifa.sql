-- ============================================
-- MIGRATION: 007_create_wazifa_rpc.sql
-- Fonction RPC pour créer un lieu Wazifa
-- ============================================

CREATE OR REPLACE FUNCTION create_wazifa(
    p_name TEXT,
    p_description TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_rhythm rhythm_level,
    p_morning TIME,
    p_evening TIME
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Permet d'exécuter avec les droits du créateur de la fonction (bypass RLS partiel si besoin, mais ici utile pour garantir l'insertion)
AS $$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO public.wazifa_gatherings (
        name,
        description,
        address,
        location,
        rhythm,
        schedule_morning,
        schedule_evening,
        created_by
    ) VALUES (
        p_name,
        p_description,
        'Adresse définie par GPS', -- On pourrait faire du reverse geocoding plus tard
        st_point(p_lng, p_lat)::geography,
        p_rhythm,
        p_morning,
        p_evening,
        auth.uid() -- L'utilisateur connecté
    )
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;
