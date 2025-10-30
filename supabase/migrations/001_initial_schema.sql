-- ============================================
-- SILKOUL AHZABOU TIDIANI - DATABASE SCHEMA
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: silsilas (Généalogie spirituelle)
-- ============================================
CREATE TABLE IF NOT EXISTS public.silsilas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    parent_id UUID REFERENCES public.silsilas(id) ON DELETE CASCADE,
    level INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_silsilas_parent ON public.silsilas(parent_id);
CREATE INDEX idx_silsilas_level ON public.silsilas(level);

-- ============================================
-- TABLE: profiles (Profils utilisateurs)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    date_of_birth DATE,
    silsila_id UUID REFERENCES public.silsilas(id) ON DELETE SET NULL,
    avatar_url TEXT,
    points INTEGER DEFAULT 0 CHECK (points >= 0),
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_silsila ON public.profiles(silsila_id);

-- ============================================
-- TABLE: campaigns (Campagnes de Zikr)
-- ============================================
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    reference TEXT,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    access_code TEXT,
    is_weekly BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_dates CHECK (end_date > start_date)
);

CREATE INDEX idx_campaigns_created_by ON public.campaigns(created_by);
CREATE INDEX idx_campaigns_category ON public.campaigns(category);
CREATE INDEX idx_campaigns_is_public ON public.campaigns(is_public);
CREATE INDEX idx_campaigns_dates ON public.campaigns(start_date, end_date);

-- ============================================
-- TABLE: tasks (Tâches de Zikr)
-- ============================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    total_number INTEGER NOT NULL CHECK (total_number > 0),
    remaining_number INTEGER NOT NULL CHECK (remaining_number >= 0),
    daily_goal INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_remaining CHECK (remaining_number <= total_number)
);

CREATE INDEX idx_tasks_campaign ON public.tasks(campaign_id);

-- ============================================
-- TABLE: user_campaigns (Souscriptions)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, campaign_id)
);

CREATE INDEX idx_user_campaigns_user ON public.user_campaigns(user_id);
CREATE INDEX idx_user_campaigns_campaign ON public.user_campaigns(campaign_id);

-- ============================================
-- TABLE: user_tasks (Engagements utilisateur)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    subscribed_quantity INTEGER NOT NULL CHECK (subscribed_quantity > 0),
    completed_quantity INTEGER DEFAULT 0 CHECK (completed_quantity >= 0),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_completed CHECK (completed_quantity <= subscribed_quantity),
    UNIQUE(user_id, task_id)
);

CREATE INDEX idx_user_tasks_user ON public.user_tasks(user_id);
CREATE INDEX idx_user_tasks_task ON public.user_tasks(task_id);
CREATE INDEX idx_user_tasks_completed ON public.user_tasks(is_completed);

-- ============================================
-- TRIGGERS: Auto-update timestamps
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at
    BEFORE UPDATE ON public.campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_tasks_updated_at
    BEFORE UPDATE ON public.user_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RPC FUNCTION: register_and_subscribe
-- Cette fonction garantit l'atomicité lors de l'abonnement
-- ============================================

CREATE OR REPLACE FUNCTION register_and_subscribe(
    p_user_id UUID,
    p_campaign_id UUID,
    p_tasks JSONB
)
RETURNS VOID AS $$
DECLARE
    task_item JSONB;
    task_uuid UUID;
    task_quantity INTEGER;
    current_remaining INTEGER;
BEGIN
    -- 1. Vérifier que la campagne existe
    IF NOT EXISTS (SELECT 1 FROM public.campaigns WHERE id = p_campaign_id) THEN
        RAISE EXCEPTION 'Campaign not found';
    END IF;

    -- 2. Vérifier que l'utilisateur n'est pas déjà abonné
    IF EXISTS (
        SELECT 1 FROM public.user_campaigns 
        WHERE user_id = p_user_id AND campaign_id = p_campaign_id
    ) THEN
        RAISE EXCEPTION 'User already subscribed to this campaign';
    END IF;

    -- 3. Créer l'entrée user_campaigns
    INSERT INTO public.user_campaigns (user_id, campaign_id)
    VALUES (p_user_id, p_campaign_id);

    -- 4. Traiter chaque tâche sélectionnée
    FOR task_item IN SELECT * FROM jsonb_array_elements(p_tasks)
    LOOP
        task_uuid := (task_item->>'task_id')::UUID;
        task_quantity := (task_item->>'quantity')::INTEGER;

        -- Vérifier que la tâche existe et appartient à la campagne
        SELECT remaining_number INTO current_remaining
        FROM public.tasks
        WHERE id = task_uuid AND campaign_id = p_campaign_id
        FOR UPDATE; -- Lock pour éviter race conditions

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Task not found or does not belong to campaign';
        END IF;

        -- Vérifier qu'il reste assez de quantité disponible
        IF current_remaining < task_quantity THEN
            RAISE EXCEPTION 'Not enough remaining quantity for task %', task_uuid;
        END IF;

        -- Décrémenter atomiquement le remaining_number
        UPDATE public.tasks
        SET remaining_number = remaining_number - task_quantity
        WHERE id = task_uuid;

        -- Créer l'entrée user_tasks
        INSERT INTO public.user_tasks (
            user_id, 
            task_id, 
            subscribed_quantity
        )
        VALUES (
            p_user_id,
            task_uuid,
            task_quantity
        );
    END LOOP;

    -- 5. Ajouter des points à l'utilisateur
    UPDATE public.profiles
    SET points = points + 10
    WHERE id = p_user_id;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Fonction pour insérer des données de test (optionnel)
-- ============================================

CREATE OR REPLACE FUNCTION insert_test_data()
RETURNS VOID AS $$
BEGIN
    -- Insérer une silsila racine
    INSERT INTO public.silsilas (name, level, description)
    VALUES ('Tariqa Tijaniyya', 0, 'Chaîne principale de la Tariqa Tijaniyya')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Appeler la fonction pour insérer les données de test
SELECT insert_test_data();
