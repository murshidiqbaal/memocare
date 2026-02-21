-- Add FCM token column to caregivers table
ALTER TABLE public.caregiver_profiles
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add FCM token column to patients table (optional, for future features)
ALTER TABLE public.patients
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_caregivers_fcm_token ON public.caregiver_profiles(fcm_token);
CREATE INDEX IF NOT EXISTS idx_patients_fcm_token ON public.patients(fcm_token);

-- RLS Policy: Users can update their own FCM token
CREATE POLICY "Users can update own FCM token" ON public.caregiver_profiles
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Patients can update own FCM token" ON public.patients
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Function to send FCM notification (to be called from Supabase Edge Functions)
-- This is a placeholder - actual FCM sending happens via Edge Functions
CREATE OR REPLACE FUNCTION public.notify_caregivers_fcm(
  p_patient_id UUID,
  p_notification_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caregiver_record RECORD;
BEGIN
  -- Get all caregivers linked to this patient with FCM tokens
  FOR v_caregiver_record IN
    SELECT c.fcm_token, c.id as caregiver_id
    FROM public.caregiver_profiles c
    INNER JOIN public.caregiver_patient_links cpl ON c.id = cpl.caregiver_id
    WHERE cpl.patient_id = p_patient_id
      AND c.fcm_token IS NOT NULL
  LOOP
    -- Log notification attempt (for debugging)
    INSERT INTO public.notification_log (
      caregiver_id,
      patient_id,
      notification_type,
      title,
      body,
      data,
      sent_at
    ) VALUES (
      v_caregiver_record.caregiver_id,
      p_patient_id,
      p_notification_type,
      p_title,
      p_body,
      p_data,
      now()
    );
    
    -- Actual FCM sending will be done via Edge Function
    -- This function just logs the intent
  END LOOP;
END;
$$;

-- Create notification log table for tracking
CREATE TABLE IF NOT EXISTS public.notification_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  caregiver_id UUID REFERENCES public.caregiver_profiles(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  sent_at TIMESTAMPTZ DEFAULT now(),
  delivered BOOLEAN DEFAULT false,
  error TEXT
);

-- Enable RLS on notification_log
ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

-- Caregivers can view their own notification logs
CREATE POLICY "Caregivers can view own notification logs" ON public.notification_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_profiles c
      WHERE c.id = notification_log.caregiver_id
        AND c.user_id = auth.uid()
    )
  );
