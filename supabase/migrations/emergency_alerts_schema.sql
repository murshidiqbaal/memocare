-- =====================================================
-- EMERGENCY ALERTS TABLE
-- =====================================================
-- This table stores SOS emergency alerts sent by patients
-- Caregivers receive real-time notifications via Supabase Realtime

CREATE TABLE IF NOT EXISTS emergency_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    caregiver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'cancelled', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    patient_name TEXT, -- Denormalized for quick display
    patient_phone TEXT, -- Denormalized for quick display
    
    -- Indexes for performance
    CONSTRAINT emergency_alerts_patient_id_idx UNIQUE (patient_id, created_at)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_patient_id ON emergency_alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_caregiver_id ON emergency_alerts(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_status ON emergency_alerts(status);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_created_at ON emergency_alerts(created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;

-- Policy 1: Patients can INSERT their own alerts
CREATE POLICY "Patients can create their own emergency alerts"
ON emergency_alerts
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = patient_id);

-- Policy 2: Patients can SELECT their own alerts
CREATE POLICY "Patients can view their own emergency alerts"
ON emergency_alerts
FOR SELECT
TO authenticated
USING (auth.uid() = patient_id);

-- Policy 3: Patients can UPDATE their own alerts (to cancel)
CREATE POLICY "Patients can cancel their own emergency alerts"
ON emergency_alerts
FOR UPDATE
TO authenticated
USING (auth.uid() = patient_id)
WITH CHECK (auth.uid() = patient_id);

-- Policy 4: Caregivers can SELECT alerts from their linked patients
CREATE POLICY "Caregivers can view alerts from linked patients"
ON emergency_alerts
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM caregiver_patient_links cpl
        INNER JOIN caregiver_profiles cp ON cpl.caregiver_id = cp.id
        WHERE cp.user_id = auth.uid()
        AND cpl.patient_id = emergency_alerts.patient_id
    )
);

-- Policy 5: Caregivers can UPDATE alerts from their linked patients (to resolve)
CREATE POLICY "Caregivers can resolve alerts from linked patients"
ON emergency_alerts
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM caregiver_patient_links cpl
        INNER JOIN caregiver_profiles cp ON cpl.caregiver_id = cp.id
        WHERE cp.user_id = auth.uid()
        AND cpl.patient_id = emergency_alerts.patient_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM caregiver_patient_links cpl
        INNER JOIN caregiver_profiles cp ON cpl.caregiver_id = cp.id
        WHERE cp.user_id = auth.uid()
        AND cpl.patient_id = emergency_alerts.patient_id
    )
);

-- =====================================================
-- REALTIME PUBLICATION
-- =====================================================
-- Enable Realtime for emergency_alerts table
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_alerts;

-- =====================================================
-- HELPER FUNCTION: Auto-assign caregiver on insert
-- =====================================================
CREATE OR REPLACE FUNCTION assign_primary_caregiver()
RETURNS TRIGGER AS $$
BEGIN
    -- Find the first linked caregiver for this patient
    SELECT cp.user_id INTO NEW.caregiver_id
    FROM caregiver_patient_links cpl
    INNER JOIN caregiver_profiles cp ON cpl.caregiver_id = cp.id
    WHERE cpl.patient_id = NEW.patient_id
    ORDER BY cpl.linked_at ASC
    LIMIT 1;
    
    -- Fetch patient details for denormalization
    SELECT 
        p.full_name,
        p.phone_number
    INTO 
        NEW.patient_name,
        NEW.patient_phone
    FROM profiles p
    WHERE p.id = NEW.patient_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-assign caregiver
CREATE TRIGGER trigger_assign_caregiver
BEFORE INSERT ON emergency_alerts
FOR EACH ROW
EXECUTE FUNCTION assign_primary_caregiver();

-- =====================================================
-- SAMPLE QUERIES (for testing)
-- =====================================================
-- Insert test alert:
-- INSERT INTO emergency_alerts (patient_id, latitude, longitude)
-- VALUES ('patient-uuid-here', 40.7128, -74.0060);

-- Query alerts for a caregiver:
-- SELECT * FROM emergency_alerts
-- WHERE status = 'sent'
-- ORDER BY created_at DESC;
