-- Migration: Create reset_demo_data RPC function
-- Timestamp: 20260131210000
-- Purpose: Idempotent demo data cleanup that preserves admin user

-- ============================================================
-- SECTION 1: Add is_demo column to all relevant tables
-- ============================================================

-- Add is_demo flag to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to stores table
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to categories table
ALTER TABLE public.categories 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to marketplace_listings table
ALTER TABLE public.marketplace_listings 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to orders table
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to order_items table
ALTER TABLE public.order_items 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to conversations table
ALTER TABLE public.conversations 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to ads table
ALTER TABLE public.ads 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to merchants table
ALTER TABLE public.merchants 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- Add is_demo flag to drivers table
ALTER TABLE public.drivers 
ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;

-- ============================================================
-- SECTION 2: Create reset_demo_data RPC function
-- ============================================================

CREATE OR REPLACE FUNCTION public.reset_demo_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_messages INT;
    deleted_conversations INT;
    deleted_order_items INT;
    deleted_orders INT;
    deleted_ads INT;
    deleted_listings INT;
    deleted_products INT;
    deleted_stores INT;
    deleted_categories INT;
    deleted_drivers INT;
    deleted_merchants INT;
    deleted_users INT;
    admin_email TEXT := 'admin@sevenknots.com';
BEGIN
    -- Check if user is admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only admins can reset demo data';
    END IF;

    -- Delete in reverse dependency order (children first, parents last)
    
    -- 1. Delete demo messages
    DELETE FROM public.messages WHERE is_demo = true;
    GET DIAGNOSTICS deleted_messages = ROW_COUNT;
    
    -- 2. Delete demo conversations
    DELETE FROM public.conversations WHERE is_demo = true;
    GET DIAGNOSTICS deleted_conversations = ROW_COUNT;
    
    -- 3. Delete demo order items
    DELETE FROM public.order_items WHERE is_demo = true;
    GET DIAGNOSTICS deleted_order_items = ROW_COUNT;
    
    -- 4. Delete demo orders
    DELETE FROM public.orders WHERE is_demo = true;
    GET DIAGNOSTICS deleted_orders = ROW_COUNT;
    
    -- 5. Delete demo ads
    DELETE FROM public.ads WHERE is_demo = true;
    GET DIAGNOSTICS deleted_ads = ROW_COUNT;
    
    -- 6. Delete demo marketplace listings
    DELETE FROM public.marketplace_listings WHERE is_demo = true;
    GET DIAGNOSTICS deleted_listings = ROW_COUNT;
    
    -- 7. Delete demo products
    DELETE FROM public.products WHERE is_demo = true;
    GET DIAGNOSTICS deleted_products = ROW_COUNT;
    
    -- 8. Delete demo stores
    DELETE FROM public.stores WHERE is_demo = true;
    GET DIAGNOSTICS deleted_stores = ROW_COUNT;
    
    -- 9. Delete demo categories
    DELETE FROM public.categories WHERE is_demo = true;
    GET DIAGNOSTICS deleted_categories = ROW_COUNT;
    
    -- 10. Delete demo drivers
    DELETE FROM public.drivers WHERE is_demo = true;
    GET DIAGNOSTICS deleted_drivers = ROW_COUNT;
    
    -- 11. Delete demo merchants
    DELETE FROM public.merchants WHERE is_demo = true;
    GET DIAGNOSTICS deleted_merchants = ROW_COUNT;
    
    -- 12. Delete demo users (EXCEPT admin@sevenknots.com)
    DELETE FROM public.users 
    WHERE is_demo = true 
    AND email != admin_email;
    GET DIAGNOSTICS deleted_users = ROW_COUNT;
    
    -- 13. Remove seed version marker to allow re-seeding
    DELETE FROM public.app_settings WHERE key = 'demo_seed_version';
    
    -- Return deletion counts as JSON
    RETURN jsonb_build_object(
        'messages', deleted_messages,
        'conversations', deleted_conversations,
        'order_items', deleted_order_items,
        'orders', deleted_orders,
        'ads', deleted_ads,
        'marketplace_listings', deleted_listings,
        'products', deleted_products,
        'stores', deleted_stores,
        'categories', deleted_categories,
        'drivers', deleted_drivers,
        'merchants', deleted_merchants,
        'users', deleted_users,
        'admin_preserved', admin_email
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Reset demo data failed: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users (RLS will check admin role)
GRANT EXECUTE ON FUNCTION public.reset_demo_data() TO authenticated;

COMMENT ON FUNCTION public.reset_demo_data() IS 'Admin-only RPC to delete all demo-tagged data while preserving admin@sevenknots.com';