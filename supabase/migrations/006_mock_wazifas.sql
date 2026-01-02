-- ============================================
-- MIGRATION: 006_mock_wazifas.sql
-- Données de test pour Wazifa Finder
-- ============================================

-- Fonction pour insérer un lieu facilement
CREATE OR REPLACE FUNCTION insert_mock_wazifa(
    p_name TEXT,
    p_desc TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_rhythm rhythm_level,
    p_am TIME,
    p_pm TIME
) RETURNS VOID AS $$
BEGIN
    INSERT INTO public.wazifa_gatherings (
        name, description, address, location, rhythm, schedule_morning, schedule_evening
    ) VALUES (
        p_name,
        p_desc,
        'Adresse simulée',
        st_point(p_lng, p_lat)::geography,
        p_rhythm,
        p_am,
        p_pm
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DAKAR (Plateau & Alentours)
-- ============================================
SELECT insert_mock_wazifa('Zawiya El Hadj Malick Sy', 'Grande Zawiya du Plateau', 14.6708, -17.4361, 'MEDIUM', '06:00', '19:00');
SELECT insert_mock_wazifa('Dahira Sopé Nabi', 'Wazifa étudiants (Rapide)', 14.6937, -17.4449, 'FAST', '06:30', '20:00');
SELECT insert_mock_wazifa('Mosquée Omarienne', 'Wazifa très posée (Lent)', 14.6811, -17.4674, 'SLOW', '05:45', '18:45');
SELECT insert_mock_wazifa('Keur Serigne Bi', 'Ambiance familiale', 14.7167, -17.4677, 'MEDIUM', '06:15', '19:15');

-- ============================================
-- TIVAOUANE & KAOLACK
-- ============================================
SELECT insert_mock_wazifa('Grande Mosquée Tivaouane', 'Lieu saint', 14.9515, -16.8228, 'SLOW', '06:00', '19:00');
SELECT insert_mock_wazifa('Médina Baye Kaolack', 'Fayda Tijaniyya', 14.1350, -16.0792, 'FAST', '06:00', '19:30');

-- ============================================
-- PARIS (Pour test simulateur Europe)
-- ============================================
SELECT insert_mock_wazifa('Dahira Paris 18ème', 'Rue des Poissonniers', 48.8914, 2.3488, 'MEDIUM', '07:00', '20:00');
SELECT insert_mock_wazifa('Mantes-la-Jolie', 'Foyer Adoma', 48.9908, 1.7173, 'FAST', '06:30', '19:30');

-- Nettoyage de la fonction utilitaire
DROP FUNCTION insert_mock_wazifa;
