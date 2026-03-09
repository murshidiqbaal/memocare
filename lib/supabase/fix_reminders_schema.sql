-- fix_reminders_schema.sql
-- Run this in Supabase SQL Editor to align reminders table with Dart model and fix RLS recursion.

-- 1. Ensure Columns Match Dart Model
ALTER TABLE public.reminders RENAME COLUMN IF EXISTS remind_at TO reminder_time;
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS status TEXT; -- Optional: keeping if user needs but 'completion_status' is primary.
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS local_audio_path TEXT; -- For local syncing if needed.

-- 2. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reminders_patient_id ON public.reminders(patient_id);
CREATE INDEX IF NOT EXISTS idx_reminders_caregiver_id ON public.reminders(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_reminders_time ON public.reminders(reminder_time);

-- 3. Enable Realtime for Reminders
ALTER PUBLICATION supabase_realtime ADD TABLE public.reminders;

-- 4. Unified Non-Recursive RLS Policies for Reminders
-- Note: These use the helper functions defined in rls_policies.sql

DROP POLICY IF EXISTS "Caregivers can insert reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can insert reminders for linked patients" ON public.reminders
FOR INSERT WITH CHECK (
    caregiver_id = get_my_caregiver_id()
    OR auth.uid() = patient_id
);

DROP POLICY IF EXISTS "Caregivers can update reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can update reminders for linked patients" ON public.reminders
FOR UPDATE USING (
    caregiver_id = get_my_caregiver_id()
    OR auth.uid() = patient_id
);

DROP POLICY IF EXISTS "Patients and linked caregivers can view reminders" ON public.reminders;
CREATE POLICY "Patients and linked caregivers can view reminders" ON public.reminders
FOR SELECT USING (
    patient_id = get_my_patient_id()
    OR caregiver_id = get_my_caregiver_id()
    OR auth.uid() = patient_id -- Fallback for directly checking auth.uid()
);

DROP POLICY IF EXISTS "Caregivers can delete reminders for linked patients" ON public.reminders;
CREATE POLICY "Caregivers can delete reminders for linked patients" ON public.reminders
FOR DELETE USING (
    caregiver_id = get_my_caregiver_id()
    OR auth.uid() = patient_id
);
