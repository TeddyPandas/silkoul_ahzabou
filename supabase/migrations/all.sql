-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.article_likes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  article_id uuid NOT NULL,
  user_id uuid NOT NULL,
  liked_at timestamp with time zone DEFAULT now(),
  CONSTRAINT article_likes_pkey PRIMARY KEY (id),
  CONSTRAINT article_likes_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.tijani_articles(id),
  CONSTRAINT article_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.badges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text UNIQUE,
  description text,
  image_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT badges_pkey PRIMARY KEY (id)
);
CREATE TABLE public.campaigns (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  created_by uuid,
  category text,
  access_code text,
  is_public boolean DEFAULT true,
  is_weekly boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  reference text,
  is_finished boolean DEFAULT false,
  CONSTRAINT campaigns_pkey PRIMARY KEY (id),
  CONSTRAINT campaigns_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.guennoun_authors (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  name_ar text,
  title text,
  title_ar text,
  biography text,
  biography_ar text,
  image_url text,
  is_primary boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_authors_pkey PRIMARY KEY (id)
);
CREATE TABLE public.guennoun_bookmarks (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  text_id uuid NOT NULL,
  position integer DEFAULT 0,
  scroll_percentage real DEFAULT 0,
  note text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_bookmarks_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT guennoun_bookmarks_text_id_fkey FOREIGN KEY (text_id) REFERENCES public.guennoun_texts(id)
);
CREATE TABLE public.guennoun_categories (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  type USER-DEFINED NOT NULL UNIQUE,
  name_fr text NOT NULL,
  name_ar text NOT NULL,
  description text,
  icon text NOT NULL,
  color text NOT NULL,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.guennoun_favorites (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  content_type USER-DEFINED NOT NULL,
  video_id uuid,
  text_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  podcast_id uuid,
  CONSTRAINT guennoun_favorites_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_favorites_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES public.guennoun_podcasts(id),
  CONSTRAINT guennoun_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT guennoun_favorites_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.guennoun_videos(id),
  CONSTRAINT guennoun_favorites_text_id_fkey FOREIGN KEY (text_id) REFERENCES public.guennoun_texts(id)
);
CREATE TABLE public.guennoun_podcast_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  podcast_id uuid NOT NULL,
  position integer NOT NULL DEFAULT 0,
  duration integer,
  is_completed boolean DEFAULT false,
  completed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_podcast_progress_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_podcast_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT guennoun_podcast_progress_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES public.guennoun_podcasts(id)
);
CREATE TABLE public.guennoun_podcasts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  title_ar text,
  description text,
  description_ar text,
  audio_url text NOT NULL,
  duration integer,
  file_size integer,
  image_url text,
  episode_number integer,
  season_number integer DEFAULT 1,
  author_id uuid,
  category_type USER-DEFINED NOT NULL DEFAULT 'enseignement'::guennoun_category_type,
  related_video_id uuid,
  related_text_id uuid,
  tags ARRAY DEFAULT '{}'::text[],
  is_premium boolean DEFAULT false,
  is_published boolean DEFAULT true,
  published_at timestamp with time zone,
  play_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_podcasts_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_podcasts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.guennoun_authors(id),
  CONSTRAINT guennoun_podcasts_related_video_id_fkey FOREIGN KEY (related_video_id) REFERENCES public.guennoun_videos(id),
  CONSTRAINT guennoun_podcasts_related_text_id_fkey FOREIGN KEY (related_text_id) REFERENCES public.guennoun_texts(id)
);
CREATE TABLE public.guennoun_texts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  title_ar text,
  description text,
  description_ar text,
  content_fr text,
  content_ar text,
  video_url text,
  external_url text,
  image_url text,
  author_id uuid,
  category_type USER-DEFINED NOT NULL DEFAULT 'enseignement'::guennoun_category_type,
  source text,
  reference text,
  tags ARRAY DEFAULT '{}'::text[],
  is_premium boolean DEFAULT false,
  is_published boolean DEFAULT true,
  reading_time integer,
  published_at timestamp with time zone DEFAULT now(),
  view_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_texts_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_texts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.guennoun_authors(id)
);
CREATE TABLE public.guennoun_videos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  title_ar text,
  description text,
  description_ar text,
  url text NOT NULL,
  platform USER-DEFINED NOT NULL DEFAULT 'youtube'::video_platform,
  video_id text,
  thumbnail_url text,
  duration integer,
  author_id uuid,
  category_type USER-DEFINED NOT NULL DEFAULT 'enseignement'::guennoun_category_type,
  tags ARRAY DEFAULT '{}'::text[],
  is_premium boolean DEFAULT false,
  is_published boolean DEFAULT true,
  published_at timestamp with time zone DEFAULT now(),
  view_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT guennoun_videos_pkey PRIMARY KEY (id),
  CONSTRAINT guennoun_videos_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.guennoun_authors(id)
);
CREATE TABLE public.lineage_path (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  lineage_id uuid NOT NULL,
  sheikh_id uuid NOT NULL,
  position integer NOT NULL CHECK ("position" >= 0),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT lineage_path_pkey PRIMARY KEY (id),
  CONSTRAINT lineage_path_lineage_id_fkey FOREIGN KEY (lineage_id) REFERENCES public.user_lineages(id),
  CONSTRAINT lineage_path_sheikh_id_fkey FOREIGN KEY (sheikh_id) REFERENCES public.sheikhs(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  display_name text,
  created_at timestamp with time zone DEFAULT now(),
  email text,
  phone text,
  address text,
  date_of_birth date,
  silsila_id uuid,
  avatar_url text,
  points integer DEFAULT 0,
  level integer DEFAULT 1,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.sheikh_lineage (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  teacher_id uuid NOT NULL,
  disciple_id uuid NOT NULL,
  lineage_name text,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sheikh_lineage_pkey PRIMARY KEY (id),
  CONSTRAINT sheikh_lineage_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.sheikhs(id),
  CONSTRAINT sheikh_lineage_disciple_id_fkey FOREIGN KEY (disciple_id) REFERENCES public.sheikhs(id)
);
CREATE TABLE public.sheikhs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  arabic_name text,
  title text,
  biography text,
  short_bio text,
  birth_date date,
  birth_date_hijri text,
  death_date date,
  death_date_hijri text,
  birth_place text,
  death_place text,
  image_url text,
  user_id uuid,
  is_root boolean DEFAULT false,
  level integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sheikhs_pkey PRIMARY KEY (id),
  CONSTRAINT sheikhs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.silsila_lineage (
  silsila_id uuid NOT NULL,
  teacher_id uuid NOT NULL,
  student_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT silsila_lineage_pkey PRIMARY KEY (silsila_id, teacher_id, student_id),
  CONSTRAINT silsila_lineage_student_id_fkey FOREIGN KEY (student_id) REFERENCES auth.users(id),
  CONSTRAINT silsila_lineage_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES auth.users(id)
);
CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);
CREATE TABLE public.tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  campaign_id uuid,
  name text NOT NULL,
  total_number integer NOT NULL,
  remaining_number integer NOT NULL,
  daily_goal integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tasks_pkey PRIMARY KEY (id),
  CONSTRAINT tasks_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id)
);
CREATE TABLE public.tijani_articles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  title_ar text NOT NULL,
  content text NOT NULL,
  content_ar text NOT NULL,
  summary text NOT NULL,
  summary_ar text NOT NULL,
  category text NOT NULL CHECK (category = ANY (ARRAY['teaching'::text, 'biography'::text, 'litany'::text, 'story'::text, 'fatwa'::text, 'poem'::text, 'dhikr'::text, 'dua'::text, 'wisdom'::text, 'history'::text])),
  author_id uuid NOT NULL,
  author_name text NOT NULL,
  author_name_ar text,
  image_url text,
  tags ARRAY DEFAULT '{}'::text[],
  tags_ar ARRAY DEFAULT '{}'::text[],
  silsila_reference text,
  source text,
  source_ar text,
  published_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  view_count integer DEFAULT 0 CHECK (view_count >= 0),
  like_count integer DEFAULT 0 CHECK (like_count >= 0),
  share_count integer DEFAULT 0 CHECK (share_count >= 0),
  is_featured boolean DEFAULT false,
  is_verified boolean DEFAULT false,
  status text DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'review'::text, 'published'::text, 'archived'::text])),
  difficulty_level text CHECK (difficulty_level = ANY (ARRAY['beginner'::text, 'intermediate'::text, 'advanced'::text, 'scholar'::text])),
  estimated_read_time integer DEFAULT 5,
  related_article_ids ARRAY DEFAULT '{}'::uuid[],
  metadata jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT tijani_articles_pkey PRIMARY KEY (id),
  CONSTRAINT tijani_articles_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_badges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  badge_id uuid,
  earned_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_badges_pkey PRIMARY KEY (id),
  CONSTRAINT user_badges_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(id),
  CONSTRAINT user_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_campaigns (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  campaign_id uuid,
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_campaigns_pkey PRIMARY KEY (id),
  CONSTRAINT user_campaigns_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_campaigns_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id)
);
CREATE TABLE public.user_lineages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  direct_teacher_id uuid NOT NULL,
  lineage_name text,
  is_primary boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_lineages_pkey PRIMARY KEY (id),
  CONSTRAINT user_lineages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_lineages_direct_teacher_id_fkey FOREIGN KEY (direct_teacher_id) REFERENCES public.sheikhs(id)
);
CREATE TABLE public.user_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  task_id uuid,
  subscribed_quantity integer CHECK (subscribed_quantity > 0),
  completed_quantity integer DEFAULT 0 CHECK (completed_quantity >= 0),
  completed_at timestamp with time zone,
  is_completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT user_tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_tasks_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);
CREATE TABLE public.wazifa_places (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  photo_url text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  address text,
  created_by uuid,
  type USER-DEFINED DEFAULT 'Zawyia'::wazifa_place_type,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT wazifa_places_pkey PRIMARY KEY (id),
  CONSTRAINT wazifa_places_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);