-- =============================================
-- ADMIN ADS SYSTEM MIGRATION
-- =============================================
-- Creates tables for admin-driven ads placement with multiple formats,
-- targeting rules, scheduling, deep-linking, and analytics

-- =============================================
-- ENUMS
-- =============================================

DO $$ BEGIN
  CREATE TYPE ad_format AS ENUM ('carousel', 'rotating_banner', 'fixed_banner');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ad_status AS ENUM ('draft', 'scheduled', 'active', 'paused', 'expired');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ad_target_type AS ENUM ('global_home', 'store', 'category', 'product', 'collection');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ad_link_type AS ENUM ('store', 'product', 'category', 'collection', 'external_url');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =============================================
-- ADS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  format ad_format NOT NULL DEFAULT 'fixed_banner',
  status ad_status NOT NULL DEFAULT 'draft',
  
  -- Media
  image_url TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  
  -- Deep-linking
  link_type ad_link_type NOT NULL,
  link_target_id TEXT,
  external_url TEXT,
  
  -- Scheduling
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_recurring BOOLEAN DEFAULT false,
  recurring_days INTEGER[] DEFAULT '{}',
  
  -- Display settings
  display_order INTEGER DEFAULT 0,
  auto_play_interval INTEGER DEFAULT 4000,
  
  -- Analytics
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- AD TARGETING RULES TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.ad_targeting_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id UUID NOT NULL REFERENCES public.ads(id) ON DELETE CASCADE,
  target_type ad_target_type NOT NULL,
  target_id TEXT,
  
  -- Additional targeting
  user_roles TEXT[] DEFAULT '{}',
  min_order_count INTEGER,
  location_radius_km DECIMAL(10, 2),
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- AD ANALYTICS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.ad_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id UUID NOT NULL REFERENCES public.ads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  context_page TEXT,
  device_type TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- INDEXES
-- =============================================

CREATE INDEX IF NOT EXISTS idx_ads_status ON public.ads(status);
CREATE INDEX IF NOT EXISTS idx_ads_format ON public.ads(format);
CREATE INDEX IF NOT EXISTS idx_ads_dates ON public.ads(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_ads_display_order ON public.ads(display_order);
CREATE INDEX IF NOT EXISTS idx_ad_targeting_ad_id ON public.ad_targeting_rules(ad_id);
CREATE INDEX IF NOT EXISTS idx_ad_targeting_type ON public.ad_targeting_rules(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_ad_analytics_ad_id ON public.ad_analytics(ad_id);
CREATE INDEX IF NOT EXISTS idx_ad_analytics_event ON public.ad_analytics(event_type, created_at);

-- =============================================
-- RLS POLICIES
-- =============================================

-- Enable RLS
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_targeting_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_analytics ENABLE ROW LEVEL SECURITY;

-- Ads policies
DROP POLICY IF EXISTS "Public can view active ads" ON public.ads;
CREATE POLICY "Public can view active ads" ON public.ads
  FOR SELECT
  USING (status = 'active' AND (start_date IS NULL OR start_date <= now()) AND (end_date IS NULL OR end_date >= now()));

DROP POLICY IF EXISTS "Admins can manage all ads" ON public.ads;
CREATE POLICY "Admins can manage all ads" ON public.ads
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

-- Ad targeting rules policies
DROP POLICY IF EXISTS "Public can view targeting rules for active ads" ON public.ad_targeting_rules;
CREATE POLICY "Public can view targeting rules for active ads" ON public.ad_targeting_rules
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.ads
      WHERE ads.id = ad_targeting_rules.ad_id
      AND ads.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Admins can manage targeting rules" ON public.ad_targeting_rules;
CREATE POLICY "Admins can manage targeting rules" ON public.ad_targeting_rules
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

-- Ad analytics policies
DROP POLICY IF EXISTS "Anyone can insert analytics" ON public.ad_analytics;
CREATE POLICY "Anyone can insert analytics" ON public.ad_analytics
  FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can view all analytics" ON public.ad_analytics;
CREATE POLICY "Admins can view all analytics" ON public.ad_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to get active ads for a specific context
CREATE OR REPLACE FUNCTION public.get_active_ads_for_context(
  p_target_type ad_target_type DEFAULT 'global_home',
  p_target_id TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  format ad_format,
  image_url TEXT,
  images TEXT[],
  link_type ad_link_type,
  link_target_id TEXT,
  external_url TEXT,
  display_order INTEGER,
  auto_play_interval INTEGER,
  impressions INTEGER,
  clicks INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    a.id,
    a.title,
    a.description,
    a.format,
    a.image_url,
    a.images,
    a.link_type,
    a.link_target_id,
    a.external_url,
    a.display_order,
    a.auto_play_interval,
    a.impressions,
    a.clicks
  FROM public.ads a
  LEFT JOIN public.ad_targeting_rules atr ON a.id = atr.ad_id
  WHERE a.status = 'active'
    AND (a.start_date IS NULL OR a.start_date <= now())
    AND (a.end_date IS NULL OR a.end_date >= now())
    AND (
      atr.target_type = p_target_type
      AND (p_target_id IS NULL OR atr.target_id = p_target_id)
      OR atr.target_type = 'global_home'
    )
  ORDER BY a.display_order ASC, a.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to track ad impression
CREATE OR REPLACE FUNCTION public.track_ad_impression(
  p_ad_id UUID,
  p_context_page TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Update impression count
  UPDATE public.ads
  SET impressions = impressions + 1
  WHERE id = p_ad_id;
  
  -- Insert analytics record
  INSERT INTO public.ad_analytics (ad_id, user_id, event_type, context_page)
  VALUES (p_ad_id, auth.uid(), 'impression', p_context_page);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to track ad click
CREATE OR REPLACE FUNCTION public.track_ad_click(
  p_ad_id UUID,
  p_context_page TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Update click count
  UPDATE public.ads
  SET clicks = clicks + 1
  WHERE id = p_ad_id;
  
  -- Insert analytics record
  INSERT INTO public.ad_analytics (ad_id, user_id, event_type, context_page)
  VALUES (p_ad_id, auth.uid(), 'click', p_context_page);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get ad analytics summary
CREATE OR REPLACE FUNCTION public.get_ad_analytics_summary(
  p_ad_id UUID DEFAULT NULL,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  ad_id UUID,
  ad_title TEXT,
  total_impressions BIGINT,
  total_clicks BIGINT,
  ctr DECIMAL,
  unique_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.title,
    COUNT(CASE WHEN aa.event_type = 'impression' THEN 1 END) as total_impressions,
    COUNT(CASE WHEN aa.event_type = 'click' THEN 1 END) as total_clicks,
    CASE
      WHEN COUNT(CASE WHEN aa.event_type = 'impression' THEN 1 END) > 0
      THEN (COUNT(CASE WHEN aa.event_type = 'click' THEN 1 END)::DECIMAL / COUNT(CASE WHEN aa.event_type = 'impression' THEN 1 END)::DECIMAL) * 100
      ELSE 0
    END as ctr,
    COUNT(DISTINCT aa.user_id) as unique_users
  FROM public.ads a
  LEFT JOIN public.ad_analytics aa ON a.id = aa.ad_id
    AND aa.created_at >= now() - (p_days || ' days')::INTERVAL
  WHERE (p_ad_id IS NULL OR a.id = p_ad_id)
  GROUP BY a.id, a.title
  ORDER BY total_impressions DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- TRIGGERS
-- =============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_ads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_ads_updated_at_trigger ON public.ads;
CREATE TRIGGER update_ads_updated_at_trigger
  BEFORE UPDATE ON public.ads
  FOR EACH ROW
  EXECUTE FUNCTION public.update_ads_updated_at();

-- =============================================
-- STORAGE BUCKET
-- =============================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('ads-images', 'ads-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for ads-images bucket
DROP POLICY IF EXISTS "Public can view ad images" ON storage.objects;
CREATE POLICY "Public can view ad images" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'ads-images');

DROP POLICY IF EXISTS "Admins can upload ad images" ON storage.objects;
CREATE POLICY "Admins can upload ad images" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'ads-images'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

DROP POLICY IF EXISTS "Admins can update ad images" ON storage.objects;
CREATE POLICY "Admins can update ad images" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'ads-images'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

DROP POLICY IF EXISTS "Admins can delete ad images" ON storage.objects;
CREATE POLICY "Admins can delete ad images" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'ads-images'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.is_active = true
    )
  );

-- =============================================
-- DEMO DATA
-- =============================================

-- Insert demo ads (only if no ads exist)
DO $$
DECLARE
  v_admin_id UUID;
  v_ad_id_1 UUID;
  v_ad_id_2 UUID;
  v_ad_id_3 UUID;
BEGIN
  -- Get first admin user
  SELECT id INTO v_admin_id
  FROM public.users
  WHERE role = 'admin'
  LIMIT 1;

  -- Only insert if no ads exist
  IF NOT EXISTS (SELECT 1 FROM public.ads LIMIT 1) THEN
    -- Carousel ad for home
    INSERT INTO public.ads (id, title, description, format, status, image_url, link_type, link_target_id, display_order, created_by)
    VALUES (
      gen_random_uuid(),
      'Summer Sale - Up to 50% OFF',
      'Fresh fruits and vegetables at unbeatable prices',
      'carousel',
      'active',
      'https://images.unsplash.com/photo-1488459716781-31db52582fe9',
      'category',
      'fruits-vegetables',
      1,
      v_admin_id
    )
    RETURNING id INTO v_ad_id_1;

    -- Add targeting for home
    INSERT INTO public.ad_targeting_rules (ad_id, target_type)
    VALUES (v_ad_id_1, 'global_home');

    -- Rotating banner for dairy
    INSERT INTO public.ads (id, title, description, format, status, image_url, link_type, link_target_id, display_order, created_by)
    VALUES (
      gen_random_uuid(),
      'Premium Dairy Products',
      'Buy 2 Get 1 FREE on all dairy items',
      'rotating_banner',
      'active',
      'https://images.unsplash.com/photo-1628088062854-d1870b4553da',
      'category',
      'dairy',
      2,
      v_admin_id
    )
    RETURNING id INTO v_ad_id_2;

    -- Add targeting for home and dairy category
    INSERT INTO public.ad_targeting_rules (ad_id, target_type, target_id)
    VALUES 
      (v_ad_id_2, 'global_home', NULL),
      (v_ad_id_2, 'category', 'dairy');

    -- Fixed banner for new store
    INSERT INTO public.ads (id, title, description, format, status, image_url, link_type, external_url, display_order, created_by)
    VALUES (
      gen_random_uuid(),
      'New Store Opening!',
      'Visit our newest location and get 20% off your first order',
      'fixed_banner',
      'active',
      'https://images.unsplash.com/photo-1604719312566-8912e9227c6a',
      'external_url',
      'https://example.com/new-store',
      3,
      v_admin_id
    )
    RETURNING id INTO v_ad_id_3;

    -- Add targeting for home
    INSERT INTO public.ad_targeting_rules (ad_id, target_type)
    VALUES (v_ad_id_3, 'global_home');

    RAISE NOTICE 'Demo ads created successfully';
  END IF;
END $$;
