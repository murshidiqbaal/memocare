-- supabase_migrations/20260222_sos_master.sql

-- Drop table safely if rebuilding
-- DROP TABLE IF EXISTS public.sos_alerts CASCADE;

CREATE TABLE IF NOT EXISTS public.sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  caregiver_id UUID REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'active', -- active | acknowledged | resolved
  triggered_at TIMESTAMPTZ DEFAULT now(),
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  note TEXT
);

-- Indexes for realtime performance and querying
CREATE INDEX IF NOT EXISTS idx_sos_patient ON public.sos_alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_sos_caregiver ON public.sos_alerts(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_sos_time ON public.sos_alerts(triggered_at DESC);

-- Enable RLS
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

-- Policy: Patient can insert own SOS
CREATE POLICY "Patients insert own sos"
ON public.sos_alerts
FOR INSERT
WITH CHECK (auth.uid() = patient_id);

-- Policy: Patient can view own SOS
CREATE POLICY "Patients view own sos"
ON public.sos_alerts
FOR SELECT
USING (auth.uid() = patient_id);

-- Policy: Patient can update own SOS
CREATE POLICY "Patients update own sos"
ON public.sos_alerts
FOR UPDATE
USING (auth.uid() = patient_id);

-- Policy: Caregiver can view linked SOS
CREATE POLICY "Caregivers view linked sos"
ON public.sos_alerts
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_patient_links l
    JOIN public.caregiver_profiles cp
      ON cp.id = l.caregiver_id
    WHERE l.patient_id = sos_alerts.patient_id
      AND cp.user_id = auth.uid()
  )
);

-- Policy: Caregiver can update linked SOS (for acknowledging/resolving)
CREATE POLICY "Caregivers update linked sos"
ON public.sos_alerts
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM public.caregiver_patient_links l
    JOIN public.caregiver_profiles cp
      ON cp.id = l.caregiver_id
    WHERE l.patient_id = sos_alerts.patient_id
      AND cp.user_id = auth.uid()
  )
);

-- Realtime broadcast
ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts;
