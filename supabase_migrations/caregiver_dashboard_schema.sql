-- Caregiver Dashboard & Remote Monitoring Schema
-- Migration for MemoCare Caregiver-Patient Linking

-- ============================================================================
-- 1. CREATE CAREGIVER_PATIENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS caregiver_patients (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  caregiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  relationship TEXT, -- e.g., "Son", "Daughter", "Professional Caregiver"
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique caregiver-patient pairs
  UNIQUE(caregiver_id, patient_id)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_caregiver_patients_caregiver_id 
ON caregiver_patients(caregiver_id);

CREATE INDEX IF NOT EXISTS idx_caregiver_patients_patient_id 
ON caregiver_patients(patient_id);

CREATE INDEX IF NOT EXISTS idx_caregiver_patients_is_primary 
ON caregiver_patients(is_primary) WHERE is_primary = TRUE;

-- ============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE caregiver_patients ENABLE ROW LEVEL SECURITY;

-- Policy: Caregivers can view their own links
CREATE POLICY "Caregivers can view own patient links"
ON caregiver_patients FOR SELECT
USING (auth.uid() = caregiver_id);

-- Policy: Caregivers can insert their own links (admin approval required)
CREATE POLICY "Caregivers can create patient links"
ON caregiver_patients FOR INSERT
WITH CHECK (auth.uid() = caregiver_id);

-- Policy: Caregivers can update their own links
CREATE POLICY "Caregivers can update own links"
ON caregiver_patients FOR UPDATE
USING (auth.uid() = caregiver_id);

-- Policy: Caregivers can delete their own links
CREATE POLICY "Caregivers can delete own links"
ON caregiver_patients FOR DELETE
USING (auth.uid() = caregiver_id);

-- ============================================================================
-- 4. EXTEND RLS POLICIES FOR EXISTING TABLES
-- ============================================================================

-- Allow caregivers to view linked patient reminders
CREATE POLICY "Caregivers can view linked patient reminders"
ON reminders FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM caregiver_patients
    WHERE caregiver_id = auth.uid()
    AND patient_id = reminders.patient_id
  )
);

-- Allow caregivers to view linked patient memory cards
CREATE POLICY "Caregivers can view linked patient memory cards"
ON memory_cards FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM caregiver_patients
    WHERE caregiver_id = auth.uid()
    AND patient_id = memory_cards.patient_id
  )
);

-- Allow caregivers to view linked patient people cards
CREATE POLICY "Caregivers can view linked patient people cards"
ON people_cards FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM caregiver_patients
    WHERE caregiver_id = auth.uid()
    AND patient_id = people_cards.patient_id
  )
);

-- Allow caregivers to view linked patient voice queries
CREATE POLICY "Caregivers can view linked patient voice queries"
ON voice_queries FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM caregiver_patients
    WHERE caregiver_id = auth.uid()
    AND patient_id = voice_queries.patient_id
  )
);

-- ============================================================================
-- 5. FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_caregiver_patients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER trigger_update_caregiver_patients_updated_at
BEFORE UPDATE ON caregiver_patients
FOR EACH ROW
EXECUTE FUNCTION update_caregiver_patients_updated_at();

-- Function to ensure only one primary caregiver per patient
CREATE OR REPLACE FUNCTION ensure_single_primary_caregiver()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = TRUE THEN
    -- Unset other primary caregivers for this patient
    UPDATE caregiver_patients
    SET is_primary = FALSE
    WHERE patient_id = NEW.patient_id
    AND id != NEW.id
    AND is_primary = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce single primary caregiver
CREATE TRIGGER trigger_ensure_single_primary_caregiver
BEFORE INSERT OR UPDATE ON caregiver_patients
FOR EACH ROW
EXECUTE FUNCTION ensure_single_primary_caregiver();

-- ============================================================================
-- 6. SAMPLE DATA (FOR TESTING)
-- ============================================================================

-- Insert sample caregiver-patient links
-- NOTE: Replace UUIDs with actual user IDs from your profiles table

-- Example:
-- INSERT INTO caregiver_patients (caregiver_id, patient_id, relationship, is_primary)
-- VALUES 
--   ('caregiver-uuid-1', 'patient-uuid-1', 'Son', TRUE),
--   ('caregiver-uuid-2', 'patient-uuid-1', 'Daughter', FALSE);

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON caregiver_patients TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if table exists
-- SELECT * FROM caregiver_patients;

-- Check RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'caregiver_patients';

-- Check indexes
-- SELECT * FROM pg_indexes WHERE tablename = 'caregiver_patients';

-- ============================================================================
-- ROLLBACK (IF NEEDED)
-- ============================================================================

-- DROP TRIGGER IF EXISTS trigger_ensure_single_primary_caregiver ON caregiver_patients;
-- DROP TRIGGER IF EXISTS trigger_update_caregiver_patients_updated_at ON caregiver_patients;
-- DROP FUNCTION IF EXISTS ensure_single_primary_caregiver();
-- DROP FUNCTION IF EXISTS update_caregiver_patients_updated_at();
-- DROP TABLE IF EXISTS caregiver_patients CASCADE;
