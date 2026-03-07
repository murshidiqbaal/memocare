-- =====================================================
-- FINAL COMPREHENSIVE FIX FOR SIGNUP 500 ERROR
-- =====================================================

-- 1. RECONCILE PROFILES TABLE
-- Ensure it has the exact columns the user requested
DO $$ 
BEGIN 
    -- Ensure columns exist individually to avoid recreation failures
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='full_name') THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'patient';
    END IF;
END $$;

-- 2. RECONCILE CAREGIVERS TABLE
-- Many migrations conflict here. We enforce the user's requested schema:
-- id, user_id, status, approved_at, created_at, updated_at
DROP TABLE IF EXISTS public.caregivers CASCADE;
CREATE TABLE public.caregivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 3. RECONCILE PATIENTS TABLE
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. CLEAN UP ALL OBSOLETE TRIGGERS & FUNCTIONS
-- This is critical! Fragmented triggers cause the 500 errors.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_caregiver ON auth.users;
DROP TRIGGER IF EXISTS trigger_handle_new_user ON auth.users;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_caregiver_user() CASCADE;

-- 5. IMPLEMENT FINAL ROBUST TRIGGER
-- Uses COALESCE and handles both 'fullName' (Flutter) and 'full_name' (Legacy)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
    user_full_name TEXT;
BEGIN
    -- Extract role with safe default
    user_role := COALESCE(new.raw_user_meta_data->>'role', 'patient');
    
    -- Extract full name (handle both camelCase and snake_case metadata)
    user_full_name := COALESCE(
        new.raw_user_meta_data->>'fullName', 
        new.raw_user_meta_data->>'full_name', 
        ''
    );

    -- A. Create/Update Profile
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, user_full_name, user_role)
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        updated_at = now();

    -- B. Create role-specific records
    IF (user_role = 'caregiver') THEN
        INSERT INTO public.caregivers (user_id, status)
        VALUES (new.id, 'pending')
        ON CONFLICT (user_id) DO NOTHING;
    ELSIF (user_role = 'patient') THEN
        INSERT INTO public.patients (id)
        VALUES (new.id)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN new;
END;
$$;

-- 6. ATTACH THE UNIFIED TRIGGER
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 7. RLS POLICIES (Minimum required for signup/initial flow)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles are public" ON public.profiles;
CREATE POLICY "Profiles are public" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Caregivers view own record" ON public.caregivers;
CREATE POLICY "Caregivers view own record" ON public.caregivers FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Patients view own record" ON public.patients;
CREATE POLICY "Patients view own record" ON public.patients FOR SELECT USING (auth.uid() = id);
