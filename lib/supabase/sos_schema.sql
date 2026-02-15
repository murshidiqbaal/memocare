-- 1. SOS Alerts Table
CREATE TABLE IF NOT EXISTS public.sos_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES public.patients(id) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  status TEXT DEFAULT 'active', -- 'active', 'resolved'
  created_at TIMESTAMPTZ DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

-- 2. Live Locations Table (for continuous tracking)
CREATE TABLE IF NOT EXISTS public.live_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES public.patients(id) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT now()
);

-- 3. RLS Policies

-- Enable RLS
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_locations ENABLE ROW LEVEL SECURITY;

-- SOS ALERTS Policies

-- Patient can view own alerts
CREATE POLICY "Patients view own alerts" ON public.sos_alerts
  FOR SELECT USING (auth.uid() = patient_id);

-- Patient can create alert
CREATE POLICY "Patients create alert" ON public.sos_alerts
  FOR INSERT WITH CHECK (auth.uid() = patient_id);

-- Linked Caregivers can view alerts
CREATE POLICY "Linked Caregivers view alerts" ON public.sos_alerts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = sos_alerts.patient_id
      AND c.user_id = auth.uid()
    )
  );

-- Linked Caregivers can update (resolve) alerts
CREATE POLICY "Linked Caregivers resolve alerts" ON public.sos_alerts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = sos_alerts.patient_id
      AND c.user_id = auth.uid()
    )
  );

-- LIVE LOCATIONS Policies

-- Patient can insert location
CREATE POLICY "Patients insert location" ON public.live_locations
  FOR INSERT WITH CHECK (auth.uid() = patient_id);

-- Patient can view own location history (optional)
CREATE POLICY "Patients view location" ON public.live_locations
  FOR SELECT USING (auth.uid() = patient_id);

-- Linked Caregivers can stream live location
CREATE POLICY "Linked Caregivers stream location" ON public.live_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = live_locations.patient_id
      AND c.user_id = auth.uid()
    )
  );

-- 4. Realtime Subscription Setup (Supabase Realtime)
-- Enable realtime for sos_alerts table so caregivers can subscribe
ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.live_locations;
