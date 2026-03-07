-- =====================================================
-- FINAL FIX: CONSOLIDATE USER CREATION TRIGGERS
-- =====================================================

-- 1. Ensure tables match the exact required schema
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    role TEXT NOT NULL CHECK (role IN ('patient', 'caregiver', 'admin')),
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.caregivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Clean up ALL old triggers and functions to prevent 500 errors
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_caregiver ON auth.users;
DROP TRIGGER IF EXISTS trigger_handle_new_user ON auth.users;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_caregiver_user() CASCADE;

-- 3. Create the robust consolidated trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_full_name TEXT;
BEGIN
    -- Extract metadata with safe defaults
    user_role := COALESCE(new.raw_user_meta_data->>'role', 'patient');
    user_full_name := new.raw_user_meta_data->>'full_name';

    -- A. Create/Update Profile
    -- Using upsert logic to handle any potential race conditions
    INSERT INTO public.profiles (id, email, role, full_name)
    VALUES (new.id, new.email, user_role, user_full_name)
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email,
        role = EXCLUDED.role,
        full_name = EXCLUDED.full_name,
        updated_at = now();

    -- B. Create role-specific records
    IF user_role = 'caregiver' THEN
        INSERT INTO public.caregivers (user_id, status)
        VALUES (new.id, 'pending')
        ON CONFLICT (user_id) DO NOTHING;
    ELSIF user_role = 'patient' THEN
        INSERT INTO public.patients (id)
        VALUES (new.id)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-attach the single consolidated trigger
CREATE TRIGGER trigger_handle_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 5. Final Table Cleanup (Optional but helpful for consistency)
-- Ensure 'caregivers' does not have 'notification_enabled' if it previously did
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caregivers' AND column_name='notification_enabled') THEN
        ALTER TABLE public.caregivers DROP COLUMN notification_enabled;
    END IF;
    -- Ensure it doesn't have 'name' as reported in the past error
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caregivers' AND column_name='name') THEN
        ALTER TABLE public.caregivers DROP COLUMN name;
    END IF;
END $$;
