-- ============================================================================
-- FIX: PATIENT SELECTION DROPDOWN DB LAYER
-- ============================================================================
-- This migration ensures the caregiver_patient_links joins cleanly with patient_profiles
-- using correctly defined foreign keys and RLS policies. It fully supports:
-- .from('caregiver_patient_links').select('patient_id, patient_profiles(*)')
-- ============================================================================

-- 1. Ensure `patients` has `full_name` column (if not added previously)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='patients' AND column_name='full_name') THEN
        ALTER TABLE public.patients ADD COLUMN full_name TEXT;
    END IF;
END $$;

-- 2. Create `patient_profiles` VIEW
-- We use a view mapped to the `patients` table to match the exact table name Flutter expects
-- and to keep logic separated if `patients` structure changes under the hood.
CREATE OR REPLACE VIEW public.patient_profiles AS 
SELECT 
  id,
  full_name,
  date_of_birth,
  gender,
  phone,
  profile_photo_url,
  medical_notes,
  emergency_contact_name,
  emergency_contact_phone,
  created_at,
  updated_at
FROM public.patients;

-- We need to ensure patients table actually exists and has an ID pointing to auth.users
-- This is already assumed by other migrations, but the views need standard grant access.
GRANT SELECT ON public.patient_profiles TO authenticated;

-- 3. Fix the Foreign Keys on `caregiver_patient_links`
-- This allows PostgREST (Supabase) to automatically resolve `patient_profiles(*)` 
-- via the underlying `patients` table relationship.

ALTER TABLE public.caregiver_patient_links 
DROP CONSTRAINT IF EXISTS caregiver_patient_links_patient_id_fkey;

ALTER TABLE public.caregiver_patient_links 
ADD CONSTRAINT caregiver_patient_links_patient_id_fkey 
FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;

ALTER TABLE public.caregiver_patient_links 
DROP CONSTRAINT IF EXISTS caregiver_patient_links_caregiver_id_fkey;

ALTER TABLE public.caregiver_patient_links 
ADD CONSTRAINT caregiver_patient_links_caregiver_id_fkey 
FOREIGN KEY (caregiver_id) REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE;

-- 4. Fix RLS on `caregiver_patient_links`
-- Make sure the caregiver can actually read their links!
DROP POLICY IF EXISTS "Caregiver can view their linked patients" ON public.caregiver_patient_links;
CREATE POLICY "Caregiver can view their linked patients"
ON public.caregiver_patient_links FOR SELECT
TO authenticated
USING (
  caregiver_id IN (SELECT id FROM public.caregiver_profiles WHERE user_id = auth.uid())
);
