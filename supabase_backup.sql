

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."task_subscription" AS (
	"task_id" "uuid",
	"quantity" integer
);


ALTER TYPE "public"."task_subscription" OWNER TO "postgres";


CREATE TYPE "public"."wazifa_place_type" AS ENUM (
    'Zawyia',
    'Ziara'
);


ALTER TYPE "public"."wazifa_place_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_award_badges"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  total_completed INTEGER;
  streak INTEGER;
  badge_record RECORD;
BEGIN
  -- Award badges based on total completed tasks
  SELECT COUNT(*) INTO total_completed FROM public.user_tasks WHERE user_id = NEW.user_id AND is_completed = true;

  IF total_completed >= 10 THEN
    SELECT id INTO badge_record FROM public.badges WHERE name = '10 Tasks Completed';
    IF FOUND AND NOT EXISTS (SELECT 1 FROM public.user_badges WHERE user_id = NEW.user_id AND badge_id = badge_record.id) THEN
      INSERT INTO public.user_badges (user_id, badge_id) VALUES (NEW.user_id, badge_record.id);
    END IF;
  END IF;

  IF total_completed >= 50 THEN
    SELECT id INTO badge_record FROM public.badges WHERE name = '50 Tasks Completed';
    IF FOUND AND NOT EXISTS (SELECT 1 FROM public.user_badges WHERE user_id = NEW.user_id AND badge_id = badge_record.id) THEN
      INSERT INTO public.user_badges (user_id, badge_id) VALUES (NEW.user_id, badge_record.id);
    END IF;
  END IF;

  -- Award badges based on streaks (consecutive days of completions)
  WITH daily_completions AS (
    SELECT DISTINCT DATE(completed_at) AS completion_date
    FROM public.user_tasks
    WHERE user_id = NEW.user_id AND completed_at IS NOT NULL
  ), streaks AS (
    SELECT completion_date, (completion_date - CAST(ROW_NUMBER() OVER (ORDER BY completion_date) AS integer)) AS streak_group
    FROM daily_completions
  )
  SELECT COUNT(*) INTO streak
  FROM streaks
  WHERE streak_group = (SELECT streak_group FROM streaks ORDER BY completion_date DESC LIMIT 1);

  IF NOT EXISTS (SELECT 1 FROM daily_completions WHERE completion_date >= CURRENT_DATE - INTERVAL '1 day') THEN
    streak := 0;
  END IF;

  IF streak >= 7 THEN
    SELECT id INTO badge_record FROM public.badges WHERE name = '7 Day Streak';
    IF FOUND AND NOT EXISTS (SELECT 1 FROM public.user_badges WHERE user_id = NEW.user_id AND badge_id = badge_record.id) THEN
      INSERT INTO public.user_badges (user_id, badge_id) VALUES (NEW.user_id, badge_record.id);
    END IF;
  END IF;

  IF streak >= 30 THEN
    SELECT id INTO badge_record FROM public.badges WHERE name = '30 Day Streak';
    IF FOUND AND NOT EXISTS (SELECT 1 FROM public.user_badges WHERE user_id = NEW.user_id AND badge_id = badge_record.id) THEN
      INSERT INTO public.user_badges (user_id, badge_id) VALUES (NEW.user_id, badge_record.id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_and_award_badges"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_task_quota"("task_id_to_check" "uuid", "quantity_to_take" integer) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    remaining INTEGER;
BEGIN
    -- Use SELECT ... FOR UPDATE to lock the row, preventing race conditions.
    SELECT remaining_number INTO remaining FROM public.tasks WHERE id = task_id_to_check FOR UPDATE;
    RETURN remaining >= quantity_to_take;
END;
$$;


ALTER FUNCTION "public"."check_task_quota"("task_id_to_check" "uuid", "quantity_to_take" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (new.id, new.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_task_subscription_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.tasks SET remaining_number = remaining_number - NEW.subscribed_quantity WHERE id = NEW.task_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.tasks SET remaining_number = remaining_number + OLD.subscribed_quantity WHERE id = OLD.task_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Handle changes in subscribed quantity
        IF OLD.subscribed_quantity <> NEW.subscribed_quantity THEN
             UPDATE public.tasks SET remaining_number = remaining_number + OLD.subscribed_quantity - NEW.subscribed_quantity WHERE id = NEW.task_id;
        END IF;
        -- Automatically update the is_completed flag
        IF NEW.completed_quantity >= NEW.subscribed_quantity THEN
            NEW.is_completed := true;
        ELSE
            NEW.is_completed := false;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."handle_task_subscription_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."join_campaign"("p_campaign_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO public.user_campaigns (user_id, campaign_id)
    VALUES (auth.uid(), p_campaign_id) ON CONFLICT DO NOTHING;
END;
$$;


ALTER FUNCTION "public"."join_campaign"("p_campaign_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_and_subscribe"("p_user_id" "uuid", "p_campaign_id" "uuid", "p_tasks" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
            RAISE EXCEPTION 'Insufficient quantity available for task %', task_uuid;
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

    -- 5. Ajouter des points à l'utilisateur (s'il y a une colonne points)
    UPDATE public.profiles
    SET points = COALESCE(points, 0) + 10
    WHERE id = p_user_id;

END;
$$;


ALTER FUNCTION "public"."register_and_subscribe"("p_user_id" "uuid", "p_campaign_id" "uuid", "p_tasks" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_task_completion_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        NEW.completed_at = NOW();
    ELSIF NEW.is_completed = false AND OLD.is_completed = true THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_task_completion_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."subscribe_to_tasks"("subscriptions" "public"."task_subscription"[]) RETURNS json
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    sub task_subscription;
BEGIN
    FOREACH sub IN ARRAY subscriptions
    LOOP
        INSERT INTO public.user_tasks (user_id, task_id, subscribed_quantity)
        VALUES (auth.uid(), sub.task_id, sub.quantity)
        ON CONFLICT (user_id, task_id) DO UPDATE
        SET subscribed_quantity = public.user_tasks.subscribed_quantity + EXCLUDED.subscribed_quantity;
    END LOOP;
    RETURN json_build_object('status', 'success', 'message', 'Tasks subscribed successfully.');
EXCEPTION
    WHEN check_violation THEN
        RAISE EXCEPTION 'Subscription failed. The requested quantity exceeds the available quota for a task.';
    WHEN OTHERS THEN
        RAISE;
END;
$$;


ALTER FUNCTION "public"."subscribe_to_tasks"("subscriptions" "public"."task_subscription"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_task_progress"("p_user_task_id" "uuid", "p_completed_quantity" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.user_tasks
    SET completed_quantity = p_completed_quantity
    WHERE id = p_user_task_id AND user_id = auth.uid();
END;
$$;


ALTER FUNCTION "public"."update_task_progress"("p_user_task_id" "uuid", "p_completed_quantity" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_weekly_campaigns"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  campaign_record RECORD;
BEGIN
  FOR campaign_record IN
    SELECT * FROM public.campaigns
    WHERE is_weekly = true AND end_date < CURRENT_DATE
  LOOP
    UPDATE public.campaigns
    SET start_date = campaign_record.end_date + INTERVAL '1 day', end_date = campaign_record.end_date + INTERVAL '8 days'
    WHERE id = campaign_record.id;
    UPDATE public.tasks
    SET remaining_number = total_number
    WHERE campaign_id = campaign_record.id;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."update_weekly_campaigns"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "description" "text",
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaigns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "created_by" "uuid",
    "category" "text",
    "access_code" "text",
    "is_public" boolean DEFAULT true,
    "is_weekly" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "reference" "text"
);


ALTER TABLE "public"."campaigns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "display_name" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "email" "text",
    "phone" "text",
    "address" "text",
    "date_of_birth" "date",
    "silsila_id" "uuid",
    "avatar_url" "text",
    "points" integer DEFAULT 0,
    "level" integer DEFAULT 1,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."silsila_lineage" (
    "silsila_id" "uuid" NOT NULL,
    "teacher_id" "uuid" NOT NULL,
    "student_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."silsila_lineage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."silsilas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "owner_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "parent_id" "uuid",
    "level" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."silsilas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "campaign_id" "uuid",
    "name" "text" NOT NULL,
    "total_number" integer NOT NULL,
    "remaining_number" integer NOT NULL,
    "daily_goal" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_remaining" CHECK (("remaining_number" <= "total_number"))
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "badge_id" "uuid",
    "earned_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_campaigns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "campaign_id" "uuid",
    "joined_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_campaigns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "task_id" "uuid",
    "subscribed_quantity" integer,
    "completed_quantity" integer DEFAULT 0,
    "completed_at" timestamp with time zone,
    "is_completed" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_tasks_completed_quantity_check" CHECK (("completed_quantity" >= 0)),
    CONSTRAINT "user_tasks_subscribed_quantity_check" CHECK (("subscribed_quantity" > 0)),
    CONSTRAINT "valid_completed" CHECK (("completed_quantity" <= "subscribed_quantity"))
);


ALTER TABLE "public"."user_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wazifa_places" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "photo_url" "text",
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "address" "text",
    "created_by" "uuid",
    "type" "public"."wazifa_place_type" DEFAULT 'Zawyia'::"public"."wazifa_place_type",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wazifa_places" OWNER TO "postgres";


ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."silsila_lineage"
    ADD CONSTRAINT "silsila_lineage_pkey" PRIMARY KEY ("silsila_id", "teacher_id", "student_id");



ALTER TABLE ONLY "public"."silsilas"
    ADD CONSTRAINT "silsilas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_campaigns"
    ADD CONSTRAINT "user_campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_campaigns"
    ADD CONSTRAINT "user_campaigns_user_id_campaign_id_key" UNIQUE ("user_id", "campaign_id");



ALTER TABLE ONLY "public"."user_tasks"
    ADD CONSTRAINT "user_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_tasks"
    ADD CONSTRAINT "user_tasks_user_id_task_id_key" UNIQUE ("user_id", "task_id");



ALTER TABLE ONLY "public"."wazifa_places"
    ADD CONSTRAINT "wazifa_places_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "update_campaigns_updated_at" BEFORE UPDATE ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_tasks_updated_at" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_tasks_updated_at" BEFORE UPDATE ON "public"."user_tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_silsila_id_fkey" FOREIGN KEY ("silsila_id") REFERENCES "public"."silsilas"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."silsila_lineage"
    ADD CONSTRAINT "silsila_lineage_silsila_id_fkey" FOREIGN KEY ("silsila_id") REFERENCES "public"."silsilas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."silsila_lineage"
    ADD CONSTRAINT "silsila_lineage_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."silsila_lineage"
    ADD CONSTRAINT "silsila_lineage_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."silsilas"
    ADD CONSTRAINT "silsilas_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."silsilas"
    ADD CONSTRAINT "silsilas_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."silsilas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_campaigns"
    ADD CONSTRAINT "user_campaigns_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_campaigns"
    ADD CONSTRAINT "user_campaigns_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_tasks"
    ADD CONSTRAINT "user_tasks_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_tasks"
    ADD CONSTRAINT "user_tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wazifa_places"
    ADD CONSTRAINT "wazifa_places_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE "public"."badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaigns" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "campaigns_delete_creator" ON "public"."campaigns" FOR DELETE USING (("created_by" = "auth"."uid"()));



CREATE POLICY "campaigns_insert_authenticated" ON "public"."campaigns" FOR INSERT WITH CHECK ((("auth"."uid"() IS NOT NULL) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "campaigns_select_public_or_member" ON "public"."campaigns" FOR SELECT USING ((("is_public" = true) OR ("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."user_campaigns"
  WHERE (("user_campaigns"."campaign_id" = "campaigns"."id") AND ("user_campaigns"."user_id" = "auth"."uid"()))))));



CREATE POLICY "campaigns_update_creator" ON "public"."campaigns" FOR UPDATE USING (("created_by" = "auth"."uid"())) WITH CHECK (("created_by" = "auth"."uid"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_delete_own" ON "public"."profiles" FOR DELETE USING (("auth"."uid"() = "id"));



CREATE POLICY "profiles_insert_own" ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "profiles_select_all" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



ALTER TABLE "public"."silsila_lineage" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."silsilas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "silsilas_select_all" ON "public"."silsilas" FOR SELECT USING (true);



ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tasks_delete_via_campaign" ON "public"."tasks" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."campaigns"
  WHERE (("campaigns"."id" = "tasks"."campaign_id") AND ("campaigns"."created_by" = "auth"."uid"())))));



CREATE POLICY "tasks_insert_via_campaign" ON "public"."tasks" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."campaigns"
  WHERE (("campaigns"."id" = "tasks"."campaign_id") AND ("campaigns"."created_by" = "auth"."uid"())))));



CREATE POLICY "tasks_select_via_campaign" ON "public"."tasks" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."campaigns"
  WHERE (("campaigns"."id" = "tasks"."campaign_id") AND (("campaigns"."is_public" = true) OR ("campaigns"."created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
           FROM "public"."user_campaigns"
          WHERE (("user_campaigns"."campaign_id" = "campaigns"."id") AND ("user_campaigns"."user_id" = "auth"."uid"())))))))));



CREATE POLICY "tasks_update_disabled" ON "public"."tasks" FOR UPDATE USING (false);



ALTER TABLE "public"."user_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_campaigns" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_campaigns_delete_own" ON "public"."user_campaigns" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_campaigns_insert_disabled" ON "public"."user_campaigns" FOR INSERT WITH CHECK (false);



CREATE POLICY "user_campaigns_select_own" ON "public"."user_campaigns" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_campaigns_update_disabled" ON "public"."user_campaigns" FOR UPDATE USING (false);



ALTER TABLE "public"."user_tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_tasks_delete_own" ON "public"."user_tasks" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_tasks_insert_disabled" ON "public"."user_tasks" FOR INSERT WITH CHECK (false);



CREATE POLICY "user_tasks_select_own" ON "public"."user_tasks" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_tasks_update_own" ON "public"."user_tasks" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."wazifa_places" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."check_and_award_badges"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_and_award_badges"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_and_award_badges"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_task_quota"("task_id_to_check" "uuid", "quantity_to_take" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."check_task_quota"("task_id_to_check" "uuid", "quantity_to_take" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_task_quota"("task_id_to_check" "uuid", "quantity_to_take" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_task_subscription_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_task_subscription_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_task_subscription_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."join_campaign"("p_campaign_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."join_campaign"("p_campaign_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_campaign"("p_campaign_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."register_and_subscribe"("p_user_id" "uuid", "p_campaign_id" "uuid", "p_tasks" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."register_and_subscribe"("p_user_id" "uuid", "p_campaign_id" "uuid", "p_tasks" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_and_subscribe"("p_user_id" "uuid", "p_campaign_id" "uuid", "p_tasks" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_task_completion_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_task_completion_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_task_completion_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."subscribe_to_tasks"("subscriptions" "public"."task_subscription"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."subscribe_to_tasks"("subscriptions" "public"."task_subscription"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subscribe_to_tasks"("subscriptions" "public"."task_subscription"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_task_progress"("p_user_task_id" "uuid", "p_completed_quantity" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."update_task_progress"("p_user_task_id" "uuid", "p_completed_quantity" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_task_progress"("p_user_task_id" "uuid", "p_completed_quantity" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_weekly_campaigns"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_weekly_campaigns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_weekly_campaigns"() TO "service_role";



GRANT ALL ON TABLE "public"."badges" TO "anon";
GRANT ALL ON TABLE "public"."badges" TO "authenticated";
GRANT ALL ON TABLE "public"."badges" TO "service_role";



GRANT ALL ON TABLE "public"."campaigns" TO "anon";
GRANT ALL ON TABLE "public"."campaigns" TO "authenticated";
GRANT ALL ON TABLE "public"."campaigns" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."silsila_lineage" TO "anon";
GRANT ALL ON TABLE "public"."silsila_lineage" TO "authenticated";
GRANT ALL ON TABLE "public"."silsila_lineage" TO "service_role";



GRANT ALL ON TABLE "public"."silsilas" TO "anon";
GRANT ALL ON TABLE "public"."silsilas" TO "authenticated";
GRANT ALL ON TABLE "public"."silsilas" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."user_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_badges" TO "service_role";



GRANT ALL ON TABLE "public"."user_campaigns" TO "anon";
GRANT ALL ON TABLE "public"."user_campaigns" TO "authenticated";
GRANT ALL ON TABLE "public"."user_campaigns" TO "service_role";



GRANT ALL ON TABLE "public"."user_tasks" TO "anon";
GRANT ALL ON TABLE "public"."user_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."user_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."wazifa_places" TO "anon";
GRANT ALL ON TABLE "public"."wazifa_places" TO "authenticated";
GRANT ALL ON TABLE "public"."wazifa_places" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






