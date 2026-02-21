-- Ensure reminders table matches Dart model exactly

CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT,
    description TEXT,
    remind_at TIMESTAMPTZ NOT NULL,
    repeat_rule TEXT,
    created_by UUID REFERENCES auth.users(id),
    completion_status TEXT,
    voice_audio_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    completion_history TIMESTAMPTZ[],
    is_snoozed BOOLEAN DEFAULT false,
    snooze_duration_minutes INTEGER,
    last_snoozed_at TIMESTAMPTZ
);

ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS repeat_rule TEXT;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS completion_status TEXT;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS completion_history TIMESTAMPTZ[] DEFAULT '{}';
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS is_snoozed BOOLEAN DEFAULT false;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS snooze_duration_minutes INTEGER;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS last_snoozed_at TIMESTAMPTZ;

-- Ensure RLS on reminders
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Caregivers can insert reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can insert reminders for linked patients" ON public.reminders
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = reminders.patient_id 
        AND c.user_id = auth.uid()
    )
    OR auth.uid() = patient_id
);

DROP POLICY IF EXISTS "Caregivers can update reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can update reminders for linked patients" ON public.reminders
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = reminders.patient_id 
        AND c.user_id = auth.uid()
    )
    OR auth.uid() = patient_id
);

DROP POLICY IF EXISTS "Patients and linked caregivers can view reminders" ON public.reminders;
CREATE POLICY "Patients and linked caregivers can view reminders" ON public.reminders
FOR SELECT USING (
    auth.uid() = patient_id
    OR 
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = reminders.patient_id 
        AND c.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Caregivers can delete reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can delete reminders for linked patients" ON public.reminders
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = reminders.patient_id 
        AND c.user_id = auth.uid()
    )
    OR auth.uid() = patient_id
);

-- Ensure memory_cards exist completely
CREATE TABLE IF NOT EXISTS public.memory_cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  voice_audio_url TEXT,
  event_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for memory cards too
ALTER TABLE public.memory_cards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Caregivers can insert memories" ON public.memory_cards;
CREATE POLICY "Caregivers can insert memories" ON public.memory_cards
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
    OR auth.uid() = patient_id
);

DROP POLICY IF EXISTS "Caregivers can update memories" ON public.memory_cards;
CREATE POLICY "Caregivers can update memories" ON public.memory_cards
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links link
        JOIN public.caregiver_profiles c ON link.caregiver_id = c.id
        WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
    OR auth.uid() = patient_id
);

NOTIFY pgrst, 'reload schema';
