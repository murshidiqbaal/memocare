-- ============================================================================
-- MEMOCARE - COMPLETE SUPABASE SCHEMA
-- Dementia Care Application - Full Database Setup
-- ============================================================================
-- This file contains all tables, RLS policies, functions, triggers, and
-- storage buckets needed for the complete MemoCare application.
-- ============================================================================

-- ============================================================================
-- 1. ENABLE REQUIRED EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For geospatial queries (optional but recommended)

-- ============================================================================
-- 2. CREATE PROFILES TABLE (User Management)
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  date_of_birth DATE,
  role TEXT NOT NULL CHECK (role IN ('patient', 'caregiver', 'admin')),
  photo_url TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  medical_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Caregivers can view linked patient profiles
CREATE POLICY "Caregivers can view linked patient profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = profiles.id
    )
  );

-- ============================================================================
-- 3. CREATE CAREGIVER_PATIENTS TABLE (Caregiver-Patient Linking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS caregiver_patients (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  caregiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  patient_name TEXT,
  patient_photo_url TEXT,
  relationship TEXT, -- e.g., "Son", "Daughter", "Professional Caregiver"
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique caregiver-patient pairs
  UNIQUE(caregiver_id, patient_id)
);

-- Indexes for caregiver_patients
CREATE INDEX IF NOT EXISTS idx_caregiver_patients_caregiver_id ON caregiver_patients(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patients_patient_id ON caregiver_patients(patient_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patients_is_primary ON caregiver_patients(is_primary) WHERE is_primary = TRUE;

-- Enable RLS
ALTER TABLE caregiver_patients ENABLE ROW LEVEL SECURITY;

-- RLS Policies for caregiver_patients
CREATE POLICY "Caregivers can view own patient links"
  ON caregiver_patients FOR SELECT
  USING (auth.uid() = caregiver_id);

CREATE POLICY "Caregivers can create patient links"
  ON caregiver_patients FOR INSERT
  WITH CHECK (auth.uid() = caregiver_id);

CREATE POLICY "Caregivers can update own links"
  ON caregiver_patients FOR UPDATE
  USING (auth.uid() = caregiver_id);

CREATE POLICY "Caregivers can delete own links"
  ON caregiver_patients FOR DELETE
  USING (auth.uid() = caregiver_id);

-- ============================================================================
-- 4. CREATE REMINDERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS reminders (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('medication', 'appointment', 'task')),
  description TEXT,
  remind_at TIMESTAMP WITH TIME ZONE NOT NULL,
  repeat_rule TEXT NOT NULL DEFAULT 'once' CHECK (repeat_rule IN ('once', 'daily', 'weekly', 'custom')),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  completion_status TEXT NOT NULL DEFAULT 'pending' CHECK (completion_status IN ('pending', 'completed', 'missed')),
  voice_audio_url TEXT,
  completion_history JSONB DEFAULT '[]'::JSONB,
  is_snoozed BOOLEAN DEFAULT FALSE,
  snooze_duration_minutes INTEGER,
  last_snoozed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for reminders
CREATE INDEX IF NOT EXISTS idx_reminders_patient_id ON reminders(patient_id);
CREATE INDEX IF NOT EXISTS idx_reminders_remind_at ON reminders(remind_at);
CREATE INDEX IF NOT EXISTS idx_reminders_completion_status ON reminders(completion_status);
CREATE INDEX IF NOT EXISTS idx_reminders_created_by ON reminders(created_by);

-- Enable RLS
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- RLS Policies for reminders
CREATE POLICY "Patients can view own reminders"
  ON reminders FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own reminders"
  ON reminders FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own reminders"
  ON reminders FOR UPDATE
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can delete own reminders"
  ON reminders FOR DELETE
  USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view linked patient reminders"
  ON reminders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = reminders.patient_id
    )
  );

CREATE POLICY "Caregivers can create reminders for patients"
  ON reminders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = reminders.patient_id
    )
  );

CREATE POLICY "Caregivers can update patient reminders"
  ON reminders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = reminders.patient_id
    )
  );

CREATE POLICY "Caregivers can delete patient reminders"
  ON reminders FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = reminders.patient_id
    )
  );

-- ============================================================================
-- 5. CREATE PEOPLE_CARDS TABLE (Important People)
-- ============================================================================

CREATE TABLE IF NOT EXISTS people_cards (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  voice_audio_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for people_cards
CREATE INDEX IF NOT EXISTS idx_people_cards_patient_id ON people_cards(patient_id);

-- Enable RLS
ALTER TABLE people_cards ENABLE ROW LEVEL SECURITY;

-- RLS Policies for people_cards
CREATE POLICY "Patients can view own people cards"
  ON people_cards FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own people cards"
  ON people_cards FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own people cards"
  ON people_cards FOR UPDATE
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can delete own people cards"
  ON people_cards FOR DELETE
  USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view linked patient people cards"
  ON people_cards FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = people_cards.patient_id
    )
  );

CREATE POLICY "Caregivers can manage patient people cards"
  ON people_cards FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = people_cards.patient_id
    )
  );

-- ============================================================================
-- 6. CREATE MEMORY_CARDS TABLE (Memories/Photos)
-- ============================================================================

CREATE TABLE IF NOT EXISTS memory_cards (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  voice_audio_url TEXT,
  event_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for memory_cards
CREATE INDEX IF NOT EXISTS idx_memory_cards_patient_id ON memory_cards(patient_id);
CREATE INDEX IF NOT EXISTS idx_memory_cards_event_date ON memory_cards(event_date);

-- Enable RLS
ALTER TABLE memory_cards ENABLE ROW LEVEL SECURITY;

-- RLS Policies for memory_cards
CREATE POLICY "Patients can view own memory cards"
  ON memory_cards FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own memory cards"
  ON memory_cards FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own memory cards"
  ON memory_cards FOR UPDATE
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can delete own memory cards"
  ON memory_cards FOR DELETE
  USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view linked patient memory cards"
  ON memory_cards FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = memory_cards.patient_id
    )
  );

CREATE POLICY "Caregivers can manage patient memory cards"
  ON memory_cards FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = memory_cards.patient_id
    )
  );

-- ============================================================================
-- 7. CREATE VOICE_QUERIES TABLE (Voice Assistant Interactions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS voice_queries (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  query_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for voice_queries
CREATE INDEX IF NOT EXISTS idx_voice_queries_patient_id ON voice_queries(patient_id);
CREATE INDEX IF NOT EXISTS idx_voice_queries_created_at ON voice_queries(created_at DESC);

-- Enable RLS
ALTER TABLE voice_queries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for voice_queries
CREATE POLICY "Patients can view own queries"
  ON voice_queries FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own queries"
  ON voice_queries FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view patient queries"
  ON voice_queries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = voice_queries.patient_id
    )
  );

-- ============================================================================
-- 8. CREATE SAFE_ZONES TABLE (Geofencing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS safe_zones (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius DOUBLE PRECISION NOT NULL, -- in meters
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for safe_zones
CREATE INDEX IF NOT EXISTS idx_safe_zones_patient_id ON safe_zones(patient_id);

-- Enable RLS
ALTER TABLE safe_zones ENABLE ROW LEVEL SECURITY;

-- RLS Policies for safe_zones
CREATE POLICY "Patients can view own safe zones"
  ON safe_zones FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view patient safe zones"
  ON safe_zones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = safe_zones.patient_id
    )
  );

CREATE POLICY "Caregivers can manage patient safe zones"
  ON safe_zones FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = safe_zones.patient_id
    )
  );

-- ============================================================================
-- 9. CREATE LOCATION_LOGS TABLE (GPS Tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS location_logs (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_breach BOOLEAN DEFAULT FALSE,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for location_logs
CREATE INDEX IF NOT EXISTS idx_location_logs_patient_id ON location_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_logs_recorded_at ON location_logs(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_logs_is_breach ON location_logs(is_breach) WHERE is_breach = TRUE;

-- Enable RLS
ALTER TABLE location_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for location_logs
CREATE POLICY "Patients can view own location logs"
  ON location_logs FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own location logs"
  ON location_logs FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view patient location logs"
  ON location_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = location_logs.patient_id
    )
  );

-- ============================================================================
-- 10. CREATE GAME_SESSIONS TABLE (Cognitive Games Analytics)
-- ============================================================================

CREATE TABLE IF NOT EXISTS game_sessions (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL CHECK (game_type IN ('memory_match', 'face_recognition', 'word_association')),
  score INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for game_sessions
CREATE INDEX IF NOT EXISTS idx_game_sessions_patient_id ON game_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_game_type ON game_sessions(game_type);
CREATE INDEX IF NOT EXISTS idx_game_sessions_created_at ON game_sessions(created_at DESC);

-- Enable RLS
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for game_sessions
CREATE POLICY "Patients can view own game sessions"
  ON game_sessions FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own game sessions"
  ON game_sessions FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Caregivers can view patient game sessions"
  ON game_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
      AND patient_id = game_sessions.patient_id
    )
  );

-- ============================================================================
-- 11. FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER trigger_update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_caregiver_patients_updated_at
  BEFORE UPDATE ON caregiver_patients
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_reminders_updated_at
  BEFORE UPDATE ON reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_people_cards_updated_at
  BEFORE UPDATE ON people_cards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_memory_cards_updated_at
  BEFORE UPDATE ON memory_cards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_safe_zones_updated_at
  BEFORE UPDATE ON safe_zones
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure only one primary caregiver per patient
CREATE OR REPLACE FUNCTION ensure_single_primary_caregiver()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = TRUE THEN
    -- Unset other primary caregivers for this patient
    UPDATE caregiver_patients
    SET is_primary = FALSE
    WHERE patient_id = NEW.patient_id
    AND id != NEW.id
    AND is_primary = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce single primary caregiver
CREATE TRIGGER trigger_ensure_single_primary_caregiver
  BEFORE INSERT OR UPDATE ON caregiver_patients
  FOR EACH ROW
  EXECUTE FUNCTION ensure_single_primary_caregiver();

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'patient'),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 12. HELPER FUNCTIONS FOR ANALYTICS
-- ============================================================================

-- Function to get reminder adherence rate for a patient
CREATE OR REPLACE FUNCTION get_reminder_adherence_rate(p_patient_id UUID, p_days INTEGER DEFAULT 7)
RETURNS NUMERIC AS $$
DECLARE
  total_reminders INTEGER;
  completed_reminders INTEGER;
  adherence_rate NUMERIC;
BEGIN
  SELECT COUNT(*) INTO total_reminders
  FROM reminders
  WHERE patient_id = p_patient_id
  AND remind_at >= NOW() - (p_days || ' days')::INTERVAL
  AND remind_at <= NOW();

  SELECT COUNT(*) INTO completed_reminders
  FROM reminders
  WHERE patient_id = p_patient_id
  AND completion_status = 'completed'
  AND remind_at >= NOW() - (p_days || ' days')::INTERVAL
  AND remind_at <= NOW();

  IF total_reminders = 0 THEN
    RETURN 0;
  END IF;

  adherence_rate := (completed_reminders::NUMERIC / total_reminders::NUMERIC) * 100;
  RETURN ROUND(adherence_rate, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get weekly game performance
CREATE OR REPLACE FUNCTION get_weekly_game_stats(p_patient_id UUID)
RETURNS TABLE(
  game_type TEXT,
  total_sessions BIGINT,
  avg_score NUMERIC,
  total_duration_minutes NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    gs.game_type,
    COUNT(*) as total_sessions,
    ROUND(AVG(gs.score), 2) as avg_score,
    ROUND(SUM(gs.duration_seconds) / 60.0, 2) as total_duration_minutes
  FROM game_sessions gs
  WHERE gs.patient_id = p_patient_id
  AND gs.created_at >= NOW() - INTERVAL '7 days'
  GROUP BY gs.game_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if location is within safe zone
CREATE OR REPLACE FUNCTION is_location_safe(
  p_patient_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
DECLARE
  is_safe BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM safe_zones
    WHERE patient_id = p_patient_id
    AND (
      -- Simple distance calculation (works for small distances)
      6371000 * ACOS(
        COS(RADIANS(p_latitude)) * COS(RADIANS(latitude)) *
        COS(RADIANS(longitude) - RADIANS(p_longitude)) +
        SIN(RADIANS(p_latitude)) * SIN(RADIANS(latitude))
      )
    ) <= radius
  ) INTO is_safe;
  
  RETURN COALESCE(is_safe, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 13. STORAGE BUCKETS (Run these in Supabase Dashboard > Storage)
-- ============================================================================

-- Note: Storage buckets must be created via Supabase Dashboard or API
-- Here are the SQL commands to set up RLS policies for storage buckets

-- Create storage buckets (run in Supabase Dashboard):
-- 1. profile-photos
-- 2. reminder-audio
-- 3. people-photos
-- 4. people-audio
-- 5. memory-photos
-- 6. memory-audio

-- Storage RLS policies (apply after creating buckets):

-- Profile Photos Bucket Policies
CREATE POLICY "Users can upload own profile photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos' AND
    auth.uid()::TEXT = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own profile photo"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-photos');

CREATE POLICY "Users can update own profile photo"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::TEXT = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own profile photo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::TEXT = (storage.foldername(name))[1]
  );

-- Reminder Audio Bucket Policies
CREATE POLICY "Users can upload reminder audio"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'reminder-audio');

CREATE POLICY "Users can view reminder audio"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'reminder-audio');

-- People Photos Bucket Policies
CREATE POLICY "Patients can manage people photos"
  ON storage.objects FOR ALL
  USING (bucket_id = 'people-photos');

-- People Audio Bucket Policies
CREATE POLICY "Patients can manage people audio"
  ON storage.objects FOR ALL
  USING (bucket_id = 'people-audio');

-- Memory Photos Bucket Policies
CREATE POLICY "Patients can manage memory photos"
  ON storage.objects FOR ALL
  USING (bucket_id = 'memory-photos');

-- Memory Audio Bucket Policies
CREATE POLICY "Patients can manage memory audio"
  ON storage.objects FOR ALL
  USING (bucket_id = 'memory-audio');

-- ============================================================================
-- 14. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================================================
-- 15. SAMPLE DATA (FOR TESTING - OPTIONAL)
-- ============================================================================

-- Insert sample patient profile
-- INSERT INTO profiles (id, email, full_name, role, phone)
-- VALUES (
--   '00000000-0000-0000-0000-000000000001'::UUID,
--   'patient@example.com',
--   'John Doe',
--   'patient',
--   '+1234567890'
-- );

-- Insert sample caregiver profile
-- INSERT INTO profiles (id, email, full_name, role, phone)
-- VALUES (
--   '00000000-0000-0000-0000-000000000002'::UUID,
--   'caregiver@example.com',
--   'Jane Smith',
--   'caregiver',
--   '+0987654321'
-- );

-- Link caregiver to patient
-- INSERT INTO caregiver_patients (caregiver_id, patient_id, relationship, is_primary)
-- VALUES (
--   '00000000-0000-0000-0000-000000000002'::UUID,
--   '00000000-0000-0000-0000-000000000001'::UUID,
--   'Daughter',
--   TRUE
-- );

-- ============================================================================
-- 16. VERIFICATION QUERIES
-- ============================================================================

-- Check all tables
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check all RLS policies
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- Check all indexes
-- SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public';

-- Check all triggers
-- SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public';

-- ============================================================================
-- 17. CLEANUP/ROLLBACK (IF NEEDED)
-- ============================================================================

-- WARNING: This will delete all data!
-- Uncomment only if you need to reset the database

-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP TRIGGER IF EXISTS trigger_ensure_single_primary_caregiver ON caregiver_patients;
-- DROP TRIGGER IF EXISTS trigger_update_profiles_updated_at ON profiles;
-- DROP TRIGGER IF EXISTS trigger_update_caregiver_patients_updated_at ON caregiver_patients;
-- DROP TRIGGER IF EXISTS trigger_update_reminders_updated_at ON reminders;
-- DROP TRIGGER IF EXISTS trigger_update_people_cards_updated_at ON people_cards;
-- DROP TRIGGER IF EXISTS trigger_update_memory_cards_updated_at ON memory_cards;
-- DROP TRIGGER IF EXISTS trigger_update_safe_zones_updated_at ON safe_zones;

-- DROP FUNCTION IF EXISTS handle_new_user();
-- DROP FUNCTION IF EXISTS update_updated_at_column();
-- DROP FUNCTION IF EXISTS ensure_single_primary_caregiver();
-- DROP FUNCTION IF EXISTS get_reminder_adherence_rate(UUID, INTEGER);
-- DROP FUNCTION IF EXISTS get_weekly_game_stats(UUID);
-- DROP FUNCTION IF EXISTS is_location_safe(UUID, DOUBLE PRECISION, DOUBLE PRECISION);

-- DROP TABLE IF EXISTS game_sessions CASCADE;
-- DROP TABLE IF EXISTS location_logs CASCADE;
-- DROP TABLE IF EXISTS safe_zones CASCADE;
-- DROP TABLE IF EXISTS voice_queries CASCADE;
-- DROP TABLE IF EXISTS memory_cards CASCADE;
-- DROP TABLE IF EXISTS people_cards CASCADE;
-- DROP TABLE IF EXISTS reminders CASCADE;
-- DROP TABLE IF EXISTS caregiver_patients CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- NOTES:
-- 1. Run this script in your Supabase SQL Editor
-- 2. Create storage buckets manually in Supabase Dashboard > Storage
-- 3. Update your .env file with Supabase URL and anon key
-- 4. Test RLS policies with different user roles
-- 5. Monitor performance and add indexes as needed
-- 6. Set up realtime subscriptions for live updates (optional)
