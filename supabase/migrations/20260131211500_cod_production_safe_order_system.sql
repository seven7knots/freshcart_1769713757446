-- =====================================================
-- COD PRODUCTION-SAFE ORDER SYSTEM MIGRATION
-- Purpose: Server-authoritative order state machine with immutable audit trail
-- Timestamp: 20260131211500
-- =====================================================

-- ========== STEP 1: ADD COD TRACKING FIELDS TO ORDERS ==========
-- Add COD-specific fields to existing orders table
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS cash_collected_amount NUMERIC,
ADD COLUMN IF NOT EXISTS cash_collected_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cash_confirmed_by_admin UUID REFERENCES public.users(id);

-- ========== STEP 2: CREATE ORDER_EVENTS AUDIT TABLE ==========
-- Immutable audit trail for all order status changes
CREATE TABLE IF NOT EXISTS public.order_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('status_change', 'assignment', 'payment', 'cancellation', 'admin_override')),
    from_status TEXT,
    to_status TEXT,
    actor_user_id UUID REFERENCES public.users(id),
    actor_role TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_events_order_id ON public.order_events(order_id);
CREATE INDEX IF NOT EXISTS idx_order_events_created_at ON public.order_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_events_actor_user_id ON public.order_events(actor_user_id);

-- ========== STEP 3: ENABLE RLS ON ORDER_EVENTS ==========
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;

-- ========== STEP 4: RLS POLICIES FOR ORDER_EVENTS ==========
-- Customers can view events for their orders
DROP POLICY IF EXISTS "customers_view_own_order_events" ON public.order_events;
CREATE POLICY "customers_view_own_order_events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_id AND o.customer_id = auth.uid()
    )
);

-- Merchants can view events for their store orders
DROP POLICY IF EXISTS "merchants_view_store_order_events" ON public.order_events;
CREATE POLICY "merchants_view_store_order_events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        JOIN public.stores s ON o.store_id = s.id
        WHERE o.id = order_id AND s.owner_user_id = auth.uid()
    )
);

-- Drivers can view events for their assigned orders
DROP POLICY IF EXISTS "drivers_view_assigned_order_events" ON public.order_events;
CREATE POLICY "drivers_view_assigned_order_events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_id AND o.driver_id = auth.uid()
    )
);

-- Admin can view all order events
DROP POLICY IF EXISTS "admin_view_all_order_events" ON public.order_events;
CREATE POLICY "admin_view_all_order_events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() AND u.role = 'admin'
    )
);

-- Only RPC functions can insert order events (no direct client inserts)
DROP POLICY IF EXISTS "rpc_only_insert_order_events" ON public.order_events;
CREATE POLICY "rpc_only_insert_order_events"
ON public.order_events
FOR INSERT
TO authenticated
WITH CHECK (false);  -- Blocks all direct inserts; only RPC functions can insert

-- ========== STEP 5: SERVER-AUTHORITATIVE RPC FUNCTIONS ==========

-- Function: Create order with server-calculated totals
CREATE OR REPLACE FUNCTION public.create_order_with_validation(
    p_store_id UUID,
    p_delivery_address TEXT,
    p_delivery_lat NUMERIC,
    p_delivery_lng NUMERIC,
    p_delivery_instructions TEXT DEFAULT NULL,
    p_customer_phone TEXT DEFAULT NULL,
    p_scheduled_for TIMESTAMPTZ DEFAULT NULL,
    p_items JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_customer_id UUID;
    v_order_id UUID;
    v_subtotal NUMERIC := 0;
    v_delivery_fee NUMERIC := 2.00;  -- Fixed delivery fee for COD
    v_service_fee NUMERIC := 0.50;
    v_tax NUMERIC := 0;
    v_total NUMERIC := 0;
    v_item JSONB;
    v_product_price NUMERIC;
    v_product_name TEXT;
    v_product_image TEXT;
BEGIN
    -- Get authenticated user
    v_customer_id := auth.uid();
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Validate store exists and is active
    IF NOT EXISTS (SELECT 1 FROM public.stores WHERE id = p_store_id AND is_active = true) THEN
        RAISE EXCEPTION 'Store not found or inactive';
    END IF;

    -- Calculate server-side totals from products
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        -- Get actual product price from database (never trust client)
        SELECT 
            COALESCE(sale_price, price),
            name,
            image_url
        INTO v_product_price, v_product_name, v_product_image
        FROM public.products
        WHERE id = (v_item->>'product_id')::UUID
        AND is_available = true;

        IF v_product_price IS NULL THEN
            RAISE EXCEPTION 'Product % not found or unavailable', v_item->>'product_id';
        END IF;

        -- Add to subtotal
        v_subtotal := v_subtotal + (v_product_price * (v_item->>'quantity')::INTEGER);
    END LOOP;

    -- Calculate tax (10% for demo)
    v_tax := v_subtotal * 0.10;

    -- Calculate total
    v_total := v_subtotal + v_delivery_fee + v_service_fee + v_tax;

    -- Create order with server-calculated totals
    INSERT INTO public.orders (
        id,
        customer_id,
        store_id,
        status,
        subtotal,
        delivery_fee,
        service_fee,
        tax,
        discount,
        tip,
        total,
        currency,
        payment_method,
        payment_status,
        delivery_address,
        delivery_lat,
        delivery_lng,
        delivery_instructions,
        customer_phone,
        scheduled_for
    ) VALUES (
        gen_random_uuid(),
        v_customer_id,
        p_store_id,
        'pending',
        v_subtotal,
        v_delivery_fee,
        v_service_fee,
        v_tax,
        0.00,
        0.00,
        v_total,
        'USD',
        'cash',  -- COD only
        'pending',
        p_delivery_address,
        p_delivery_lat,
        p_delivery_lng,
        p_delivery_instructions,
        p_customer_phone,
        p_scheduled_for
    ) RETURNING id INTO v_order_id;

    -- Create order items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        SELECT 
            COALESCE(sale_price, price),
            name,
            image_url
        INTO v_product_price, v_product_name, v_product_image
        FROM public.products
        WHERE id = (v_item->>'product_id')::UUID;

        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name,
            product_image,
            quantity,
            unit_price,
            total_price,
            currency
        ) VALUES (
            v_order_id,
            (v_item->>'product_id')::UUID,
            v_product_name,
            v_product_image,
            (v_item->>'quantity')::INTEGER,
            v_product_price,
            v_product_price * (v_item->>'quantity')::INTEGER,
            'USD'
        );
    END LOOP;

    -- Create audit event
    INSERT INTO public.order_events (
        order_id,
        event_type,
        from_status,
        to_status,
        actor_user_id,
        actor_role,
        metadata
    ) VALUES (
        v_order_id,
        'status_change',
        NULL,
        'pending',
        v_customer_id,
        'customer',
        jsonb_build_object(
            'action', 'order_created',
            'subtotal', v_subtotal,
            'total', v_total,
            'item_count', jsonb_array_length(p_items)
        )
    );

    -- Return order details
    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'status', 'pending',
        'subtotal', v_subtotal,
        'delivery_fee', v_delivery_fee,
        'service_fee', v_service_fee,
        'tax', v_tax,
        'total', v_total
    );
END;
$$;

-- Function: Update order status with validation
CREATE OR REPLACE FUNCTION public.update_order_status(
    p_order_id UUID,
    p_new_status TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_status TEXT;
    v_customer_id UUID;
    v_store_owner_id UUID;
    v_driver_id UUID;
    v_actor_id UUID;
    v_actor_role TEXT;
    v_can_transition BOOLEAN := false;
BEGIN
    -- Get authenticated user
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get current order details
    SELECT 
        o.status,
        o.customer_id,
        s.owner_user_id,
        o.driver_id
    INTO 
        v_current_status,
        v_customer_id,
        v_store_owner_id,
        v_driver_id
    FROM public.orders o
    JOIN public.stores s ON o.store_id = s.id
    WHERE o.id = p_order_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- Get actor role
    SELECT role INTO v_actor_role FROM public.users WHERE id = v_actor_id;

    -- Validate status transitions based on role
    CASE v_current_status
        WHEN 'pending' THEN
            -- Customer can cancel
            IF v_actor_id = v_customer_id AND p_new_status = 'cancelled' THEN
                v_can_transition := true;
            -- Merchant/Admin can accept or reject
            ELSIF (v_actor_id = v_store_owner_id OR v_actor_role = 'admin') AND p_new_status IN ('accepted', 'rejected') THEN
                v_can_transition := true;
            END IF;
        
        WHEN 'accepted' THEN
            -- Merchant/Admin can assign driver
            IF (v_actor_id = v_store_owner_id OR v_actor_role = 'admin') AND p_new_status = 'assigned' THEN
                v_can_transition := true;
            -- Customer can still cancel within time window (simplified: always allow for demo)
            ELSIF v_actor_id = v_customer_id AND p_new_status = 'cancelled' THEN
                v_can_transition := true;
            END IF;
        
        WHEN 'assigned' THEN
            -- Driver can pick up
            IF v_actor_id = v_driver_id AND p_new_status = 'picked_up' THEN
                v_can_transition := true;
            -- Admin can override
            ELSIF v_actor_role = 'admin' AND p_new_status IN ('cancelled', 'pending') THEN
                v_can_transition := true;
            END IF;
        
        WHEN 'picked_up' THEN
            -- Driver can deliver
            IF v_actor_id = v_driver_id AND p_new_status = 'delivered' THEN
                v_can_transition := true;
            -- Admin can override
            ELSIF v_actor_role = 'admin' THEN
                v_can_transition := true;
            END IF;
        
        WHEN 'delivered' THEN
            -- Only admin can change delivered orders
            IF v_actor_role = 'admin' THEN
                v_can_transition := true;
            END IF;
        
        WHEN 'cancelled' THEN
            -- Only admin can reactivate cancelled orders
            IF v_actor_role = 'admin' THEN
                v_can_transition := true;
            END IF;
        
        ELSE
            -- Unknown status
            RAISE EXCEPTION 'Invalid current status: %', v_current_status;
    END CASE;

    -- Check if transition is allowed
    IF NOT v_can_transition THEN
        RAISE EXCEPTION 'Status transition from % to % not allowed for role %', v_current_status, p_new_status, v_actor_role;
    END IF;

    -- Update order status
    UPDATE public.orders
    SET 
        status = p_new_status,
        cancelled_at = CASE WHEN p_new_status = 'cancelled' THEN now() ELSE cancelled_at END,
        cancellation_reason = CASE WHEN p_new_status = 'cancelled' THEN p_reason ELSE cancellation_reason END,
        actual_delivery_time = CASE WHEN p_new_status = 'delivered' THEN now() ELSE actual_delivery_time END
    WHERE id = p_order_id;

    -- Create audit event
    INSERT INTO public.order_events (
        order_id,
        event_type,
        from_status,
        to_status,
        actor_user_id,
        actor_role,
        metadata
    ) VALUES (
        p_order_id,
        'status_change',
        v_current_status,
        p_new_status,
        v_actor_id,
        v_actor_role,
        jsonb_build_object(
            'reason', p_reason,
            'timestamp', now()
        )
    );

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'from_status', v_current_status,
        'to_status', p_new_status
    );
END;
$$;

-- Function: Assign driver to order
CREATE OR REPLACE FUNCTION public.assign_driver_to_order(
    p_order_id UUID,
    p_driver_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_status TEXT;
    v_store_owner_id UUID;
    v_actor_id UUID;
    v_actor_role TEXT;
BEGIN
    -- Get authenticated user
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get actor role
    SELECT role INTO v_actor_role FROM public.users WHERE id = v_actor_id;

    -- Get order details
    SELECT 
        o.status,
        s.owner_user_id
    INTO 
        v_current_status,
        v_store_owner_id
    FROM public.orders o
    JOIN public.stores s ON o.store_id = s.id
    WHERE o.id = p_order_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- Only merchant or admin can assign drivers
    IF v_actor_id != v_store_owner_id AND v_actor_role != 'admin' THEN
        RAISE EXCEPTION 'Only store owner or admin can assign drivers';
    END IF;

    -- Order must be in accepted status
    IF v_current_status != 'accepted' THEN
        RAISE EXCEPTION 'Order must be in accepted status to assign driver';
    END IF;

    -- Verify driver exists and is active
    IF NOT EXISTS (SELECT 1 FROM public.drivers WHERE user_id = p_driver_id AND is_active = true) THEN
        RAISE EXCEPTION 'Driver not found or inactive';
    END IF;

    -- Assign driver and update status
    UPDATE public.orders
    SET 
        driver_id = p_driver_id,
        status = 'assigned'
    WHERE id = p_order_id;

    -- Create audit event
    INSERT INTO public.order_events (
        order_id,
        event_type,
        from_status,
        to_status,
        actor_user_id,
        actor_role,
        metadata
    ) VALUES (
        p_order_id,
        'assignment',
        v_current_status,
        'assigned',
        v_actor_id,
        v_actor_role,
        jsonb_build_object(
            'driver_id', p_driver_id,
            'assigned_at', now()
        )
    );

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'driver_id', p_driver_id,
        'status', 'assigned'
    );
END;
$$;

-- Function: Confirm cash collection (driver marks cash collected)
CREATE OR REPLACE FUNCTION public.confirm_cash_collection(
    p_order_id UUID,
    p_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_driver_id UUID;
    v_actor_id UUID;
    v_order_total NUMERIC;
BEGIN
    -- Get authenticated user
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get order details
    SELECT driver_id, total
    INTO v_driver_id, v_order_total
    FROM public.orders
    WHERE id = p_order_id;

    IF v_driver_id IS NULL THEN
        RAISE EXCEPTION 'Order not found or no driver assigned';
    END IF;

    -- Only assigned driver can confirm cash collection
    IF v_actor_id != v_driver_id THEN
        RAISE EXCEPTION 'Only assigned driver can confirm cash collection';
    END IF;

    -- Update cash collection details
    UPDATE public.orders
    SET 
        cash_collected_amount = p_amount,
        cash_collected_at = now(),
        payment_status = 'paid'
    WHERE id = p_order_id;

    -- Create audit event
    INSERT INTO public.order_events (
        order_id,
        event_type,
        from_status,
        to_status,
        actor_user_id,
        actor_role,
        metadata
    ) VALUES (
        p_order_id,
        'payment',
        NULL,
        NULL,
        v_actor_id,
        'driver',
        jsonb_build_object(
            'cash_collected_amount', p_amount,
            'order_total', v_order_total,
            'collected_at', now()
        )
    );

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'cash_collected_amount', p_amount,
        'collected_at', now()
    );
END;
$$;

-- Function: Admin confirms cash (admin verifies driver's cash collection)
CREATE OR REPLACE FUNCTION public.admin_confirm_cash(
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_actor_id UUID;
    v_actor_role TEXT;
BEGIN
    -- Get authenticated user
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get actor role
    SELECT role INTO v_actor_role FROM public.users WHERE id = v_actor_id;

    -- Only admin can confirm cash
    IF v_actor_role != 'admin' THEN
        RAISE EXCEPTION 'Only admin can confirm cash collection';
    END IF;

    -- Update confirmation
    UPDATE public.orders
    SET cash_confirmed_by_admin = v_actor_id
    WHERE id = p_order_id;

    -- Create audit event
    INSERT INTO public.order_events (
        order_id,
        event_type,
        from_status,
        to_status,
        actor_user_id,
        actor_role,
        metadata
    ) VALUES (
        p_order_id,
        'payment',
        NULL,
        NULL,
        v_actor_id,
        'admin',
        jsonb_build_object(
            'action', 'cash_confirmed_by_admin',
            'confirmed_at', now()
        )
    );

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'confirmed_by', v_actor_id
    );
END;
$$;

-- ========== STEP 6: ENHANCED RLS POLICIES FOR ORDERS ==========
-- Block direct status updates (must use RPC functions)
DROP POLICY IF EXISTS "block_direct_status_updates" ON public.orders;
CREATE POLICY "block_direct_status_updates"
ON public.orders
FOR UPDATE
TO authenticated
USING (
    -- Allow updates to non-critical fields only
    true
)
WITH CHECK (
    -- Block updates to protected fields
    status = (SELECT status FROM public.orders WHERE id = orders.id) AND
    total = (SELECT total FROM public.orders WHERE id = orders.id) AND
    subtotal = (SELECT subtotal FROM public.orders WHERE id = orders.id) AND
    driver_id = (SELECT driver_id FROM public.orders WHERE id = orders.id)
);

-- Customers can view their own orders
DROP POLICY IF EXISTS "customers_view_own_orders" ON public.orders;
CREATE POLICY "customers_view_own_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- Merchants can view orders for their stores
DROP POLICY IF EXISTS "merchants_view_store_orders" ON public.orders;
CREATE POLICY "merchants_view_store_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stores s
        WHERE s.id = store_id AND s.owner_user_id = auth.uid()
    )
);

-- Drivers can view their assigned orders
DROP POLICY IF EXISTS "drivers_view_assigned_orders" ON public.orders;
CREATE POLICY "drivers_view_assigned_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (driver_id = auth.uid());

-- Admin can view all orders
DROP POLICY IF EXISTS "admin_view_all_orders" ON public.orders;
CREATE POLICY "admin_view_all_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() AND u.role = 'admin'
    )
);

-- ========== STEP 7: TRIGGER FOR AUTOMATIC AUDIT LOGGING ==========
-- Automatically log all order status changes
CREATE OR REPLACE FUNCTION public.log_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.order_events (
            order_id,
            event_type,
            from_status,
            to_status,
            actor_user_id,
            actor_role,
            metadata
        ) VALUES (
            NEW.id,
            'status_change',
            OLD.status,
            NEW.status,
            auth.uid(),
            (SELECT role FROM public.users WHERE id = auth.uid()),
            jsonb_build_object(
                'trigger', 'automatic',
                'timestamp', now()
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_log_order_status_change ON public.orders;
CREATE TRIGGER trigger_log_order_status_change
AFTER UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.log_order_status_change();

-- ========== STEP 8: GRANT EXECUTE PERMISSIONS ==========
GRANT EXECUTE ON FUNCTION public.create_order_with_validation TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_order_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_order TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_cash_collection TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_confirm_cash TO authenticated;

-- ========== MIGRATION COMPLETE ==========
-- Summary:
-- ✅ Added COD tracking fields (cash_collected_amount, cash_collected_at, cash_confirmed_by_admin)
-- ✅ Created order_events audit table with immutable event logging
-- ✅ Implemented server-authoritative RPC functions for order state machine
-- ✅ Added comprehensive RLS policies for role-based access control
-- ✅ Blocked direct client updates to protected fields (status, totals, driver_id)
-- ✅ Created automatic audit logging trigger
-- ✅ Enforced strict order status transitions with role validation