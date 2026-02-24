-- ════════════════════════════════════════════════════════════════════════
-- Migration 027: Create courses table for in-app calendar
-- ════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  teacher_name text,
  start_time timestamptz NOT NULL,
  duration_minutes int DEFAULT 60,
  telegram_link text,
  recurrence text DEFAULT 'once' CHECK (recurrence IN ('once', 'weekly', 'daily')),
  recurrence_day int CHECK (recurrence_day >= 0 AND recurrence_day <= 6),
  color text DEFAULT '#009688',
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index pour les requêtes par date
CREATE INDEX idx_courses_start_time ON public.courses(start_time);
CREATE INDEX idx_courses_active ON public.courses(is_active) WHERE is_active = true;

-- RLS
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut lire les cours actifs
CREATE POLICY "courses_read_all" ON public.courses
  FOR SELECT USING (is_active = true);

-- Seul le créateur (admin) peut insérer / modifier / supprimer
CREATE POLICY "courses_insert_auth" ON public.courses
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "courses_update_own" ON public.courses
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "courses_delete_own" ON public.courses
  FOR DELETE USING (auth.uid() = created_by);
