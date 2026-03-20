-- =============================================================================
-- Fix Caregiver Fetch Logic & RLS Policies
-- =============================================================================

-- 1. Ensure RLS allows patients to read profiles of caregivers they are linked to.
-- This uses the user's requested logic which checks link from patients.user_id.

DROP POLICY IF EXISTS "patients can read linked caregivers" ON public.caregiver_profiles;
CREATE POLICY "patients can read linked caregivers"
ON public.caregiver_profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_patient_links cpl
    JOIN public.patients p ON p.id = cpl.patient_id
    WHERE cpl.caregiver_id = public.caregiver_profiles.id
    AND p.user_id = auth.uid()
  )
  OR auth.uid() = user_id -- Allow caregivers to see their own profile
);

-- 2. Ensure RLS allows patients to read their own caregiver links.

DROP POLICY IF EXISTS "patients read caregiver links" ON public.caregiver_patient_links;
CREATE POLICY "patients read caregiver links"
ON public.caregiver_patient_links
FOR SELECT
TO authenticated
USING (
  patient_id IN (
    SELECT id FROM public.patients WHERE user_id = auth.uid()
  )
  OR caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE user_id = auth.uid()
  )
);

-- 3. Verification Query (Run this manually in SQL Editor to test for a specific patient)
-- SELECT *
-- FROM caregiver_patient_links cpl
-- JOIN caregiver_profiles cp ON cp.id = cpl.caregiver_id
-- WHERE cpl.patient_id = 'YOUR_PATIENT_ID_HERE';
