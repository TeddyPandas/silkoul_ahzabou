-- Re-create the create_wazifa RPC to ensure it does not contain erroneous SQL commands.
-- Also updated the type of p_rhythm to TEXT to avoid issues with missing enum types.

CREATE OR REPLACE FUNCTION create_wazifa(
    p_name TEXT,
    p_description TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_rhythm TEXT, -- Changed from rhythm_level to TEXT to be safe
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
        p_rhythm, -- This assumes the column is TEXT or implicitly castable
        p_morning,
        p_evening,
        auth.uid()
    )
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;
