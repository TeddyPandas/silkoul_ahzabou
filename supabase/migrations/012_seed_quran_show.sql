-- ==============================================================================
-- 0. ENSURE SCHEMA EXISTS (Fix for missing 008 migration)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.transcripts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  teaching_id uuid REFERENCES public.teachings(id) NOT NULL,
  language text DEFAULT 'fr',
  content jsonb NOT NULL,
  created_at timestamp WITH time zone DEFAULT timezone('utc'::text, NOW()) NOT NULL
);

-- Enable RLS (Safe to run multiple times, but good practice to check, 
-- though 'alter table' doesn't error if already enabled usually, but 'create policy' does)
ALTER TABLE public.transcripts ENABLE ROW LEVEL SECURITY;

-- Policies (Drop first to ensure idempotency if they exist partially)
DROP POLICY IF EXISTS "Public transcripts are viewable by everyone." ON public.transcripts;
CREATE POLICY "Public transcripts are viewable by everyone." ON public.transcripts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can insert transcripts." ON public.transcripts;
CREATE POLICY "Admins can insert transcripts." ON public.transcripts FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can update transcripts." ON public.transcripts;
CREATE POLICY "Admins can update transcripts." ON public.transcripts FOR UPDATE USING (true);


-- ==============================================================================
-- 1. SEED DATA (Robust Upserts)
-- ==============================================================================

-- 1.1 Ensure Author (Mishary) exists
INSERT INTO public.authors (id, name, bio, image_url)
VALUES (
  'b2222222-2222-2222-2222-222222222222', 
  'Mishary Rashid Alafasy', 
  'Récitateur de Coran connu.', 
  'https://upload.wikimedia.org/wikipedia/commons/e/e2/Mishary_Rashid_Alafasy.jpg'
) ON CONFLICT (id) DO NOTHING;

-- 1.2 Ensure Podcast Show exists (Le Saint Coran)
INSERT INTO podcast_shows (id, title_fr, title_ar, description_fr, image_url, author_id)
VALUES (
  'c1111111-1111-1111-1111-111111111111', 
  'Le Saint Coran',
  'القرآن الكريم',
  'Récitations du Saint Coran avec transcription et traduction.',
  'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?q=80&w=1000&auto=format&fit=crop',
  'b2222222-2222-2222-2222-222222222222'
) ON CONFLICT (id) DO NOTHING;

-- 1.3 Ensure Teaching (Al-Fatiha) exists and link it correctly
INSERT INTO public.teachings (id, type, author_id, category_id, title_fr, title_ar, description_fr, media_url, thumbnail_url, duration_seconds, published_at, podcast_show_id)
VALUES (
  'f9999999-9999-9999-9999-999999999999',
  'AUDIO',
  'b2222222-2222-2222-2222-222222222222',
  (SELECT id FROM public.categories LIMIT 1),
  'Sourate Al-Fatiha',
  'سورة الفاتحة',
  'La Mère du Livre (Al-Fatiha).',
  'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3',
  'https://i.pinimg.com/736x/8f/c9/78/8fc9781846b027d1433296061386766d.jpg',
  45,
  NOW(),
  'c1111111-1111-1111-1111-111111111111'
)
ON CONFLICT (id) DO UPDATE SET
  podcast_show_id = EXCLUDED.podcast_show_id,
  author_id = EXCLUDED.author_id,
  type = EXCLUDED.type;

-- 1.4 Clean up old transcripts for this teaching to avoid duplicates
DELETE FROM public.transcripts WHERE teaching_id = 'f9999999-9999-9999-9999-999999999999';

-- 1.5 Insert Transcript
INSERT INTO public.transcripts (teaching_id, language, content)
VALUES (
  'f9999999-9999-9999-9999-999999999999',
  'fr',
  '[
    {
      "startTime": 0,
       "endTime": 6000,
       "arabic": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
       "transliteration": "Bismillāhi r-raḥmāni r-raḥīm",
       "translation": "Au nom d''Allah, le Tout Miséricordieux, le Très Miséricordieux."
    },
    {
      "startTime": 6000,
      "endTime": 12000,
      "arabic": "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ",
      "transliteration": "Al-ḥamdu lillāhi rabbi l-ʿālamīn",
      "translation": "Louange à Allah, Seigneur de l''univers."
    },
    {
      "startTime": 12000,
      "endTime": 16000,
      "arabic": "ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
      "transliteration": "Ar-raḥmāni r-raḥīm",
      "translation": "Le Tout Miséricordieux, le Très Miséricordieux,"
    },
    {
      "startTime": 16000,
      "endTime": 20000,
      "arabic": "مَـٰلِكِ يَوْمِ ٱلدِّينِ",
      "transliteration": "Māliki yawmi d-dīn",
      "translation": "Maître du Jour de la Rétribution."
    },
    {
      "startTime": 20000,
      "endTime": 25000,
      "arabic": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
      "transliteration": "Iyyāka naʿbudu waʾiyyāka nastaʿīn",
      "translation": "C''est Toi [Seul] que nous adorons, et c''est Toi [Seul] dont nous implorons secours."
    },
     {
      "startTime": 25000,
      "endTime": 30000,
      "arabic": "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
      "transliteration": "Ihdinā ṣ-ṣirāṭa l-mustaqīm",
      "translation": "Guide-nous dans le droit chemin,"
    },
    {
      "startTime": 30000,
      "endTime": 45000,
      "arabic": "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
      "transliteration": "Ṣirāṭa lladhīna ʾanʿamta ʿalayhim ghayri l-maghḍūbi ʿalayhim wala ḍ-ḍāllīn",
      "translation": "Le chemin de ceux que Tu as comblés de faveurs, non pas de ceux qui ont encouru Ta colère, ni des égarés."
    }
  ]'::jsonb
);
