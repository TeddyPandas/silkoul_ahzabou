-- Fix for function overloading conflict
-- We need to drop all variations of create_wazifa before recreating the correct one.

-- Drop the version with TEXT (if it exists)
DROP FUNCTION IF EXISTS public.create_wazifa(text, text, double precision, double precision, text, time without time zone, time without time zone);

-- Drop the version with rhythm_level (if it exists)
-- Note: We must cast the type name if valid, but to be safe we can use the signature.
-- If rhythm_level is a type, postgres signature might use public.rhythm_level
DROP FUNCTION IF EXISTS public.create_wazifa(text, text, double precision, double precision, public.rhythm_level, time without time zone, time without time zone);

-- Just in case, try dropping without schema prefix for the type
DROP FUNCTION IF EXISTS public.create_wazifa(text, text, double precision, double precision, rhythm_level, time without time zone, time without time zone);


-- Now recreate the single source of truth version
-- We use TEXT for p_rhythm to be flexible and avoid type issues, but cast it inside.
CREATE OR REPLACE FUNCTION create_wazifa(
    p_name TEXT,
    p_description TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_rhythm TEXT,
    p_morning TIME,
    p_evening TIME
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
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
        'Adresse définie par GPS',
        st_point(p_lng, p_lat)::geography,
        p_rhythm::rhythm_level, -- Explicit cast to the enum type
        p_morning,
        p_evening,
        auth.uid()
    )
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;
