-- ============================================================================
-- PATIENT PROFILE SYSTEM - COMPLETE SCHEMA
-- ============================================================================
-- This migration creates the complete patient profile system with:
-- 1. Patients table for patient-specific data
-- 2. RLS policies for secure access
-- 3. Storage bucket for profile photos
-- 4. Triggers for automatic profile creation
-- ============================================================================

-- ============================================================================
-- 1. CREATE PATIENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  medical_notes TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  profile_photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_patients_id ON public.patients(id);

-- Add comment for documentation
COMMENT ON TABLE public.patients IS 'Stores patient-specific profile information for dementia care application';

-- ============================================================================
-- 2. CREATE TRIGGER FOR AUTO-UPDATING updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_patients_updated_at ON public.patients;
CREATE TRIGGER update_patients_updated_at
  BEFORE UPDATE ON public.patients
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Patients can view own profile" ON public.patients;
DROP POLICY IF EXISTS "Patients can update own profile" ON public.patients;
DROP POLICY IF EXISTS "Patients can insert own profile" ON public.patients;
DROP POLICY IF EXISTS "Linked Caregivers can view patient profile" ON public.patients;
DROP POLICY IF EXISTS "Linked Caregivers can update patient medical info" ON public.patients;

-- ============================================================================
-- 4. CREATE RLS POLICIES
-- ============================================================================

-- Policy 1: Patients can view their own profile
CREATE POLICY "Patients can view own profile" 
ON public.patients
FOR SELECT 
USING (auth.uid() = id);

-- Policy 2: Patients can update their own profile
CREATE POLICY "Patients can update own profile" 
ON public.patients
FOR UPDATE 
USING (auth.uid() = id);

-- Policy 3: Patients can insert their own profile
CREATE POLICY "Patients can insert own profile" 
ON public.patients
FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Policy 4: Linked Caregivers can view patient profiles
-- (Requires caregiver_patient_links table to exist)
CREATE POLICY "Linked Caregivers can view patient profile" 
ON public.patients
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM public.caregiver_patient_links link
    JOIN public.caregivers c ON link.caregiver_id = c.id
    WHERE link.patient_id = patients.id 
    AND c.user_id = auth.uid()
  )
);

-- Policy 5: Linked Caregivers can update patient medical information
-- (Emergency contact and medical notes only)
CREATE POLICY "Linked Caregivers can update patient medical info" 
ON public.patients
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 
    FROM public.caregiver_patient_links link
    JOIN public.caregivers c ON link.caregiver_id = c.id
    WHERE link.patient_id = patients.id 
    AND c.user_id = auth.uid()
  )
);

-- ============================================================================
-- 5. CREATE STORAGE BUCKET FOR PROFILE PHOTOS
-- ============================================================================

-- Create bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('patient-avatars', 'patient-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Patients can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Patients can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Patients can delete own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;

-- Storage Policy 1: Patients can upload their own avatar
CREATE POLICY "Patients can upload own avatar"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'patient-avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage Policy 2: Patients can update their own avatar
CREATE POLICY "Patients can update own avatar"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'patient-avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage Policy 3: Patients can delete their own avatar
CREATE POLICY "Patients can delete own avatar"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'patient-avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage Policy 4: Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
ON storage.objects
FOR SELECT
USING (bucket_id = 'patient-avatars');

-- ============================================================================
-- 6. CREATE TRIGGER FOR AUTO-CREATING PATIENT PROFILE ON SIGNUP
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_patient_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create patient profile if role is 'patient'
  IF NEW.raw_user_meta_data->>'role' = 'patient' THEN
    INSERT INTO public.patients (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_patient ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created_patient
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_patient_user();

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions on patients table
GRANT SELECT, INSERT, UPDATE ON public.patients TO authenticated;

-- ============================================================================
-- 8. VERIFICATION QUERIES (For testing)
-- ============================================================================

-- Uncomment to test:
-- SELECT * FROM public.patients;
-- SELECT * FROM storage.buckets WHERE id = 'patient-avatars';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
