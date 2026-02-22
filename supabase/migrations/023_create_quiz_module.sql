-- 1. Table: QUIZZES
CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('Fiqh', 'Sirah', 'Tariqa', 'Quran', 'General')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('Easy', 'Medium', 'Hard')),
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_quiz_title_category UNIQUE (title, category)
);

-- 2. Table: QUESTIONS
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    explanation TEXT, -- Shown after answering
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Table: ANSWERS
CREATE TABLE IF NOT EXISTS answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Table: USER_QUIZ_ATTEMPTS (History & XP)
CREATE TABLE IF NOT EXISTS user_quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
    score INT NOT NULL, -- Number of correct answers
    total_questions INT NOT NULL,
    xp_earned INT NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_questions_quiz_id ON questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_attempts_user_id ON user_quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_attempts_quiz_id ON user_quiz_attempts(quiz_id);

-- 6. RLS Policies
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Public can read quizzes, questions, answers
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'quizzes' AND policyname = 'Public can view quizzes'
    ) THEN
        CREATE POLICY "Public can view quizzes" ON quizzes FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Public can view questions'
    ) THEN
        CREATE POLICY "Public can view questions" ON questions FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'answers' AND policyname = 'Public can view answers'
    ) THEN
        CREATE POLICY "Public can view answers" ON answers FOR SELECT USING (true);
    END IF;

   IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_quiz_attempts' AND policyname = 'Users can view own attempts'
    ) THEN
        CREATE POLICY "Users can view own attempts" ON user_quiz_attempts 
            FOR SELECT USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_quiz_attempts' AND policyname = 'Users can insert own attempts'
    ) THEN
        CREATE POLICY "Users can insert own attempts" ON user_quiz_attempts 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END
$$;

-- 7. View: LEADERBOARD
-- Aggregates XP from quiz attempts for each user
-- Note: 'profiles' table must exist.
-- Re-creating view correctly:
DROP VIEW IF EXISTS leaderboard;

CREATE OR REPLACE VIEW leaderboard AS
SELECT 
    p.id as user_id,
    p.display_name,
    p.avatar_url,
    COALESCE(SUM(uqa.xp_earned), 0) as total_xp,
    RANK() OVER (ORDER BY COALESCE(SUM(uqa.xp_earned), 0) DESC) as rank
FROM profiles p
LEFT JOIN user_quiz_attempts uqa ON p.id = uqa.user_id
GROUP BY p.id, p.display_name, p.avatar_url;


-- 8. RPC: Submit Quiz Attempt
-- Handles insertion and returning the result
CREATE OR REPLACE FUNCTION submit_quiz_attempt(
    p_quiz_id UUID,
    p_score INT,
    p_total_questions INT,
    p_xp_earned INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_attempt_id UUID;
BEGIN
    INSERT INTO user_quiz_attempts (user_id, quiz_id, score, total_questions, xp_earned)
    VALUES (auth.uid(), p_quiz_id, p_score, p_total_questions, p_xp_earned)
    RETURNING id INTO v_attempt_id;

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', v_attempt_id,
        'xp_earned', p_xp_earned
    );
END;
$$;
