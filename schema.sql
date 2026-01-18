BEGIN;

-- 1. CONFIGURATION ET EXTENSIONS
-- Nécessaire pour uuid_generate_v4() et gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Nécessaire pour les types géographiques (si utilisé pour 'location')
-- Note : Si vous n'avez pas PostGIS installé, commentez cette ligne et changez le type 'USER-DEFINED' plus bas.
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. GESTION DES DÉPENDANCES EXTERNES (MOCKUP POUR AUTH)
-- Si vous êtes sur Supabase, ce schéma existe déjà. Sinon, on le crée pour éviter les erreurs.
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE,
    encrypted_password text,
    created_at timestamp with time zone DEFAULT now()
);

-- 3. CRÉATION DES TYPES PERSONNALISÉS (ENUMS)
-- Déduits du contexte "USER-DEFINED"
DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('USER', 'ADMIN', 'MODERATOR');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.rhythm_level AS ENUM ('SLOW', 'MEDIUM', 'FAST');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 4. CRÉATION DES TABLES (ORDRE DE DÉPENDANCE)

-- Table indépendante : Spatial Ref Sys (Souvent incluse avec PostGIS)
CREATE TABLE IF NOT EXISTS public.spatial_ref_sys (
    srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
    auth_name character varying,
    auth_srid integer,
    srtext character varying,
    proj4text character varying,
    CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);

-- Table indépendante : Categories
CREATE TABLE IF NOT EXISTS public.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name_fr character varying NOT NULL,
    name_ar character varying NOT NULL,
    slug character varying NOT NULL UNIQUE,
    icon_name character varying,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT categories_pkey PRIMARY KEY (id)
);

-- Table indépendante : Authors
CREATE TABLE IF NOT EXISTS public.authors (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name character varying NOT NULL,
    bio text,
    image_url text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT authors_pkey PRIMARY KEY (id)
);

-- Table : Silsilas (Référence elle-même via parent_id, donc créée tôt)
CREATE TABLE IF NOT EXISTS public.silsilas (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    parent_id uuid,
    level integer NOT NULL DEFAULT 0,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    is_global boolean DEFAULT false,
    image_url text,
    CONSTRAINT silsilas_pkey PRIMARY KEY (id),
    CONSTRAINT silsilas_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.silsilas(id)
);

-- Table : Profiles (Dépend de auth.users et silsilas)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL,
    display_name text NOT NULL,
    email text NOT NULL,
    phone text,
    address text,
    date_of_birth date,
    silsila_id uuid,
    avatar_url text,
    points integer DEFAULT 0 CHECK (points >= 0),
    level integer DEFAULT 1 CHECK (level >= 1),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    role public.user_role NOT NULL DEFAULT 'USER'::user_role,
    CONSTRAINT profiles_pkey PRIMARY KEY (id),
    CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
    CONSTRAINT profiles_silsila_id_fkey FOREIGN KEY (silsila_id) REFERENCES public.silsilas(id)
);

-- Table : Articles (Dépend de authors et categories)
CREATE TABLE IF NOT EXISTS public.articles (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title_fr character varying NOT NULL,
    title_ar character varying NOT NULL,
    content_fr text,
    content_ar text,
    author_id uuid,
    category_id uuid,
    read_time_minutes integer DEFAULT 5,
    views_count bigint DEFAULT 0,
    is_featured boolean DEFAULT false,
    published_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT articles_pkey PRIMARY KEY (id),
    CONSTRAINT articles_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id),
    CONSTRAINT articles_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);

-- Table : Podcast Shows (Dépend de authors et categories)
CREATE TABLE IF NOT EXISTS public.podcast_shows (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title_fr character varying NOT NULL,
    title_ar character varying NOT NULL,
    description_fr text,
    description_ar text,
    image_url text,
    author_id uuid,
    category_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT podcast_shows_pkey PRIMARY KEY (id),
    CONSTRAINT podcast_shows_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id),
    CONSTRAINT podcast_shows_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);

-- Table : Teachings (Dépend de authors, categories et podcast_shows)
CREATE TABLE IF NOT EXISTS public.teachings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title_fr character varying NOT NULL,
    title_ar character varying NOT NULL,
    description_fr text,
    description_ar text,
    type character varying NOT NULL CHECK (type::text = ANY (ARRAY['VIDEO'::character varying, 'AUDIO'::character varying]::text[])),
    media_url text NOT NULL,
    thumbnail_url text,
    duration_seconds integer DEFAULT 0,
    author_id uuid,
    category_id uuid,
    views_count bigint DEFAULT 0,
    is_featured boolean DEFAULT false,
    published_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    podcast_show_id uuid,
    CONSTRAINT teachings_pkey PRIMARY KEY (id),
    CONSTRAINT teachings_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id),
    CONSTRAINT teachings_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
    CONSTRAINT teachings_podcast_show_id_fkey FOREIGN KEY (podcast_show_id) REFERENCES public.podcast_shows(id)
);

-- Table : Transcripts (Dépend de teachings)
CREATE TABLE IF NOT EXISTS public.transcripts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    teaching_id uuid NOT NULL,
    language text DEFAULT 'fr'::text,
    content jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT transcripts_pkey PRIMARY KEY (id),
    CONSTRAINT transcripts_teaching_id_fkey FOREIGN KEY (teaching_id) REFERENCES public.teachings(id)
);

-- Table : Campaigns (Dépend de profiles)
CREATE TABLE IF NOT EXISTS public.campaigns (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    reference text,
    description text,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    created_by uuid NOT NULL,
    category text,
    is_public boolean DEFAULT true,
    access_code text,
    is_weekly boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT campaigns_pkey PRIMARY KEY (id),
    CONSTRAINT campaigns_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

-- Table : Tasks (Dépend de campaigns)
CREATE TABLE IF NOT EXISTS public.tasks (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    campaign_id uuid NOT NULL,
    name text NOT NULL,
    total_number integer NOT NULL CHECK (total_number > 0),
    remaining_number integer NOT NULL CHECK (remaining_number >= 0),
    daily_goal integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT tasks_pkey PRIMARY KEY (id),
    CONSTRAINT tasks_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id)
);

-- Tables Media (Indépendantes ou dépendantes entre elles)
CREATE TABLE IF NOT EXISTS public.media_authors (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    avatar_url text,
    bio text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT media_authors_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.media_categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    rank integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT media_categories_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.media_channels (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    youtube_id text NOT NULL UNIQUE,
    name text NOT NULL,
    thumbnail_url text,
    auto_import boolean DEFAULT true,
    last_scraped_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT media_channels_pkey PRIMARY KEY (id)
);

-- Table : Media Videos (Dépend de channel, author, category)
CREATE TABLE IF NOT EXISTS public.media_videos (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    youtube_id text NOT NULL UNIQUE,
    title text NOT NULL,
    description text,
    duration integer,
    channel_id uuid,
    author_id uuid,
    category_id uuid,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    custom_subtitle_url text,
    status text NOT NULL DEFAULT 'PENDING'::text CHECK (status = ANY (ARRAY['PENDING'::text, 'PUBLISHED'::text, 'ARCHIVED'::text])),
    CONSTRAINT media_videos_pkey PRIMARY KEY (id),
    CONSTRAINT media_videos_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.media_channels(id),
    CONSTRAINT media_videos_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.media_authors(id),
    CONSTRAINT media_videos_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.media_categories(id)
);

-- Table : Silsila Relations (Dépend de silsilas)
CREATE TABLE IF NOT EXISTS public.silsila_relations (
    parent_id uuid NOT NULL,
    child_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT silsila_relations_pkey PRIMARY KEY (parent_id, child_id),
    CONSTRAINT silsila_relations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.silsilas(id),
    CONSTRAINT silsila_relations_child_id_fkey FOREIGN KEY (child_id) REFERENCES public.silsilas(id)
);

-- Table : User Campaigns (Dépend de profiles et campaigns)
CREATE TABLE IF NOT EXISTS public.user_campaigns (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    campaign_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_campaigns_pkey PRIMARY KEY (id),
    CONSTRAINT user_campaigns_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
    CONSTRAINT user_campaigns_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id)
);

-- Table : User Interactions (Dépend de auth.users)
CREATE TABLE IF NOT EXISTS public.user_interactions (
    user_id uuid NOT NULL,
    item_id uuid NOT NULL,
    item_type character varying NOT NULL CHECK (item_type::text = ANY (ARRAY['TEACHING'::character varying, 'ARTICLE'::character varying, 'PODCAST_SHOW'::character varying]::text[])),
    is_favorite boolean DEFAULT false,
    last_position_seconds integer DEFAULT 0,
    last_read_percentage integer DEFAULT 0,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_interactions_pkey PRIMARY KEY (user_id, item_id, item_type),
    CONSTRAINT user_interactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Table : User Tasks (Dépend de profiles et tasks)
CREATE TABLE IF NOT EXISTS public.user_tasks (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    task_id uuid NOT NULL,
    subscribed_quantity integer NOT NULL CHECK (subscribed_quantity > 0),
    completed_quantity integer DEFAULT 0 CHECK (completed_quantity >= 0),
    is_completed boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    CONSTRAINT user_tasks_pkey PRIMARY KEY (id),
    CONSTRAINT user_tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
    CONSTRAINT user_tasks_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);

-- Table : Wazifa Gatherings (Dépend de profiles)
-- Note: 'location' est défini ici comme GEOGRAPHY. Si pas de PostGIS, changez en TEXT.
CREATE TABLE IF NOT EXISTS public.wazifa_gatherings (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    description text,
    address text,
    location public.geometry, -- Assumant PostGIS
    rhythm public.rhythm_level DEFAULT 'MEDIUM'::rhythm_level,
    schedule_morning time without time zone,
    schedule_evening time without time zone,
    contact_phone text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    status text NOT NULL DEFAULT 'PENDING'::text,
    CONSTRAINT wazifa_gatherings_pkey PRIMARY KEY (id),
    CONSTRAINT wazifa_gatherings_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

COMMIT;
