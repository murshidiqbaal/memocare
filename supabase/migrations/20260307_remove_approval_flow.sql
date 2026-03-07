-- =====================================================
-- REMOVE CAREGIVER APPROVAL FLOW
-- =====================================================

-- 1. Drop the caregiver_requests table
DROP TABLE IF EXISTS public.caregiver_requests CASCADE;

-- 2. Update profiles table
DO $$ 
BEGIN
    -- Ensure email column exists as expected by the Dart model
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;

    ALTER TABLE public.profiles 
    DROP CONSTRAINT IF EXISTS profiles_role_check;
    
    ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('patient', 'caregiver', 'admin'));
END $$;

-- 3. Any existing 'pending_caregiver' users should be converted to 'caregiver'
UPDATE public.profiles 
SET role = 'caregiver' 
WHERE role = 'pending_caregiver';
