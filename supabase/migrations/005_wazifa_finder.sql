-- ============================================
-- TABLE: wazifa_gatherings (Lieux de Wazifa)
-- ============================================

-- Extensions nécessaires pour la géolocalisation
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE rhythm_level AS ENUM ('SLOW', 'MEDIUM', 'FAST');

CREATE TABLE IF NOT EXISTS public.wazifa_gatherings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    location GEOGRAPHY(POINT) NOT NULL, -- Stockage GPS optimisé
    rhythm rhythm_level DEFAULT 'MEDIUM',
    schedule_morning TIME, -- Heure Wazifa Matin
    schedule_evening TIME, -- Heure Wazifa Soir
    contact_phone TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index géospatial pour les recherches de proximité rapides
CREATE INDEX idx_wazifa_location ON public.wazifa_gatherings USING GIST (location);

-- ============================================
-- RLS POLICIES (Sécurité)
-- ============================================
ALTER TABLE public.wazifa_gatherings ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut voir les lieux (même sans compte, pour l'instant)
CREATE POLICY "wazifa_select_all"
    ON public.wazifa_gatherings
    FOR SELECT
    USING (true);

-- Seuls les utilisateurs connectés peuvent ajouter un lieu
CREATE POLICY "wazifa_insert_auth"
    ON public.wazifa_gatherings
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Seul le créateur peut modifier son lieu
CREATE POLICY "wazifa_update_own"
    ON public.wazifa_gatherings
    FOR UPDATE
    USING (created_by = auth.uid());

-- ============================================
-- RPC: Rechercher les wazifas à proximité
-- ============================================
CREATE OR REPLACE FUNCTION get_nearby_wazifas(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 5000 -- 5km par défaut
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    address TEXT,
    rhythm rhythm_level,
    schedule_morning TIME,
    schedule_evening TIME,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        w.id,
        w.name,
        w.description,
        w.address,
        w.rhythm,
        w.schedule_morning,
        w.schedule_evening,
        st_y(w.location::geometry) as lat,
        st_x(w.location::geometry) as lng,
        st_distance(w.location, st_point(p_lng, p_lat)::geography) as distance_meters
    FROM
        public.wazifa_gatherings w
    WHERE
        st_dwithin(w.location, st_point(p_lng, p_lat)::geography, radius_meters)
    ORDER BY
        distance_meters ASC;
END;
$$;
