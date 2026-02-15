-- 1. Auto-Create Caregiver Profile Trigger
-- Trigger function
CREATE OR REPLACE FUNCTION public.handle_new_caregiver_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the new user has the role 'caregiver'
  -- Assuming 'role' is stored in raw_user_meta_data or a separate profiles table
  -- Adjust the condition based on how you store roles. 
  -- Example: IF new.raw_user_meta_data->>'role' = 'caregiver' THEN
  
  -- Insert safely (if not exists)
  INSERT INTO public.caregivers (user_id, notification_enabled)
  VALUES (new.id, true)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN new;
END;
$$;

-- Trigger definition
DROP TRIGGER IF EXISTS on_auth_user_created_caregiver ON auth.users;
CREATE TRIGGER on_auth_user_created_caregiver
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_caregiver_user();


-- 2. Row Level Security (RLS) Policies
-- Enable RLS
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;

-- Policy: Caregiver can view their own profile
CREATE POLICY "Caregivers can view own profile"
  ON public.caregivers
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Caregiver can update their own profile
CREATE POLICY "Caregivers can update own profile"
  ON public.caregivers
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Caregivers can insert their own profile (in case trigger fails or manual creation)
CREATE POLICY "Caregivers can insert own profile"
  ON public.caregivers
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
