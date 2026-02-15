-- Rename caregivers table to caregiver_profiles
ALTER TABLE IF EXISTS caregivers RENAME TO caregiver_profiles;

-- Update foreign key references in caregiver_patient_links if necessary
-- (Assuming the FK was pointing to caregivers.id)

-- Drop the old FK constraint
ALTER TABLE caregiver_patient_links DROP CONSTRAINT IF EXISTS caregiver_patient_links_caregiver_id_fkey;

-- Add new FK constraint pointing to caregiver_profiles
ALTER TABLE caregiver_patient_links 
ADD CONSTRAINT caregiver_patient_links_caregiver_id_fkey 
FOREIGN KEY (caregiver_id) REFERENCES caregiver_profiles(id) ON DELETE CASCADE;

-- Update RLS policies to use the new table name
-- (Policies on other tables that might reference caregivers)

-- Example: Policy on patients table
-- DROP POLICY IF EXISTS "Linked Caregivers can view patient profile" ON patients;
-- CREATE POLICY "Linked Caregivers can view patient profile" ON patients
-- FOR SELECT USING (
--   EXISTS (
--     SELECT 1 FROM caregiver_patient_links link
--     JOIN caregiver_profiles c ON link.caregiver_id = c.id
--     WHERE link.patient_id = patients.id 
--     AND c.user_id = auth.uid()
--   )
-- );
