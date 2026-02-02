-- =====================================================
-- MARKETPLACE COMPLETE SETUP MIGRATION
-- Purpose: Fix empty marketplace by adding categories, store collaborators, and comprehensive seed data
-- =====================================================

-- ========== STEP 1: CREATE CATEGORIES TABLE ==========
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ar TEXT,
    type TEXT NOT NULL CHECK (type IN ('marketplace', 'service', 'product')),
    icon TEXT,
    description TEXT,
    description_ar TEXT,
    parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON public.categories(parent_id);

-- ========== STEP 2: CREATE STORE COLLABORATORS TABLE ==========
DROP TYPE IF EXISTS public.collaborator_role CASCADE;
CREATE TYPE public.collaborator_role AS ENUM ('owner', 'admin', 'editor', 'viewer');

CREATE TABLE IF NOT EXISTS public.store_collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role public.collaborator_role NOT NULL DEFAULT 'viewer',
    permissions JSONB DEFAULT '{}',
    invited_by UUID REFERENCES public.users(id),
    invited_at TIMESTAMPTZ DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(store_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_store_collaborators_store_id ON public.store_collaborators(store_id);
CREATE INDEX IF NOT EXISTS idx_store_collaborators_user_id ON public.store_collaborators(user_id);

-- ========== STEP 3: ADD MISSING COLUMNS TO EXISTING TABLES ==========
-- Add owner_user_id to stores if not exists
ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS owner_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;

-- Add listing_type to marketplace_listings if not exists
DROP TYPE IF EXISTS public.listing_type CASCADE;
CREATE TYPE public.listing_type AS ENUM ('product', 'service', 'request');

ALTER TABLE public.marketplace_listings
ADD COLUMN IF NOT EXISTS listing_type public.listing_type DEFAULT 'product',
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'expired', 'removed'));

CREATE INDEX IF NOT EXISTS idx_marketplace_listings_store_id ON public.marketplace_listings(store_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_category_id ON public.marketplace_listings(category_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_listing_type ON public.marketplace_listings(listing_type);

-- ========== STEP 4: ENABLE RLS ==========
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_collaborators ENABLE ROW LEVEL SECURITY;

-- ========== STEP 5: RLS POLICIES ==========

-- Categories: Public read, admin write
DROP POLICY IF EXISTS "public_read_categories" ON public.categories;
CREATE POLICY "public_read_categories"
ON public.categories
FOR SELECT
TO public
USING (is_active = true);

DROP POLICY IF EXISTS "authenticated_manage_categories" ON public.categories;
CREATE POLICY "authenticated_manage_categories"
ON public.categories
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Store Collaborators: Users manage their own collaborations
DROP POLICY IF EXISTS "users_view_store_collaborators" ON public.store_collaborators;
CREATE POLICY "users_view_store_collaborators"
ON public.store_collaborators
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid() OR
    store_id IN (
        SELECT id FROM public.stores WHERE owner_user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "store_owners_manage_collaborators" ON public.store_collaborators;
CREATE POLICY "store_owners_manage_collaborators"
ON public.store_collaborators
FOR ALL
TO authenticated
USING (
    store_id IN (
        SELECT id FROM public.stores WHERE owner_user_id = auth.uid()
    )
)
WITH CHECK (
    store_id IN (
        SELECT id FROM public.stores WHERE owner_user_id = auth.uid()
    )
);

-- Enhanced Stores RLS: Owner + Collaborators
DROP POLICY IF EXISTS "users_view_stores" ON public.stores;
CREATE POLICY "users_view_stores"
ON public.stores
FOR SELECT
TO authenticated
USING (
    is_active = true AND (
        owner_user_id = auth.uid() OR
        id IN (
            SELECT store_id FROM public.store_collaborators 
            WHERE user_id = auth.uid() AND is_active = true
        )
    )
);

DROP POLICY IF EXISTS "users_manage_own_stores" ON public.stores;
CREATE POLICY "users_manage_own_stores"
ON public.stores
FOR ALL
TO authenticated
USING (owner_user_id = auth.uid())
WITH CHECK (owner_user_id = auth.uid());

-- Enhanced Marketplace Listings RLS: Owner + Store Collaborators
DROP POLICY IF EXISTS "public_read_active_listings" ON public.marketplace_listings;
CREATE POLICY "public_read_active_listings"
ON public.marketplace_listings
FOR SELECT
TO public
USING (is_active = true AND status = 'active');

DROP POLICY IF EXISTS "users_manage_own_listings" ON public.marketplace_listings;
CREATE POLICY "users_manage_own_listings"
ON public.marketplace_listings
FOR ALL
TO authenticated
USING (
    user_id = auth.uid() OR
    (store_id IS NOT NULL AND store_id IN (
        SELECT store_id FROM public.store_collaborators 
        WHERE user_id = auth.uid() AND is_active = true AND role IN ('owner', 'admin', 'editor')
    ))
)
WITH CHECK (
    user_id = auth.uid() OR
    (store_id IS NOT NULL AND store_id IN (
        SELECT store_id FROM public.store_collaborators 
        WHERE user_id = auth.uid() AND is_active = true AND role IN ('owner', 'admin', 'editor')
    ))
);

-- Services RLS: Public read, provider manage
DROP POLICY IF EXISTS "public_read_active_services" ON public.services;
CREATE POLICY "public_read_active_services"
ON public.services
FOR SELECT
TO public
USING (is_active = true);

DROP POLICY IF EXISTS "providers_manage_own_services" ON public.services;
CREATE POLICY "providers_manage_own_services"
ON public.services
FOR ALL
TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

-- ========== STEP 6: SEED DATA ==========

DO $$
DECLARE
    -- Category IDs
    cat_electronics_id UUID := gen_random_uuid();
    cat_furniture_id UUID := gen_random_uuid();
    cat_clothing_id UUID := gen_random_uuid();
    cat_home_id UUID := gen_random_uuid();
    cat_vehicles_id UUID := gen_random_uuid();
    cat_sports_id UUID := gen_random_uuid();
    cat_books_id UUID := gen_random_uuid();
    cat_other_id UUID := gen_random_uuid();
    
    -- Service Category IDs
    cat_taxi_id UUID := gen_random_uuid();
    cat_towing_id UUID := gen_random_uuid();
    cat_water_id UUID := gen_random_uuid();
    cat_diesel_id UUID := gen_random_uuid();
    cat_chef_id UUID := gen_random_uuid();
    cat_trainer_id UUID := gen_random_uuid();
    cat_driver_id UUID := gen_random_uuid();
    cat_cleaning_id UUID := gen_random_uuid();
    cat_handyman_id UUID := gen_random_uuid();
    
    -- User IDs
    existing_user_id UUID;
    demo_seller_id UUID;
    demo_provider_id UUID;
    
    -- Store IDs
    demo_store_id UUID := gen_random_uuid();
    electronics_store_id UUID := gen_random_uuid();
    
BEGIN
    -- Get existing users or create demo users
    SELECT id INTO existing_user_id FROM public.users WHERE role = 'customer' LIMIT 1;
    
    IF existing_user_id IS NULL THEN
        RAISE NOTICE 'No existing users found. Creating demo users...';
        
        -- Create demo seller
        demo_seller_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
            is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
            recovery_token, recovery_sent_at, email_change_token_new, email_change,
            email_change_sent_at, email_change_token_current, email_change_confirm_status,
            reauthentication_token, reauthentication_sent_at, phone, phone_change,
            phone_change_token, phone_change_sent_at
        ) VALUES (
            demo_seller_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'seller@marketplace.com', crypt('seller123', gen_salt('bf', 10)), now(), now(), now(),
            jsonb_build_object('full_name', 'Demo Seller', 'role', 'customer'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, '+9613167968', '', '', null
        ) ON CONFLICT (id) DO NOTHING;
        
        INSERT INTO public.users (id, email, full_name, phone, role, is_verified, is_active)
        VALUES (demo_seller_id, 'seller@marketplace.com', 'Demo Seller', '+9613167968', 'customer', true, true)
        ON CONFLICT (id) DO NOTHING;
        
        -- Create demo service provider
        demo_provider_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
            is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
            recovery_token, recovery_sent_at, email_change_token_new, email_change,
            email_change_sent_at, email_change_token_current, email_change_confirm_status,
            reauthentication_token, reauthentication_sent_at, phone, phone_change,
            phone_change_token, phone_change_sent_at
        ) VALUES (
            demo_provider_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'provider@marketplace.com', crypt('provider123', gen_salt('bf', 10)), now(), now(), now(),
            jsonb_build_object('full_name', 'Service Provider', 'role', 'customer'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, '+9613167969', '', '', null
        ) ON CONFLICT (id) DO NOTHING;
        
        INSERT INTO public.users (id, email, full_name, phone, role, is_verified, is_active)
        VALUES (demo_provider_id, 'provider@marketplace.com', 'Service Provider', '+9613167969', 'customer', true, true)
        ON CONFLICT (id) DO NOTHING;
        
        existing_user_id := demo_seller_id;
    ELSE
        demo_seller_id := existing_user_id;
        SELECT id INTO demo_provider_id FROM public.users WHERE role = 'customer' AND id != demo_seller_id LIMIT 1;
        IF demo_provider_id IS NULL THEN
            demo_provider_id := demo_seller_id;
        END IF;
    END IF;
    
    -- ========== INSERT CATEGORIES ==========
    
    -- Marketplace Product Categories
    INSERT INTO public.categories (id, name, name_ar, type, icon, description, sort_order, is_active) VALUES
        (cat_electronics_id, 'Electronics', 'إلكترونيات', 'marketplace', 'phone_iphone', 'Phones, laptops, gadgets', 1, true),
        (cat_furniture_id, 'Furniture', 'أثاث', 'marketplace', 'chair', 'Home and office furniture', 2, true),
        (cat_clothing_id, 'Clothing', 'ملابس', 'marketplace', 'checkroom', 'Fashion and apparel', 3, true),
        (cat_home_id, 'Home & Garden', 'منزل وحديقة', 'marketplace', 'home', 'Home decor and garden items', 4, true),
        (cat_vehicles_id, 'Vehicles', 'مركبات', 'marketplace', 'directions_car', 'Cars, bikes, and parts', 5, true),
        (cat_sports_id, 'Sports & Outdoors', 'رياضة', 'marketplace', 'sports_soccer', 'Sports equipment and gear', 6, true),
        (cat_books_id, 'Books & Media', 'كتب', 'marketplace', 'menu_book', 'Books, music, movies', 7, true),
        (cat_other_id, 'Other', 'أخرى', 'marketplace', 'category', 'Miscellaneous items', 8, true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Service Categories
    INSERT INTO public.categories (id, name, name_ar, type, icon, description, sort_order, is_active) VALUES
        (cat_taxi_id, 'Taxi Service', 'تاكسي', 'service', 'local_taxi', 'Quick rides around town', 1, true),
        (cat_towing_id, 'Towing Service', 'سحب مركبات', 'service', 'car_repair', 'Vehicle towing and recovery', 2, true),
        (cat_water_id, 'Water Delivery', 'توصيل مياه', 'service', 'water_drop', 'Fresh water delivery', 3, true),
        (cat_diesel_id, 'Diesel Delivery', 'توصيل ديزل', 'service', 'local_gas_station', 'Fuel delivery service', 4, true),
        (cat_chef_id, 'Private Chef', 'طاهي خاص', 'service', 'restaurant', 'Personal cooking service', 5, true),
        (cat_trainer_id, 'Personal Trainer', 'مدرب شخصي', 'service', 'fitness_center', 'Fitness coaching', 6, true),
        (cat_driver_id, 'Private Driver', 'سائق خاص', 'service', 'drive_eta', 'Personal driver service', 7, true),
        (cat_cleaning_id, 'Cleaning Service', 'تنظيف', 'service', 'cleaning_services', 'Home and office cleaning', 8, true),
        (cat_handyman_id, 'Handyman', 'صيانة', 'service', 'handyman', 'Repairs and maintenance', 9, true)
    ON CONFLICT (id) DO NOTHING;
    
    -- ========== INSERT STORES ==========
    
    INSERT INTO public.stores (id, merchant_id, owner_user_id, name, name_ar, category, description, image_url, is_active, is_featured, rating, total_reviews) VALUES
        (demo_store_id, NULL, demo_seller_id, 'Tech Hub Lebanon', 'تك هاب لبنان', 'marketplace', 'Your one-stop shop for electronics and gadgets', 'https://images.unsplash.com/photo-1498049794561-7780e7231661', true, true, 4.8, 127),
        (electronics_store_id, NULL, demo_seller_id, 'Gadget Galaxy', 'جالاكسي الأجهزة', 'marketplace', 'Latest tech at best prices', 'https://images.unsplash.com/photo-1519389950473-47ba0277781c', true, false, 4.5, 89)
    ON CONFLICT (id) DO NOTHING;
    
    -- ========== INSERT STORE COLLABORATORS ==========
    
    IF demo_provider_id != demo_seller_id THEN
        INSERT INTO public.store_collaborators (store_id, user_id, role, invited_by, accepted_at, is_active) VALUES
            (demo_store_id, demo_provider_id, 'editor', demo_seller_id, now(), true)
        ON CONFLICT (store_id, user_id) DO NOTHING;
    END IF;
    
    -- ========== INSERT MARKETPLACE LISTINGS ==========
    
    INSERT INTO public.marketplace_listings (
        user_id, store_id, category_id, listing_type, title, title_ar, description, price, currency,
        category, condition, images, location_text, is_negotiable, is_sold, is_active, status, views, inquiries
    ) VALUES
        -- Electronics
        (demo_seller_id, demo_store_id, cat_electronics_id, 'product', 'iPhone 14 Pro Max 256GB', 'آيفون 14 برو ماكس', 'Excellent condition, barely used. Includes original box and accessories.', 899.00, 'USD', 'electronics', 'like_new', 
         '["https://images.unsplash.com/photo-1678652197831-2d180705cd2c", "https://images.unsplash.com/photo-1592286927505-c80e3b0c9c1e"]'::jsonb, 'Beirut, Lebanon', true, false, true, 'active', 45, 12),
        
        (demo_seller_id, electronics_store_id, cat_electronics_id, 'product', 'MacBook Air M2 2023', 'ماك بوك اير', 'Brand new sealed. Perfect for students and professionals.', 1199.00, 'USD', 'electronics', 'new', 
         '["https://images.unsplash.com/photo-1517336714731-489689fd1ca8", "https://images.unsplash.com/photo-1611186871348-b1ce696e52c9"]'::jsonb, 'Jounieh, Lebanon', false, false, true, 'active', 78, 23),
        
        (demo_seller_id, NULL, cat_electronics_id, 'product', 'Sony WH-1000XM5 Headphones', 'سماعات سوني', 'Noise cancelling headphones. Used for 3 months.', 299.00, 'USD', 'electronics', 'good', 
         '["https://images.unsplash.com/photo-1546435770-a3e426bf472b", "https://images.unsplash.com/photo-1484704849700-f032a568e944"]'::jsonb, 'Tripoli, Lebanon', true, false, true, 'active', 34, 8),
        
        -- Furniture
        (demo_seller_id, NULL, cat_furniture_id, 'product', 'Modern L-Shaped Sofa', 'كنبة حديثة', 'Gray fabric sofa in excellent condition. Moving sale!', 450.00, 'USD', 'furniture', 'good', 
         '["https://images.unsplash.com/photo-1555041469-a586c61ea9bc", "https://images.unsplash.com/photo-1586023492125-27b2c045efd7"]'::jsonb, 'Beirut, Achrafieh', true, false, true, 'active', 56, 15),
        
        (demo_seller_id, NULL, cat_furniture_id, 'product', 'Wooden Dining Table Set', 'طاولة طعام خشبية', '6-seater dining table with chairs. Solid wood construction.', 650.00, 'USD', 'furniture', 'like_new', 
         '["https://images.unsplash.com/photo-1617806118233-18e1de247200", "https://images.unsplash.com/photo-1595428774223-ef52624120d2"]'::jsonb, 'Saida, Lebanon', true, false, true, 'active', 67, 19),
        
        -- Clothing
        (demo_seller_id, NULL, cat_clothing_id, 'product', 'Designer Leather Jacket', 'جاكيت جلد', 'Genuine leather jacket, size M. Worn twice.', 180.00, 'USD', 'clothing', 'like_new', 
         '["https://images.unsplash.com/photo-1551028719-00167b16eac5", "https://images.unsplash.com/photo-1520975954732-35dd22299614"]'::jsonb, 'Beirut, Hamra', true, false, true, 'active', 89, 21),
        
        -- Vehicles
        (demo_seller_id, NULL, cat_vehicles_id, 'product', '2019 Honda Civic LX', 'هوندا سيفيك', 'Well maintained, single owner. Full service history.', 15500.00, 'USD', 'vehicles', 'good', 
         '["https://images.unsplash.com/photo-1590362891991-f776e747a588", "https://images.unsplash.com/photo-1552519507-da3b142c6e3d"]'::jsonb, 'Beirut, Lebanon', true, false, true, 'active', 123, 34),
        
        -- Sports
        (demo_seller_id, NULL, cat_sports_id, 'product', 'Mountain Bike - Trek X-Caliber', 'دراجة جبلية', '29-inch wheels, 21-speed. Perfect for trails.', 420.00, 'USD', 'sports', 'good', 
         '["https://images.unsplash.com/photo-1576435728678-68d0fbf94e91", "https://images.unsplash.com/photo-1571333250630-f0230c320b6d"]'::jsonb, 'Byblos, Lebanon', true, false, true, 'active', 45, 11),
        
        -- Books
        (demo_seller_id, NULL, cat_books_id, 'product', 'Programming Books Collection', 'مجموعة كتب برمجة', '15 books on web development, Python, and JavaScript.', 85.00, 'USD', 'books', 'good', 
         '["https://images.unsplash.com/photo-1512820790803-83ca734da794", "https://images.unsplash.com/photo-1497633762265-9d179a990aa6"]'::jsonb, 'Beirut, Lebanon', true, false, true, 'active', 67, 18),
        
        -- Service Requests
        (demo_seller_id, NULL, cat_handyman_id, 'request', 'Need Plumber for Kitchen Repair', 'مطلوب سباك', 'Kitchen sink leaking. Need urgent repair.', 50.00, 'USD', 'other', NULL, 
         '["https://images.unsplash.com/photo-1607472586893-edb57bdc0e39"]'::jsonb, 'Beirut, Verdun', false, false, true, 'active', 23, 5),
        
        (demo_seller_id, NULL, cat_cleaning_id, 'request', 'Weekly House Cleaning Service', 'خدمة تنظيف أسبوعية', 'Looking for reliable cleaning service for 3-bedroom apartment.', 80.00, 'USD', 'other', NULL, 
         '["https://images.unsplash.com/photo-1581578731548-c64695cc6952"]'::jsonb, 'Jounieh, Lebanon', true, false, true, 'active', 34, 9)
    ON CONFLICT (id) DO NOTHING;
    
    -- ========== INSERT SERVICES ==========
    
    INSERT INTO public.services (
        type, provider_id, name, name_ar, description, description_ar, base_price, currency,
        price_per_km, price_per_hour, rating, total_bookings, is_active, is_verified, images
    ) VALUES
        -- Taxi
        ('taxi', demo_provider_id, 'Quick Taxi Beirut', 'تاكسي سريع بيروت', 'Fast and reliable taxi service across Beirut', 'خدمة تاكسي سريعة وموثوقة في بيروت', 5.00, 'USD', 1.50, NULL, 4.7, 234, true, true,
         '["https://images.unsplash.com/photo-1449965408869-eaa3f722e40d", "https://images.unsplash.com/photo-1519003722824-194d4455a60c"]'::jsonb),
        
        ('taxi', demo_provider_id, 'Airport Transfer Service', 'خدمة نقل المطار', 'Comfortable rides to and from Beirut Airport', 'رحلات مريحة من وإلى مطار بيروت', 25.00, 'USD', 2.00, NULL, 4.9, 567, true, true,
         '["https://images.unsplash.com/photo-1544620347-c4fd4a3d5957"]'::jsonb),
        
        -- Towing
        ('towing', demo_provider_id, '24/7 Towing Lebanon', 'سحب مركبات لبنان', 'Emergency towing service available 24/7', 'خدمة سحب طوارئ متاحة على مدار الساعة', 50.00, 'USD', 3.00, NULL, 4.6, 189, true, true,
         '["https://images.unsplash.com/photo-1621939514649-280e2ee25f60"]'::jsonb),
        
        -- Water Delivery
        ('water_delivery', demo_provider_id, 'Fresh Water Delivery', 'توصيل مياه نقية', 'Clean drinking water delivered to your door', 'مياه شرب نظيفة توصل إلى باب منزلك', 3.00, 'USD', NULL, NULL, 4.8, 456, true, true,
         '["https://images.unsplash.com/photo-1548839140-29a749e1cf4d"]'::jsonb),
        
        -- Diesel Delivery
        ('diesel_delivery', demo_provider_id, 'Diesel Express', 'ديزل إكسبريس', 'Fast diesel delivery for generators', 'توصيل سريع للديزل للمولدات', 1.20, 'USD', NULL, NULL, 4.5, 678, true, true,
         '["https://images.unsplash.com/photo-1545262810-77515befe149"]'::jsonb),
        
        -- Private Chef
        ('private_chef', demo_provider_id, 'Chef Antoine Catering', 'الشيف أنطوان', 'Professional chef for your events and daily meals', 'طاهي محترف لمناسباتك ووجباتك اليومية', 150.00, 'USD', NULL, 50.00, 5.0, 123, true, true,
         '["https://images.unsplash.com/photo-1577219491135-ce391730fb2c", "https://images.unsplash.com/photo-1556910103-1c02745aae4d"]'::jsonb),
        
        -- Personal Trainer
        ('personal_trainer', demo_provider_id, 'Fitness Pro Lebanon', 'فتنس برو لبنان', 'Certified personal trainer for all fitness levels', 'مدرب شخصي معتمد لجميع مستويات اللياقة', 40.00, 'USD', NULL, 40.00, 4.9, 234, true, true,
         '["https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b", "https://images.unsplash.com/photo-1534438327276-14e5300c3a48"]'::jsonb),
        
        -- Private Driver
        ('private_driver', demo_provider_id, 'Professional Driver Service', 'خدمة سائق محترف', 'Experienced driver for daily commute or special occasions', 'سائق ذو خبرة للتنقل اليومي أو المناسبات الخاصة', 30.00, 'USD', NULL, 15.00, 4.7, 345, true, true,
         '["https://images.unsplash.com/photo-1449965408869-eaa3f722e40d"]'::jsonb),
        
        -- Cleaning
        ('cleaning', demo_provider_id, 'Sparkle Clean Services', 'خدمات التنظيف المتألق', 'Professional home and office cleaning', 'تنظيف احترافي للمنازل والمكاتب', 50.00, 'USD', NULL, 25.00, 4.8, 567, true, true,
         '["https://images.unsplash.com/photo-1581578731548-c64695cc6952", "https://images.unsplash.com/photo-1628177142898-93e36e4e3a50"]'::jsonb),
        
        -- Handyman
        ('handyman', demo_provider_id, 'Fix-It Pro Lebanon', 'محترف الإصلاح لبنان', 'Expert repairs and maintenance for your home', 'إصلاحات وصيانة احترافية لمنزلك', 35.00, 'USD', NULL, 30.00, 4.6, 432, true, true,
         '["https://images.unsplash.com/photo-1607472586893-edb57bdc0e39", "https://images.unsplash.com/photo-1581578731548-c64695cc6952"]'::jsonb)
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE '✅ Marketplace seed data created successfully!';
    RAISE NOTICE '📦 Created % product listings', (SELECT COUNT(*) FROM public.marketplace_listings WHERE listing_type = 'product');
    RAISE NOTICE '🛠️ Created % service listings', (SELECT COUNT(*) FROM public.services);
    RAISE NOTICE '🏪 Created % stores', (SELECT COUNT(*) FROM public.stores WHERE owner_user_id IS NOT NULL);
    RAISE NOTICE '📂 Created % categories', (SELECT COUNT(*) FROM public.categories);
    RAISE NOTICE '';
    RAISE NOTICE '🔐 Demo Accounts:';
    RAISE NOTICE '   Seller: seller@marketplace.com / seller123';
    RAISE NOTICE '   Provider: provider@marketplace.com / provider123';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error creating seed data: %', SQLERRM;
END $$;