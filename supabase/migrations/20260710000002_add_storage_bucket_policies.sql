-- Migration: Add Storage RLS policies for 'profile pics' bucket

-- 1. Allow authenticated users to upload files to 'profile pics' bucket
CREATE POLICY "Allow authenticated uploads to profile pics"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile pics');

-- 2. Allow authenticated users to update files in 'profile pics' bucket
CREATE POLICY "Allow authenticated updates to profile pics"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'profile pics');

-- 3. Allow public read access to files in 'profile pics' bucket
CREATE POLICY "Allow public read access to profile pics"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile pics');
