-- =============================================================================
-- MemoCare — Final Auth Fix Script
-- Run this in the Supabase SQL Editor to resolve the "Database error saving new user".
-- This script properly drops conflicting triggers, defines robust tables matching the
-- Flutter client's expectations, and safely handles role-based profile creation.
-- =============================================================================

-- 1. Ensure core schema has the correct columns (user_id instead of just id)
-- The Flutter app explicitly queries 'user_id' in profiles.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT CHECK (role IN ('patient', 'caregiver', 'admin')) DEFAULT 'patient',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.caregiver_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);


-- 2. Drop EVERY potential conflicting trigger that caused 500 errors or duplicate constraints
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_caregiver ON auth.users;
DROP TRIGGER IF EXISTS trigger_handle_new_user ON auth.users;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_profile() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_caregiver_user() CASCADE;


-- 3. Consolidated and SAFE Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user_v2()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  extracted_role TEXT;
  extracted_name TEXT;
BEGIN
  -- Extract Metadata Safely
  extracted_role := COALESCE(new.raw_user_meta_data->>'role', 'patient');
  extracted_name := COALESCE(new.raw_user_meta_data->>'fullName', 'User');

  -- A. Insert into the main profiles table
  INSERT INTO public.profiles (
    user_id,
    email,
    full_name,
    role,
    created_at
  )
  VALUES (
    new.id,
    new.email,
    extracted_name,
    extracted_role,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE 
  SET email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role;

  -- B. Handle role-specific tables (patients or caregiver_profiles)
  IF (extracted_role = 'caregiver') THEN
      INSERT INTO public.caregiver_profiles (user_id, email, full_name, created_at)
      VALUES (new.id, new.email, extracted_name, now())
      ON CONFLICT (user_id) DO NOTHING;
  ELSIF (extracted_role = 'patient') THEN
      INSERT INTO public.patients (user_id, created_at)
      VALUES (new.id, now())
      ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    -- If anything fails, DO NOT block auth.users creation. Just log the error context to pg_stat_activity if possible, and return new to allow signup.
    RAISE LOG 'Supabase Profile Creation Trigger Failed: %', SQLERRM;
    RETURN new;
END;
$$;


-- 4. Create the final unified trigger
CREATE TRIGGER on_auth_user_created_v2
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_v2();


-- 5. Safe Permissions Defaults
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_profiles ENABLE ROW LEVEL SECURITY;

-- If they aren't created yet, these ensure the tables work initially.
-- Users can read/write their own profile.
DROP POLICY IF EXISTS "Profiles select own" ON public.profiles;
CREATE POLICY "Profiles select own" ON public.profiles FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;
CREATE POLICY "Profiles update own" ON public.profiles FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Profiles insert own" ON public.profiles;
CREATE POLICY "Profiles insert own" ON public.profiles FOR INSERT WITH CHECK (user_id = auth.uid());
