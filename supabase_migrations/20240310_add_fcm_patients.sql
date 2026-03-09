-- Add FCM token column to patients table
ALTER TABLE public.patients
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_patients_fcm_token ON public.patients(fcm_token);
