-- lib/supabase/sos_policies.sql
-- Run these in your Supabase SQL Editor to enable SOS security.

-- 1. Enable RLS
alter table sos_messages enable row level security;

-- 2. Allow patient to insert SOS
-- Assumes patient_id is a foreign key to patients(id)
-- and patients(id) is associated with auth.uid() via user_id
create policy "patient insert sos"
on sos_messages
for insert
to authenticated
with check (
  exists (
    select 1 from patients
    where patients.id = patient_id
    and patients.user_id = auth.uid()
  )
);

-- 3. Allow caregiver to read directed SOS alerts
create policy "caregiver read sos"
on sos_messages
for select
to authenticated
using (auth.uid() = caregiver_id);

-- 4. Allow patient to read their own alerts
create policy "patient read own sos"
on sos_messages
for select
to authenticated
using (
  exists (
    select 1 from patients
    where patients.id = patient_id
    and patients.user_id = auth.uid()
  )
);

-- 5. Allow caregiver to update status (acknowledge/resolve)
create policy "caregiver update sos"
on sos_messages
for update
to authenticated
using (auth.uid() = caregiver_id)
with check (auth.uid() = caregiver_id);

----------------------------------------------------------------
-- VERIFICATION SQL (STEP 7)
----------------------------------------------------------------
-- Replace 'AUTH_USER_ID' with a real auth.users.id
-- Replace 'PATIENT_UUID' with a real patients.id

-- Test insert
-- insert into sos_messages
-- (patient_id, lat, lng, triggered_at, status, note)
-- values
-- ('PATIENT_UUID', 9.8991, 76.7166, now(), 'pending', 'Manual Test SOS');
