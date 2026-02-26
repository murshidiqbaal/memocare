-- Drop existing table from previous migrations to apply new schema
DROP TABLE IF EXISTS public.game_analytics_daily CASCADE;

-- 1️⃣ Create aggregated daily analytics table
CREATE TABLE IF NOT EXISTS public.game_analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL,
  session_count INTEGER DEFAULT 0,
  avg_score NUMERIC DEFAULT 0,
  best_score INTEGER DEFAULT 0,
  total_duration_seconds INTEGER DEFAULT 0,
  analytics_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(patient_id, game_type, analytics_date)
);

-- 2️⃣ Enable RLS
ALTER TABLE public.game_analytics_daily ENABLE ROW LEVEL SECURITY;

-- Patient can insert/update own analytics
CREATE POLICY "Patients manage own analytics"
ON public.game_analytics_daily
FOR ALL
USING (auth.uid() = patient_id)
WITH CHECK (auth.uid() = patient_id);

-- Caregiver read linked patients analytics
CREATE POLICY "Caregivers view linked analytics"
ON public.game_analytics_daily
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_patient_links link
    JOIN public.caregiver_profiles cp
      ON cp.id = link.caregiver_id
    WHERE link.patient_id = game_analytics_daily.patient_id
      AND cp.user_id = auth.uid()
  )
);
