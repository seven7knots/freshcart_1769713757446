-- Migration: Add comprehensive seed data for Admin, Merchant, Driver, and Customer roles
-- Timestamp: 20260131160000

-- ============================================================
-- SEED DATA FOR ALL ROLES
-- ============================================================

DO $$
DECLARE
    admin_user_id UUID;
    merchant_user_id UUID;
    driver_user_id UUID;
    customer_user_id UUID;
    store_id UUID;
    product1_id UUID;
    product2_id UUID;
    product3_id UUID;
    order1_id UUID;
BEGIN
    -- Check if demo users already exist
    SELECT id INTO admin_user_id FROM public.users WHERE email = 'admin@kjdelivery.com' LIMIT 1;
    
    IF admin_user_id IS NULL THEN
        -- Create Admin User
        INSERT INTO public.users (
            id, email, phone, full_name, role, wallet_balance, is_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'admin@kjdelivery.com', '+96170123456', 'Admin User', 
            'admin', 1000.00, true, true
        ) RETURNING id INTO admin_user_id;
        RAISE NOTICE 'Created admin user: %', admin_user_id;
    END IF;

    -- Create Merchant User
    SELECT id INTO merchant_user_id FROM public.users WHERE email = 'merchant@kjdelivery.com' LIMIT 1;
    IF merchant_user_id IS NULL THEN
        INSERT INTO public.users (
            id, email, phone, full_name, role, wallet_balance, is_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'merchant@kjdelivery.com', '+96170234567', 'Store Owner', 
            'merchant', 500.00, true, true
        ) RETURNING id INTO merchant_user_id;
        RAISE NOTICE 'Created merchant user: %', merchant_user_id;
    END IF;

    -- Create Driver User
    SELECT id INTO driver_user_id FROM public.users WHERE email = 'driver@kjdelivery.com' LIMIT 1;
    IF driver_user_id IS NULL THEN
        INSERT INTO public.users (
            id, email, phone, full_name, role, wallet_balance, is_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'driver@kjdelivery.com', '+96170345678', 'Delivery Driver', 
            'driver', 250.00, true, true
        ) RETURNING id INTO driver_user_id;
        RAISE NOTICE 'Created driver user: %', driver_user_id;
    END IF;

    -- Create Customer User
    SELECT id INTO customer_user_id FROM public.users WHERE email = 'customer@kjdelivery.com' LIMIT 1;
    IF customer_user_id IS NULL THEN
        INSERT INTO public.users (
            id, email, phone, full_name, role, wallet_balance, is_verified, is_active,
            default_address, location_lat, location_lng
        ) VALUES (
            gen_random_uuid(), 'customer@kjdelivery.com', '+96170456789', 'John Customer', 
            'customer', 100.00, true, true,
            'Beirut, Lebanon', 33.8886, 35.4955
        ) RETURNING id INTO customer_user_id;
        RAISE NOTICE 'Created customer user: %', customer_user_id;
    END IF;

    -- Create Merchant Profile
    INSERT INTO public.merchants (
        id, user_id, business_name, business_name_ar, business_type, 
        description, address, location_lat, location_lng, is_verified, is_active
    ) VALUES (
        gen_random_uuid(), merchant_user_id, 'Fresh Market', 'السوق الطازج', 'grocery',
        'Your neighborhood grocery store with fresh produce', 
        'Hamra Street, Beirut', 33.8959, 35.4769, true, true
    ) ON CONFLICT (user_id) DO NOTHING;

    -- Create Store (check if exists first)
    SELECT id INTO store_id FROM public.stores WHERE owner_user_id = merchant_user_id LIMIT 1;
    IF store_id IS NULL THEN
        INSERT INTO public.stores (
            id, name, name_ar, category, description, address, 
            location_lat, location_lng, is_active, is_featured, owner_user_id
        ) VALUES (
            gen_random_uuid(), 'Fresh Market Store', 'متجر السوق الطازج', 'grocery',
            'Fresh fruits, vegetables, and daily essentials',
            'Hamra Street, Beirut', 33.8959, 35.4769, true, true, merchant_user_id
        ) RETURNING id INTO store_id;
        RAISE NOTICE 'Created store: %', store_id;
    END IF;

    -- Create Products
    IF store_id IS NOT NULL THEN
        INSERT INTO public.products (
            id, store_id, name, name_ar, description, price, category, 
            image_url, is_available, is_featured, stock_quantity
        ) VALUES 
            (gen_random_uuid(), store_id, 'Fresh Apples', 'تفاح طازج', 
             'Crisp and sweet red apples', 2.99, 'Fruits', 
             'https://images.pexels.com/photos/102104/pexels-photo-102104.jpeg', 
             true, true, 100),
            (gen_random_uuid(), store_id, 'Organic Bananas', 'موز عضوي',
             'Fresh organic bananas from local farms', 1.99, 'Fruits',
             'https://images.pexels.com/photos/2872755/pexels-photo-2872755.jpeg',
             true, true, 150),
            (gen_random_uuid(), store_id, 'Fresh Milk', 'حليب طازج',
             'Farm fresh whole milk', 3.49, 'Dairy',
             'https://images.pexels.com/photos/236010/pexels-photo-236010.jpeg',
             true, false, 50)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Create Driver Profile
    INSERT INTO public.drivers (
        id, user_id, vehicle_type, vehicle_plate, vehicle_model, vehicle_color,
        is_online, is_verified, is_active, current_location_lat, current_location_lng
    ) VALUES (
        gen_random_uuid(), driver_user_id, 'motorcycle', 'ABC123', 'Honda CB', 'Red',
        true, true, true, 33.8886, 35.4955
    ) ON CONFLICT (user_id) DO NOTHING;

    -- Create Sample Order (check if exists first)
    IF store_id IS NOT NULL AND customer_user_id IS NOT NULL THEN
        SELECT id INTO order1_id FROM public.orders WHERE customer_id = customer_user_id AND store_id = store_id LIMIT 1;
        IF order1_id IS NULL THEN
            INSERT INTO public.orders (
                id, customer_id, store_id, driver_id, status, subtotal, delivery_fee,
                total, delivery_address, delivery_lat, delivery_lng, customer_phone
            ) VALUES (
                gen_random_uuid(), customer_user_id, store_id, driver_user_id, 'assigned',
                15.47, 2.00, 17.47, 'Beirut, Lebanon', 33.8886, 35.4955, '+96170456789'
            ) RETURNING id INTO order1_id;
            RAISE NOTICE 'Created order: %', order1_id;
        END IF;

        -- Add order items
        IF order1_id IS NOT NULL THEN
            SELECT id INTO product1_id FROM public.products WHERE store_id = store_id LIMIT 1;
            IF product1_id IS NOT NULL THEN
                INSERT INTO public.order_items (
                    id, order_id, product_id, product_name, quantity, unit_price, total_price
                ) VALUES (
                    gen_random_uuid(), order1_id, product1_id, 'Fresh Apples', 3, 2.99, 8.97
                ) ON CONFLICT (id) DO NOTHING;
            END IF;
        END IF;
    END IF;

    RAISE NOTICE 'Seed data creation completed successfully';
    RAISE NOTICE 'Demo Credentials:';
    RAISE NOTICE '  Admin: admin@kjdelivery.com';
    RAISE NOTICE '  Merchant: merchant@kjdelivery.com';
    RAISE NOTICE '  Driver: driver@kjdelivery.com';
    RAISE NOTICE '  Customer: customer@kjdelivery.com';
    RAISE NOTICE '  Password for all: (set via Supabase Auth)';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating seed data: %', SQLERRM;
END $$;
