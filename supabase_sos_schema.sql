-- Supabase Schema Migration: Hospital-Grade Patient Safety & SOS Monitoring System

-- 1. sos_messages table
CREATE TABLE IF NOT EXISTS public.sos_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    caregiver_id UUID NOT NULL REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'viewed', 'resolved')) DEFAULT 'pending',
    triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    location_lat DOUBLE PRECISION NOT NULL,
    location_lng DOUBLE PRECISION NOT NULL,
    note TEXT
);

-- Enable RLS for sos_messages
ALTER TABLE public.sos_messages ENABLE ROW LEVEL SECURITY;

-- Patients can INSERT their own SOS messages
CREATE POLICY "Patients can create their own SOS"
    ON public.sos_messages FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Caregivers can SELECT SOS messages linked to their ID
CREATE POLICY "Caregivers can view their assigned SOS messages"
    ON public.sos_messages FOR SELECT
    USING (caregiver_id = auth.uid());

-- Caregivers can UPDATE SOS status (e.g., mark 'resolved')
CREATE POLICY "Caregivers can update SOS status"
    ON public.sos_messages FOR UPDATE
    USING (caregiver_id = auth.uid());


-- 2. patient_locations table (Realtime Tracking)
CREATE TABLE IF NOT EXISTS public.patient_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS for patient_locations
ALTER TABLE public.patient_locations ENABLE ROW LEVEL SECURITY;

-- Patients can UPSERT their own location
-- Using ON CONFLICT requires a unique constraint on patient_id if we want exactly 1 row per patient
ALTER TABLE public.patient_locations ADD CONSTRAINT unique_patient_location UNIQUE (patient_id);

CREATE POLICY "Patients can insert/update their own location"
    ON public.patient_locations FOR ALL
    USING (patient_id = auth.uid());

-- Caregivers can read locations for patients they monitor
-- Assuming there's a caregivers_patients mapping table or similar relationship
-- Fallback simplest RLS: authenticated users can read. Adjust based on your linking logic.
CREATE POLICY "Linked caregivers can read locations"
    ON public.patient_locations FOR SELECT
    USING (
        auth.role() = 'authenticated'
        -- Replace with actual relationship check if stricter privacy is needed:
        -- EXISTS (SELECT 1 FROM caregiver_patient_links WHERE caregiver_id = auth.uid() AND patient_id = patient_locations.patient_id)
    );


-- 3. patient_home_locations table
CREATE TABLE IF NOT EXISTS public.patient_home_locations (
    patient_id UUID PRIMARY KEY REFERENCES public.patients(id) ON DELETE CASCADE,
    home_lat DOUBLE PRECISION NOT NULL,
    home_lng DOUBLE PRECISION NOT NULL,
    radius DOUBLE PRECISION NOT NULL DEFAULT 50.0  -- meters
);

-- Enable RLS for patient_home_locations
ALTER TABLE public.patient_home_locations ENABLE ROW LEVEL SECURITY;

-- Caregivers can create/update safe zones for their patients
CREATE POLICY "Caregivers can manage safe zones"
    ON public.patient_home_locations FOR ALL
    USING (auth.role() = 'authenticated'); -- Adjust constraint as needed

-- Patients can read their own safe zone
CREATE POLICY "Patients can view their safe zone"
    ON public.patient_home_locations FOR SELECT
    USING (patient_id = auth.uid());

-- 4. Enable Supabase Realtime for these tables
-- Run this to enable realtime broadcast on these specific tables
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;
alter publication supabase_realtime add table public.sos_messages;
alter publication supabase_realtime add table public.patient_locations;
