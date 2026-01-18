-- ============================================
-- SEED: 004_seed_malick_sy_chain
-- DESCRIPTION: Insert the verified Silsila of El Hadj Malick Sy
-- ============================================

-- 1. Insert Nodes (if not exist)
-- Note: We use ON CONFLICT DO NOTHING to avoid duplicates, assuming names are unique enough for this seed.
-- In production, we might want more robust matching.

INSERT INTO public.silsilas (name, is_global, level) VALUES 
('Prophet Muhammad (SAW)', TRUE, 1000),
('Cheikh Ahmad At-Tidiani', TRUE, 100),
('Muhammad Al-Ghali', TRUE, 90),
('Cheikh Oumar Foutiyou Tall', TRUE, 80),
('Alphahim Mayoro Welle', TRUE, 70),
('El Hadj Malick Sy', TRUE, 60)
ON CONFLICT DO NOTHING;

-- 2. Create Connections (Parent -> Child)

-- Muhammad (SAW) -> Cheikh Ahmad (Veille/Spirituel)
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT p.id, c.id FROM public.silsilas p, public.silsilas c 
WHERE p.name = 'Prophet Muhammad (SAW)' AND c.name = 'Cheikh Ahmad At-Tidiani'
ON CONFLICT DO NOTHING;

-- Cheikh Ahmad -> Muhammad Al-Ghali
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT p.id, c.id FROM public.silsilas p, public.silsilas c 
WHERE p.name = 'Cheikh Ahmad At-Tidiani' AND c.name = 'Muhammad Al-Ghali'
ON CONFLICT DO NOTHING;

-- Muhammad Al-Ghali -> Cheikh Oumar Foutiyou Tall
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT p.id, c.id FROM public.silsilas p, public.silsilas c 
WHERE p.name = 'Muhammad Al-Ghali' AND c.name = 'Cheikh Oumar Foutiyou Tall'
ON CONFLICT DO NOTHING;

-- Cheikh Oumar -> Alphahim Mayoro Welle
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT p.id, c.id FROM public.silsilas p, public.silsilas c 
WHERE p.name = 'Cheikh Oumar Foutiyou Tall' AND c.name = 'Alphahim Mayoro Welle'
ON CONFLICT DO NOTHING;

-- Alphahim Mayoro Welle -> El Hadj Malick Sy
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT p.id, c.id FROM public.silsilas p, public.silsilas c 
WHERE p.name = 'Alphahim Mayoro Welle' AND c.name = 'El Hadj Malick Sy'
ON CONFLICT DO NOTHING;
