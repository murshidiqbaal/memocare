-- =====================================================
-- FINAL AUTH FIX: SAFE TRIGGER-BASED INITIALIZATION
-- =====================================================

-- 1. Ensure profiles table matches EXACT requirements
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT CHECK (role IN ('patient', 'caregiver', 'admin')) DEFAULT 'patient',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Drop EVERY potential old trigger that might cause 500 errors
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_caregiver ON auth.users;
DROP TRIGGER IF EXISTS trigger_handle_new_user ON auth.users;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_caregiver_user() CASCADE;

-- 3. Consolidated and SAFE Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert into profiles using COALESCE for safety
  -- Reads 'fullName' (camelCase) to match Flutter code requirement
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    created_at
  )
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'fullName', ''),
    COALESCE(new.raw_user_meta_data->>'role', 'patient'),
    now()
  )
  ON CONFLICT (id) DO UPDATE 
  SET email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role;

  -- B. Handle role-specific tables if they exist
  IF (COALESCE(new.raw_user_meta_data->>'role', 'patient') = 'caregiver') THEN
      INSERT INTO public.caregivers (user_id, status)
      VALUES (new.id, 'pending')
      ON CONFLICT (user_id) DO NOTHING;
  ELSIF (COALESCE(new.raw_user_meta_data->>'role', 'patient') = 'patient') THEN
      INSERT INTO public.patients (id)
      VALUES (new.id)
      ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;

-- 4. Re-create the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 5. Ensure RLS allows the trigger (SECURITY DEFINER usually bypasses, but safe to set)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
