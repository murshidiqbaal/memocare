-- ============================================================================
-- fix_reminders_fk.sql
-- Run this in the Supabase SQL Editor to fix the FK constraint on reminders.
--
-- ROOT CAUSE:
--   reminders.caregiver_id was pointing at auth.users instead of
--   caregiver_profiles, causing any insert with a caregiver_profiles.id
--   to violate the FK constraint.
-- ============================================================================

-- STEP 1: Drop the incorrect FK constraint
-- Replace 'reminders_caregiver_id_fkey' with the actual constraint name if different.
-- You can find it via:
--   SELECT conname FROM pg_constraint WHERE conrelid = 'public.reminders'::regclass;
ALTER TABLE public.reminders
  DROP CONSTRAINT IF EXISTS reminders_caregiver_id_fkey;

-- STEP 2: Add the CORRECT FK — caregiver_id → caregiver_profiles.id
ALTER TABLE public.reminders
  ADD CONSTRAINT reminders_caregiver_id_fkey
  FOREIGN KEY (caregiver_id)
  REFERENCES public.caregiver_profiles(id)
  ON DELETE CASCADE;

-- STEP 3: Ensure patient_id also references patients.id (correct table)
ALTER TABLE public.reminders
  DROP CONSTRAINT IF EXISTS reminders_patient_id_fkey;

ALTER TABLE public.reminders
  ADD CONSTRAINT reminders_patient_id_fkey
  FOREIGN KEY (patient_id)
  REFERENCES public.patients(id)
  ON DELETE CASCADE;

-- STEP 4: Ensure required columns exist and have correct types
ALTER TABLE public.reminders
  ADD COLUMN IF NOT EXISTS reminder_time  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS repeat_rule    TEXT DEFAULT 'once',
  ADD COLUMN IF NOT EXISTS completion_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS completion_history JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS is_snoozed     BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS snooze_duration_minutes INT,
  ADD COLUMN IF NOT EXISTS last_snoozed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS voice_audio_url TEXT;

-- STEP 5: Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reminders_patient_id   ON public.reminders(patient_id);
CREATE INDEX IF NOT EXISTS idx_reminders_caregiver_id ON public.reminders(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_reminders_time         ON public.reminders(reminder_time);

-- STEP 6: Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.reminders;

-- STEP 7: RLS Policies using get_my_caregiver_id() helper
-- (Assumes you have a get_my_caregiver_id() function that returns
--  caregiver_profiles.id for the current auth user.)

DROP POLICY IF EXISTS "Caregivers can insert reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can insert reminders for linked patients" ON public.reminders
FOR INSERT WITH CHECK (
    caregiver_id = get_my_caregiver_id()
);

DROP POLICY IF EXISTS "Caregivers can update reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can update reminders for linked patients" ON public.reminders
FOR UPDATE USING (
    caregiver_id = get_my_caregiver_id()
);

DROP POLICY IF EXISTS "Patients and linked caregivers can view reminders" ON public.reminders;
CREATE POLICY "Patients and linked caregivers can view reminders" ON public.reminders
FOR SELECT USING (
    patient_id = get_my_patient_id()
    OR caregiver_id = get_my_caregiver_id()
);

DROP POLICY IF EXISTS "Caregivers can delete reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can delete reminders for linked patients" ON public.reminders
FOR DELETE USING (
    caregiver_id = get_my_caregiver_id()
);

-- ============================================================================
-- HELPER FUNCTIONS (run once if not already created)
-- These functions look up the internal profile ID for the current auth user.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_caregiver_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.caregiver_profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_my_patient_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.patients WHERE user_id = auth.uid() LIMIT 1;
$$;
