-- ============================================================================
-- CAREGIVER PROFILE MODULE SETUP
-- ============================================================================

-- 1. Create table caregiver_profiles (if not exists)
CREATE TABLE IF NOT EXISTS public.caregiver_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT,
  relationship TEXT,
  notification_enabled BOOLEAN DEFAULT true,
  profile_photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  
  -- Ensure one profile per user
  CONSTRAINT caregiver_profiles_user_id_key UNIQUE (user_id)
);

-- 2. Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_caregiver_profiles_user_id ON public.caregiver_profiles(user_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.caregiver_profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Policy: Caregivers can view their own profile
CREATE POLICY "Caregivers can view own profile" 
ON public.caregiver_profiles
FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Caregivers can insert/update their own profile
CREATE POLICY "Caregivers can insert/update own profile" 
ON public.caregiver_profiles
FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Caregivers can update their own profile (Explicit Update)
-- (Redundant if ALL is used, but good for clarity)
-- CREATE POLICY "Caregivers can update own profile" 
-- ON public.caregiver_profiles
-- FOR UPDATE
-- USING (auth.uid() = user_id);

-- 5. Storage Bucket for Avatars (Optional, if not already created)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('caregiver-avatars', 'caregiver-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy: Allow authenticated users to upload their own avatar
CREATE POLICY "Caregivers can upload own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'caregiver-avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage Policy: Allow public to view avatars
CREATE POLICY "Any user can view avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'caregiver-avatars');
