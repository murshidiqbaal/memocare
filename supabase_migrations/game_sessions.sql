-- Game Sessions Table for tracking cognitive game performance
-- Patients play games, caregivers view analytics

CREATE TABLE IF NOT EXISTS public.game_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE NOT NULL,
  game_type TEXT NOT NULL CHECK (game_type IN ('memory_match', 'word_puzzle', 'shape_sorter')),
  score INTEGER NOT NULL CHECK (score >= 0),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_game_sessions_patient_id ON public.game_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_completed_at ON public.game_sessions(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_sessions_game_type ON public.game_sessions(game_type);

-- Enable Row Level Security
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can view their own game sessions
CREATE POLICY "Patients can view own game sessions" ON public.game_sessions
  FOR SELECT USING (auth.uid() = patient_id);

-- Patients can insert their own game sessions
CREATE POLICY "Patients can insert own game sessions" ON public.game_sessions
  FOR INSERT WITH CHECK (auth.uid() = patient_id);

-- Linked caregivers can view patient game sessions (for analytics)
CREATE POLICY "Linked caregivers can view patient game sessions" ON public.game_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
      WHERE link.patient_id = game_sessions.patient_id 
        AND c.user_id = auth.uid()
    )
  );

-- Optional: Caregivers can delete sessions (for data management)
CREATE POLICY "Linked caregivers can delete game sessions" ON public.game_sessions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
      WHERE link.patient_id = game_sessions.patient_id 
        AND c.user_id = auth.uid()
    )
  );
