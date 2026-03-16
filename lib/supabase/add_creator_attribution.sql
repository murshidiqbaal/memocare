-- 1. Correct the Foreign Key Relationship
-- The reminders table should reference the internal PK of caregiver_profiles, NOT the auth UUID.

ALTER TABLE public.reminders
DROP CONSTRAINT IF EXISTS reminders_caregiver_id_fkey;

ALTER TABLE public.reminders
  ADD CONSTRAINT reminders_caregiver_id_fkey
  FOREIGN KEY (caregiver_id) REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE;

-- 2. Add Creator Attribution Tracking
-- This stores the auth.users.id of the person who actually created the reminder.

ALTER TABLE public.reminders
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 3. One-time Data Migration (Cleanup)
-- If any existing reminders stored the auth UUID in the caregiver_id column,
-- this script attempts to switch them to the correct internal profile ID.

UPDATE public.reminders r
SET caregiver_id = cp.id
FROM public.caregiver_profiles cp
WHERE r.caregiver_id = cp.user_id;

-- 4. Remove previous experimentation (if exists)
ALTER TABLE public.reminders DROP COLUMN IF EXISTS created_role;
