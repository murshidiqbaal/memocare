-- ============================================================================
-- Push Notification Pipeline — Production Schema
-- ============================================================================
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================================

-- 1. Ensure fcm_token columns exist on both tables
ALTER TABLE public.caregiver_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ============================================================================
-- 2. notification_log — production version
--    Tracks every push notification attempt + delivery status
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notification_log (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id        UUID REFERENCES public.patients(id) ON DELETE CASCADE,
  caregiver_id      UUID REFERENCES public.caregiver_profiles(id) ON DELETE SET NULL,
  reminder_id       UUID,  -- soft ref (reminders may be deleted)
  notification_type TEXT NOT NULL,
  title             TEXT NOT NULL,
  body              TEXT NOT NULL,
  data              JSONB DEFAULT '{}'::jsonb,
  sent_at           TIMESTAMPTZ DEFAULT now(),
  delivered         BOOLEAN DEFAULT false,
  error             TEXT
);

-- Indexes for fast querying
CREATE INDEX IF NOT EXISTS idx_notif_log_patient   ON public.notification_log(patient_id);
CREATE INDEX IF NOT EXISTS idx_notif_log_sent_at   ON public.notification_log(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_log_type      ON public.notification_log(notification_type);

-- Enable RLS
ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

-- Caregivers can see notification logs for patients they are linked to
CREATE POLICY IF NOT EXISTS "Caregivers can view notification logs for their patients"
  ON public.notification_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.caregiver_patient_links cpl
      JOIN public.caregiver_profiles cp ON cp.id = cpl.caregiver_id
      WHERE cpl.patient_id = notification_log.patient_id
        AND cp.user_id = auth.uid()
    )
  );

-- Edge Functions (service role) can insert logs
-- (Service role bypasses RLS by default — no policy needed for INSERT with service role)

-- ============================================================================
-- 3. FCM token indexes for fast lookup
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_caregiver_fcm_token ON public.caregiver_profiles(fcm_token)
  WHERE fcm_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patients_fcm_token ON public.patients(fcm_token)
  WHERE fcm_token IS NOT NULL;

-- ============================================================================
-- 4. Missed reminder detection function
--    Called by pg_cron every 5 minutes to mark overdue reminders as missed
--    and invoke the Edge Function for push notifications.
--
--    Enable pg_cron in Supabase:
--    Dashboard → Database → Extensions → cron
--
--    Then schedule it:
--    SELECT cron.schedule('mark-missed-reminders', '*/5 * * * *',
--      $$CALL public.process_missed_reminders()$$);
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_missed_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reminder RECORD;
  v_missed_count INT := 0;
BEGIN
  -- Find reminders that are past due by > 15 minutes and still pending
  FOR v_reminder IN
    SELECT id, patient_id, title, remind_at
    FROM public.reminders
    WHERE completion_status = 'pending'
      AND remind_at < (now() - INTERVAL '15 minutes')
      AND is_snoozed = false
    LIMIT 50  -- process in batches to avoid timeout
  LOOP
    -- Mark as missed
    UPDATE public.reminders
    SET completion_status = 'missed'
    WHERE id = v_reminder.id;

    -- Log the missed event (Edge Function will be triggered separately)
    INSERT INTO public.notification_log (
      patient_id,
      reminder_id,
      notification_type,
      title,
      body,
      sent_at,
      delivered
    ) VALUES (
      v_reminder.patient_id,
      v_reminder.id,
      'reminder_missed',
      '⚠️ Missed Reminder',
      v_reminder.title || ' was not completed',
      now(),
      false  -- will be marked true when Edge Function confirms delivery
    );

    v_missed_count := v_missed_count + 1;
  END LOOP;

  RAISE NOTICE 'Marked % reminders as missed', v_missed_count;
END;
$$;

-- ============================================================================
-- 5. Supabase Database Webhook (optional alternative to cron)
--    Triggers the Edge Function when a reminder is inserted/updated.
--    Configure in: Dashboard → Database → Webhooks
--
--    Name:   on_reminder_change
--    Table:  reminders
--    Events: INSERT, UPDATE
--    URL:    {SUPABASE_URL}/functions/v1/send-reminder-notification
--    Headers:
--      Authorization: Bearer {SUPABASE_ANON_KEY}
--      Content-Type: application/json
-- ============================================================================

-- ============================================================================
-- 6. RLS: Service role can update FCM tokens for any user
--    (Used by Edge Function when clearing stale tokens)
-- ============================================================================

-- Patients can update their own FCM token
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'patients' AND policyname = 'Patients can update own FCM token'
  ) THEN
    CREATE POLICY "Patients can update own FCM token" ON public.patients
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END;
$$;

-- Caregivers can update their own FCM token  
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'caregiver_profiles'
      AND policyname = 'Caregivers can update own FCM token'
  ) THEN
    CREATE POLICY "Caregivers can update own FCM token" ON public.caregiver_profiles
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END;
$$;
