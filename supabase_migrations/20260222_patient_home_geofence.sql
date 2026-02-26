-- 1️⃣ Create patient home location table
CREATE TABLE IF NOT EXISTS public.patient_home_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER DEFAULT 1000,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(patient_id)
);

-- 2️⃣ Create location alerts table
CREATE TABLE IF NOT EXISTS public.location_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  caregiver_id UUID REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3️⃣ Enable RLS
ALTER TABLE public.patient_home_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_alerts ENABLE ROW LEVEL SECURITY;

-- 4️⃣ RLS policies

-- Patient manages own home
CREATE POLICY "Patients manage own home"
ON public.patient_home_locations
FOR ALL
USING (auth.uid() = patient_id)
WITH CHECK (auth.uid() = patient_id);

-- Caregiver can read linked patient home
CREATE POLICY "Caregivers view linked patient home"
ON public.patient_home_locations
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_patient_links link
    JOIN public.caregiver_profiles cp
      ON cp.id = link.caregiver_id
    WHERE link.patient_id = patient_home_locations.patient_id
      AND cp.user_id = auth.uid()
  )
);

-- Location alerts policies
CREATE POLICY "Patients view own alerts"
ON public.location_alerts
FOR SELECT
USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers view linked alerts"
ON public.location_alerts
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_profiles cp
    WHERE cp.id = location_alerts.caregiver_id
      AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "System insert alerts"
ON public.location_alerts
FOR INSERT
WITH CHECK (true);
