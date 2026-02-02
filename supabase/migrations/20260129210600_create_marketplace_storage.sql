-- Create public bucket for marketplace listing images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'marketplace-images',
    'marketplace-images',
    true,  -- PUBLIC for easy viewing
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- RLS: Anyone can view, authenticated can upload
CREATE POLICY "public_read_marketplace_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'marketplace-images');

CREATE POLICY "authenticated_upload_marketplace_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'marketplace-images');

CREATE POLICY "owners_delete_marketplace_images" ON storage.objects
FOR DELETE TO authenticated  
USING (bucket_id = 'marketplace-images' AND owner = auth.uid());

CREATE POLICY "owners_update_marketplace_images" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'marketplace-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'marketplace-images' AND owner = auth.uid());