-- supabase_migrations/game_analytics.sql

-- 1. Table for individual game sessions (tracked per game played)
CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    accuracy NUMERIC CHECK (accuracy >= 0 AND accuracy <= 100),
    played_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for fast aggregation
CREATE INDEX IF NOT EXISTS idx_game_sessions_patient_id ON public.game_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_played_at ON public.game_sessions(played_at DESC);

-- 2. Table for aggregated daily analytics
CREATE TABLE IF NOT EXISTS public.game_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_games INTEGER NOT NULL DEFAULT 0,
    total_duration INTEGER NOT NULL DEFAULT 0,
    avg_score NUMERIC NOT NULL DEFAULT 0,
    avg_accuracy NUMERIC,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(patient_id, date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_game_analytics_daily_patient_date 
ON public.game_analytics_daily(patient_id, date DESC);

-- 3. RLS Policies for game_sessions
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;

-- Patients can insert their own game sessions
CREATE POLICY "Patients can insert own game sessions" 
ON public.game_sessions FOR INSERT 
TO authenticated 
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Caregivers can read game sessions of linked patients
CREATE POLICY "Caregivers can view linked patient game sessions" 
ON public.game_sessions FOR SELECT 
TO authenticated 
USING (
    patient_id IN (
        SELECT cpl.patient_id 
        FROM public.caregiver_patient_links cpl
        JOIN public.caregiver_profiles cp ON cp.id = cpl.caregiver_id
        WHERE cp.user_id = auth.uid()
    )
    OR 
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- 4. RLS Policies for game_analytics_daily
ALTER TABLE public.game_analytics_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Caregivers and patients can view analytics" 
ON public.game_analytics_daily FOR SELECT 
TO authenticated 
USING (
    patient_id IN (
        SELECT cpl.patient_id 
        FROM public.caregiver_patient_links cpl
        JOIN public.caregiver_profiles cp ON cp.id = cpl.caregiver_id
        WHERE cp.user_id = auth.uid()
    )
    OR 
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- 5. Aggregation Function
-- Aggregates game_sessions into game_analytics_daily
-- Can be called via pg_cron or RPC from an Edge Function
CREATE OR REPLACE FUNCTION public.aggregate_game_analytics()
RETURNS void AS $$
BEGIN
    INSERT INTO public.game_analytics_daily (
        patient_id, 
        date, 
        total_games, 
        total_duration, 
        avg_score, 
        avg_accuracy, 
        updated_at
    )
    SELECT
        patient_id,
        DATE(played_at) as session_date,
        COUNT(*) as total_games_count,
        SUM(duration_seconds) as total_duration_sum,
        ROUND(AVG(score), 2) as avg_score_val,
        ROUND(AVG(accuracy), 2) as avg_acc_val,
        NOW() as updated_at_val
    FROM public.game_sessions
    WHERE played_at >= CURRENT_DATE - INTERVAL '1 day' -- Only aggregate recent defaults to prevent full table scans
    GROUP BY patient_id, session_date
    ON CONFLICT (patient_id, date) 
    DO UPDATE SET 
        total_games = EXCLUDED.total_games,
        total_duration = EXCLUDED.total_duration,
        avg_score = EXCLUDED.avg_score,
        avg_accuracy = EXCLUDED.avg_accuracy,
        updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Schedule Cron Job (Requires pg_cron extension)
-- Runs every 10 minutes to auto-aggregate recent game sessions
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule('aggregate-game-analytics', '*/10 * * * *', 'SELECT public.aggregate_game_analytics();');
  END IF;
END
$$;
