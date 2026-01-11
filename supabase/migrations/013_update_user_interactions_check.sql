-- Migration to allow following Podcast Shows in user_interactions
-- File: supabase/migrations/013_update_user_interactions_check.sql

-- Drop the existing check constraint
ALTER TABLE user_interactions
DROP CONSTRAINT user_interactions_item_type_check;

-- Add the new check constraint including 'PODCAST_SHOW'
ALTER TABLE user_interactions
ADD CONSTRAINT user_interactions_item_type_check
CHECK (item_type IN ('TEACHING', 'ARTICLE', 'PODCAST_SHOW'));
