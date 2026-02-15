-- ============================================================================
-- 1. INVITE CODES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster lookup
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes(code);

-- RLS: Only caregivers/authenticated users can view code to verify (or use RPC for stricter security)
-- Allow anyone authenticated to find a code by its value (needed for verification step)
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users to verify code"
ON invite_codes FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Enable update for authenticated users to mark used"
ON invite_codes FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- ============================================================================
-- 2. CAREGIVER PATIENT LINKS TABLE
-- ============================================================================

-- If the table exists from previous migrations with different schema, we might need to alter it
-- For this task, we define the schema as requested.
CREATE TABLE IF NOT EXISTS caregiver_patient_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caregiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Prevent duplicate links
  UNIQUE(caregiver_id, patient_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_links_caregiver ON caregiver_patient_links(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_links_patient ON caregiver_patient_links(patient_id);

-- RLS
ALTER TABLE caregiver_patient_links ENABLE ROW LEVEL SECURITY;

-- Caregiver can see their own links
CREATE POLICY "Caregiver can view their linked patients"
ON caregiver_patient_links FOR SELECT
TO authenticated
USING (auth.uid() = caregiver_id);

-- Patient can see who monitors them
CREATE POLICY "Patient can view their caregivers"
ON caregiver_patient_links FOR SELECT
TO authenticated
USING (auth.uid() = patient_id);

-- Caregiver can create a link (when connecting)
CREATE POLICY "Caregiver can create a link"
ON caregiver_patient_links FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = caregiver_id);

-- ============================================================================
-- 3. RLS FOR DATA ACCESS (Reminders, Profiles)
-- ============================================================================

-- Access Reminders: Caregiver can read reminders if linked to patient
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Caregiver can view linked patient reminders"
ON reminders FOR SELECT
TO authenticated
USING (
  auth.uid() = patient_id -- User is the patient
  OR
  EXISTS (
    SELECT 1 FROM caregiver_patient_links
    WHERE caregiver_id = auth.uid()
    AND patient_id = reminders.patient_id
  )
);

-- Access Profiles: Caregiver can read patient profile if linked
-- Assuming 'profiles' table exists
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Caregiver can view linked patient profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() = id -- User is the profile owner
  OR
  EXISTS (
    SELECT 1 FROM caregiver_patient_links
    WHERE caregiver_id = auth.uid()
    AND patient_id = profiles.id
  )
);
