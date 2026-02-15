-- ============================================================================
-- CONNECTED PATIENTS DASHBOARD SCHEMA & SECURITY
-- ============================================================================

-- 1. Patients Table (Ensure fields exist)
CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  date_of_birth DATE,
  gender TEXT,
  phone TEXT,
  profile_photo_url TEXT,
  medical_notes TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Enable RLS
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies

-- Policy: Patients can view/update their own profile
CREATE POLICY "Patients view own profile" 
ON public.patients 
FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Patients update own profile" 
ON public.patients 
FOR UPDATE 
USING (auth.uid() = id);

-- Policy: Caregivers can view patients they are linked to
CREATE POLICY "Caregivers view linked patients" 
ON public.patients 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM public.caregiver_patient_links link
    JOIN public.caregiver_profiles profile ON link.caregiver_id = profile.id
    WHERE link.patient_id = public.patients.id 
    AND profile.user_id = auth.uid()
  )
);

-- 4. Real-time Setup
-- Enable generic replication on caregiver_patient_links to allow clients to listen to changes
ALTER PUBLICATION supabase_realtime ADD TABLE public.caregiver_patient_links;
-- Enable replication on 'patients' if we want to stream status updates (optional)
ALTER PUBLICATION supabase_realtime ADD TABLE public.patients;
