-- 1. Insert Author (Reciter) if not exists (Generic Reciter for Demo)
INSERT INTO public.authors (id, name, bio, image_url)
VALUES (
  'b2222222-2222-2222-2222-222222222222', 
  'Mishary Rashid Alafasy', 
  'Récitateur de Coran connu.', 
  'https://upload.wikimedia.org/wikipedia/commons/e/e2/Mishary_Rashid_Alafasy.jpg'
) ON CONFLICT (id) DO NOTHING;

-- 2. Insert Teaching (Surah Al-Fatiha MP3)
INSERT INTO public.teachings (id, type, author_id, category_id, title_fr, title_ar, description_fr, media_url, thumbnail_url, duration_seconds, published_at)
VALUES (
  'f9999999-9999-9999-9999-999999999999',
  'AUDIO',
  'b2222222-2222-2222-2222-222222222222',
  (SELECT id FROM public.categories LIMIT 1), -- Any category
  'Sourate Al-Fatiha',
  'سورة الفاتحة',
  'La Mère du Livre (Al-Fatiha). Récitation pour démonstration.',
  'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3', -- Public Domain Quran MP3
  'https://i.pinimg.com/736x/8f/c9/78/8fc9781846b027d1433296061386766d.jpg', -- Quran Calligraphy
  45, -- Approx 45 seconds
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 3. Insert Real Transcript (JSON)
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
