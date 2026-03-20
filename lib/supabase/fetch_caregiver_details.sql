-- 1. Add missing columns to caregiver_profiles if they don't exist
-- This ensures the table matches the fields expected by the EditCaregiverProfileScreen and the Caregiver model.

ALTER TABLE public.caregiver_profiles 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS relationship TEXT,
ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS languages TEXT[],
ADD COLUMN IF NOT EXISTS years_of_experience INTEGER,
ADD COLUMN IF NOT EXISTS qualification TEXT,
ADD COLUMN IF NOT EXISTS license_number TEXT,
ADD COLUMN IF NOT EXISTS certifications TEXT[],
ADD COLUMN IF NOT EXISTS shift_hours TEXT,
ADD COLUMN IF NOT EXISTS care_type TEXT,
ADD COLUMN IF NOT EXISTS available_days INTEGER[],
ADD COLUMN IF NOT EXISTS emergency_available BOOLEAN DEFAULT true;

-- 2. Update RLS Policies for caregiver_profiles
-- We need to allow patients to read the profiles of THEIR linked caregivers.

-- First, ensure the security definer function exists (from rls_policies.sql)
CREATE OR REPLACE FUNCTION get_my_patient_id()
RETURNS uuid
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
    SELECT id FROM patients WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Drop the old restricted select policy if it exists (or just add the new one)
-- The original policy was: 
-- CREATE POLICY "caregiver_profiles_select_own" ON public.caregiver_profiles FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "caregiver_profiles_linked_patient_select" ON public.caregiver_profiles;
CREATE POLICY "caregiver_profiles_linked_patient_select" ON public.caregiver_profiles
    FOR SELECT USING (
        auth.uid() = user_id -- Still allow owner to see own
        OR 
        EXISTS (
            SELECT 1 FROM public.caregiver_patient_links cpl
            WHERE cpl.caregiver_id = caregiver_profiles.id
              AND cpl.patient_id = get_my_patient_id()
        )
    );

-- 3. Verify caregiver_patient_links RLS
-- Ensure patients can select their own links to caregivers
DROP POLICY IF EXISTS "cpl_patient_select" ON public.caregiver_patient_links;
CREATE POLICY "cpl_patient_select" ON public.caregiver_patient_links
    FOR SELECT USING (
        patient_id = get_my_patient_id()
    );

-- 4. Enable Realtime for caregiver_profiles so updates reflect immediately
ALTER PUBLICATION supabase_realtime ADD TABLE public.caregiver_profiles;
