-- ============================================================================
-- FIX: MEMORY PHOTOS BUCKET RE-ALIGNMENT
-- ============================================================================
-- Renames/Configures the storage bucket specifically to "memory-photos"
-- as opposed to "memory_photos" ensuring proper matching with the Flutter app
-- ============================================================================

-- Create storage bucket for memory-photos if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'memory-photos', 
    'memory-photos', 
    true, 
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/heic']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS for the exact bucket logic
-- (In case RLS is missing on the broader storage.objects)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop old policies on the old name to keep things clean (optional, doesn't break if missing)
DROP POLICY IF EXISTS "Authenticated users can upload memory photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view memory photos" ON storage.objects;
DROP POLICY IF EXISTS "Caregivers can update their uploaded photos" ON storage.objects;
DROP POLICY IF EXISTS "Caregivers can delete their uploaded photos" ON storage.objects;

-- Storage policies strictly for "memory-photos"
CREATE POLICY "Authenticated users can upload memory photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'memory-photos');

CREATE POLICY "Anyone can view memory photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'memory-photos');

CREATE POLICY "Caregivers can update their uploaded photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'memory-photos');

CREATE POLICY "Caregivers can delete their uploaded photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'memory-photos');
