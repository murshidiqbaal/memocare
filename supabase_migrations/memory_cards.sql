-- Memory Cards Table for storing patient memories
-- Managed by caregivers, viewed by patients

CREATE TABLE IF NOT EXISTS public.memory_cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  voice_audio_url TEXT,
  event_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create index for faster patient queries
CREATE INDEX IF NOT EXISTS idx_memory_cards_patient_id ON public.memory_cards(patient_id);
CREATE INDEX IF NOT EXISTS idx_memory_cards_event_date ON public.memory_cards(event_date DESC);

-- Enable Row Level Security
ALTER TABLE public.memory_cards ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can view their own memories
CREATE POLICY "Patients can view own memories" ON public.memory_cards
  FOR SELECT USING (auth.uid() = patient_id);

-- Linked caregivers can view patient memories
CREATE POLICY "Linked caregivers can view patient memories" ON public.memory_cards
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
  );

-- Linked caregivers can insert memories for their patients
CREATE POLICY "Linked caregivers can create memories" ON public.memory_cards
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
  );

-- Linked caregivers can update memories for their patients
CREATE POLICY "Linked caregivers can update memories" ON public.memory_cards
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
  );

-- Linked caregivers can delete memories for their patients
CREATE POLICY "Linked caregivers can delete memories" ON public.memory_cards
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.caregiver_patient_links link
      JOIN public.caregivers c ON link.caregiver_id = c.id
      WHERE link.patient_id = memory_cards.patient_id 
        AND c.user_id = auth.uid()
    )
  );

-- Create storage bucket for memory photos if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('memory_photos', 'memory_photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for memory_photos bucket
CREATE POLICY "Authenticated users can upload memory photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'memory_photos');

CREATE POLICY "Anyone can view memory photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'memory_photos');

CREATE POLICY "Caregivers can update their uploaded photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'memory_photos');

CREATE POLICY "Caregivers can delete their uploaded photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'memory_photos');
