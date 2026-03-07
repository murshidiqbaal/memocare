-- =====================================================
-- AUTH ENHANCEMENTS AND TRIGGER-BASED INITIALIZATION
-- =====================================================

-- 1. Ensure profiles table matches user requirements
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    role TEXT CHECK (role IN ('patient', 'caregiver', 'admin')) NOT NULL,
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Update/Define caregivers table to match requested schema
-- Note: id is primary key, user_id references profiles(id)
CREATE TABLE IF NOT EXISTS public.caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- 3. Ensure patients table exists
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. handle_new_user Trigger Function
-- This function automatically creates profile and specialized rows
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_full_name TEXT;
BEGIN
    -- Extract metadata from Auth signup
    user_role := COALESCE(new.raw_user_meta_data->>'role', 'patient');
    user_full_name := new.raw_user_meta_data->>'full_name';

    -- 1. Create Profile
    INSERT INTO public.profiles (id, email, role, full_name)
    VALUES (new.id, new.email, user_role, user_full_name)
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email,
        role = EXCLUDED.role,
        full_name = EXCLUDED.full_name;

    -- 2. Create specialized entry based on role
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

-- 5. Attach trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- RLS POLICIES (Summary)
-- =====================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile and specialized record
CREATE POLICY "Users view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Caregivers view own record" ON public.caregivers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Patients view own record" ON public.patients FOR SELECT USING (auth.uid() = id);
