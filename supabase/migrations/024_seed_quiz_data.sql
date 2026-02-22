-- Function to seed quiz data
CREATE OR REPLACE FUNCTION seed_quiz_data()
RETURNS VOID AS $$
DECLARE
    v_quiz_fiqh_id UUID;
    v_quiz_sirah_id UUID;
    v_quiz_tariqa_id UUID;
    v_q1_id UUID;
    v_q2_id UUID;
    v_q3_id UUID;
    v_q4_id UUID;
    v_q5_id UUID;
    v_q6_id UUID;
BEGIN
    -- 1. Create Fiqh Quiz
    IF NOT EXISTS (SELECT 1 FROM quizzes WHERE title = 'Les Piliers de l''Islam' AND category = 'Fiqh') THEN
        INSERT INTO quizzes (title, description, category, difficulty, image_url)
        VALUES (
            'Les Piliers de l''Islam', 
            'Testez vos connaissances sur les fondements de notre religion.', 
            'Fiqh', 
            'Easy',
            'assets/images/quizzes/fiqh_thumb.png'
        )
        RETURNING id INTO v_quiz_fiqh_id;
    
        -- Question 1
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_fiqh_id, 'Combien y a-t-il de piliers de l''Islam ?', 'Les 5 piliers sont : Chahada, Prière, Zakat, Jeûne, Pèlerinage.')
        RETURNING id INTO v_q1_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q1_id, '4', FALSE),
        (v_q1_id, '5', TRUE),
        (v_q1_id, '6', FALSE),
        (v_q1_id, '3', FALSE);
    
        -- Question 2
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_fiqh_id, 'Quelle est la prière effectuée au milieu de la journée ?', 'Dhuhr est la prière de la mi-journée.')
        RETURNING id INTO v_q2_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q2_id, 'Fajr', FALSE),
        (v_q2_id, 'Maghrib', FALSE),
        (v_q2_id, 'Dhuhr', TRUE),
        (v_q2_id, 'Asr', FALSE);
    END IF;

    -- 2. Create Sirah Quiz
    IF NOT EXISTS (SELECT 1 FROM quizzes WHERE title = 'Vie du Prophète (PSL) - Débuts' AND category = 'Sirah') THEN
        INSERT INTO quizzes (title, description, category, difficulty, image_url)
        VALUES (
            'Vie du Prophète (PSL) - Débuts', 
            'Connaissez-vous l''histoire de la naissance et jeunesse du Messager ?', 
            'Sirah', 
            'Medium',
            'assets/images/quizzes/sirah_thumb.png'
        )
        RETURNING id INTO v_quiz_sirah_id;
    
        -- Question 1
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_sirah_id, 'En quelle année est né le Prophète (PSL) ?', 'L''année de l''Éléphant correspond environ à 570 après J.C.')
        RETURNING id INTO v_q3_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q3_id, '570 (Année de l''Éléphant)', TRUE),
        (v_q3_id, '622 (Hégire)', FALSE),
        (v_q3_id, '610 (Révélation)', FALSE),
        (v_q3_id, '632 (Décès)', FALSE);
    
        -- Question 2
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_sirah_id, 'Quel était le métier du Prophète (PSL) dans sa jeunesse ?', 'Il était connu pour être un berger puis un commerçant honnête.')
        RETURNING id INTO v_q4_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q4_id, 'Forgeron', FALSE),
        (v_q4_id, 'Berger / Commerçant', TRUE),
        (v_q4_id, 'Charpentier', FALSE),
        (v_q4_id, 'Agriculteur', FALSE);
    END IF;

    -- 3. Create Tariqa Quiz
    IF NOT EXISTS (SELECT 1 FROM quizzes WHERE title = 'Bases de la Tariqa' AND category = 'Tariqa') THEN
        INSERT INTO quizzes (title, description, category, difficulty, image_url)
        VALUES (
            'Bases de la Tariqa', 
            'Découvrez les fondements spirituels de notre voie.', 
            'Tariqa', 
            'Easy',
            'assets/images/quizzes/tariqa_thumb.png'
        )
        RETURNING id INTO v_quiz_tariqa_id;
    
        -- Tariqa Question 1
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_tariqa_id, 'Quel est le but principal de la Tariqa ?', 'La Tariqa est un chemin vers la purification de l''âme (Tazkiya) et la connaissance d''Allah.')
        RETURNING id INTO v_q5_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q5_id, 'La purification de l''âme', TRUE),
        (v_q5_id, 'Le commerce', FALSE),
        (v_q5_id, 'La politique', FALSE),
        (v_q5_id, 'L''astronomie', FALSE);
    
        -- Tariqa Question 2
        INSERT INTO questions (quiz_id, question_text, explanation)
        VALUES (v_quiz_tariqa_id, 'Comment appelle-t-on le disciple dans une Tariqa ?', 'Le terme "Mourid" signifie littéralement "celui qui veut" (Allah).')
        RETURNING id INTO v_q6_id;
    
        INSERT INTO answers (question_id, text, is_correct) VALUES 
        (v_q6_id, 'Le Professeur', FALSE),
        (v_q6_id, 'Le Mourid', TRUE),
        (v_q6_id, 'L''Étudiant', FALSE),
        (v_q6_id, 'Le Messager', FALSE);
    END IF;

END;
$$ LANGUAGE plpgsql;

-- Execute seed
SELECT seed_quiz_data();

-- Drop function after use
DROP FUNCTION seed_quiz_data();
