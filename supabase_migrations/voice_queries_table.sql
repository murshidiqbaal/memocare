-- Voice Queries Table for Voice Assistant Module
-- Stores patient voice interactions and AI responses

-- Create voice_queries table
CREATE TABLE IF NOT EXISTS voice_queries (
  id TEXT PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  query_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Indexes for performance
  CONSTRAINT voice_queries_pkey PRIMARY KEY (id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_voice_queries_patient_id 
  ON voice_queries(patient_id);

CREATE INDEX IF NOT EXISTS idx_voice_queries_created_at 
  ON voice_queries(created_at DESC);

-- Enable Row Level Security
ALTER TABLE voice_queries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Patients can view own queries" ON voice_queries;
DROP POLICY IF EXISTS "Patients can insert own queries" ON voice_queries;
DROP POLICY IF EXISTS "Caregivers can view patient queries" ON voice_queries;

-- Policy: Patients can view their own queries
CREATE POLICY "Patients can view own queries"
  ON voice_queries
  FOR SELECT
  USING (auth.uid() = patient_id);

-- Policy: Patients can insert their own queries
CREATE POLICY "Patients can insert own queries"
  ON voice_queries
  FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Policy: Caregivers can view linked patient queries
CREATE POLICY "Caregivers can view patient queries"
  ON voice_queries
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 
      FROM caregiver_patients
      WHERE caregiver_id = auth.uid()
        AND patient_id = voice_queries.patient_id
    )
  );

-- Grant permissions
GRANT SELECT, INSERT ON voice_queries TO authenticated;

-- Add helpful comments
COMMENT ON TABLE voice_queries IS 'Stores patient voice assistant interactions and AI-generated responses';
COMMENT ON COLUMN voice_queries.id IS 'Unique identifier for the voice query';
COMMENT ON COLUMN voice_queries.patient_id IS 'Reference to the patient who asked the question';
COMMENT ON COLUMN voice_queries.query_text IS 'The question asked by the patient (speech-to-text)';
COMMENT ON COLUMN voice_queries.response_text IS 'AI-generated response to the query';
COMMENT ON COLUMN voice_queries.created_at IS 'Timestamp when the query was created';
