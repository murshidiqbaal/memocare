-- =====================================================
-- CAREGIVER APPROVAL WORKFLOW
-- =====================================================

-- Table to store caregiver registration requests
CREATE TABLE IF NOT EXISTS caregiver_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE caregiver_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view all caregiver requests"
ON caregiver_requests FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Admins can update caregiver requests"
ON caregiver_requests FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can view their own requests"
ON caregiver_requests FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR email = (SELECT email FROM auth.users WHERE id = auth.uid()));

CREATE POLICY "Authenticated users can create requests"
ON caregiver_requests FOR INSERT
TO authenticated
WITH CHECK (true);

-- =====================================================
-- TRIGGER FOR AUTO-ROLE UPDATE
-- =====================================================

CREATE OR REPLACE FUNCTION handle_caregiver_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        -- Update the user's role in the profiles table
        UPDATE profiles
        SET role = 'caregiver'
        WHERE id = NEW.user_id;
    END IF;
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_caregiver_approval
BEFORE UPDATE ON caregiver_requests
FOR EACH ROW
EXECUTE FUNCTION handle_caregiver_approval();

-- Ensure 'pending_caregiver' is a recognized role in your application logic
-- The AppRouter will handle redirection for this role.
