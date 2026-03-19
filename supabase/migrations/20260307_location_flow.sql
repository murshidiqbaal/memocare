-- 1. Create patient_patient_home_locations Table
-- Stores the actual approved circular geofence for a patient.
CREATE TABLE IF NOT EXISTS public.patient_patient_home_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(patient_id)
);

-- 2. Create location_change_requests Table
-- Stores the pending/history of requests from patients.
CREATE TABLE IF NOT EXISTS public.location_change_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  caregiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requested_latitude DOUBLE PRECISION NOT NULL,
  requested_longitude DOUBLE PRECISION NOT NULL,
  requested_radius_meters INTEGER NOT NULL,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- 3. Enable RLS
ALTER TABLE public.patient_patient_home_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_change_requests ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Patient can read their own safe zone
CREATE POLICY patient_view_safe_zone
ON public.patient_patient_home_locations
FOR SELECT
USING (auth.uid() = patient_id);

-- Patient can insert requests
CREATE POLICY patient_create_request
ON public.location_change_requests
FOR INSERT
WITH CHECK (auth.uid() = patient_id);

-- Caregiver can view requests assigned to them
CREATE POLICY caregiver_view_requests
ON public.location_change_requests
FOR SELECT
USING (auth.uid() = caregiver_id);

-- Caregiver can update requests assigned to them (approve/reject)
CREATE POLICY caregiver_update_requests
ON public.location_change_requests
FOR UPDATE
USING (auth.uid() = caregiver_id);

-- Caregiver can view linked patient safe zone (helper policy)
CREATE POLICY caregiver_view_safe_zone
ON public.patient_patient_home_locations
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.location_change_requests
    WHERE public.location_change_requests.patient_id = public.patient_patient_home_locations.patient_id
      AND public.location_change_requests.caregiver_id = auth.uid()
  )
);
