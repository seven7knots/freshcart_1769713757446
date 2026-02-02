-- Admin Panel Setup Migration
-- Creates admin-specific RLS policies and helper functions

-- 1. Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  )
$$;

-- 2. Create function to get admin statistics
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS TABLE(
  active_orders_count BIGINT,
  online_drivers_count BIGINT,
  today_revenue NUMERIC,
  today_new_users BIGINT,
  today_new_merchants BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  today_start TIMESTAMPTZ := date_trunc('day', now());
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.orders WHERE status IN ('pending', 'confirmed', 'preparing', 'ready', 'assigned', 'picked_up', 'in_transit'))::BIGINT AS active_orders_count,
    (SELECT COUNT(*) FROM public.drivers WHERE is_online = true AND is_active = true)::BIGINT AS online_drivers_count,
    (SELECT COALESCE(SUM(total), 0) FROM public.orders WHERE created_at >= today_start AND payment_status = 'paid')::NUMERIC AS today_revenue,
    (SELECT COUNT(*) FROM public.users WHERE created_at >= today_start AND role = 'customer')::BIGINT AS today_new_users,
    (SELECT COUNT(*) FROM public.merchants WHERE created_at >= today_start)::BIGINT AS today_new_merchants;
END;
$$;

-- 3. Create function to get users list with filters
CREATE OR REPLACE FUNCTION public.get_users_for_admin(
  search_query TEXT DEFAULT NULL,
  filter_role TEXT DEFAULT NULL,
  filter_status BOOLEAN DEFAULT NULL,
  limit_count INT DEFAULT 50,
  offset_count INT DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  email TEXT,
  phone TEXT,
  full_name TEXT,
  role TEXT,
  wallet_balance NUMERIC,
  is_verified BOOLEAN,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  order_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.phone,
    u.full_name,
    u.role,
    u.wallet_balance,
    u.is_verified,
    u.is_active,
    u.created_at,
    (SELECT COUNT(*) FROM public.orders o WHERE o.customer_id = u.id)::BIGINT AS order_count
  FROM public.users u
  WHERE
    (search_query IS NULL OR 
     u.full_name ILIKE '%' || search_query || '%' OR 
     u.email ILIKE '%' || search_query || '%' OR
     u.phone ILIKE '%' || search_query || '%')
    AND (filter_role IS NULL OR u.role = filter_role)
    AND (filter_status IS NULL OR u.is_active = filter_status)
  ORDER BY u.created_at DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$;

-- 4. Create function to adjust user wallet balance
CREATE OR REPLACE FUNCTION public.admin_adjust_wallet_balance(
  target_user_id UUID,
  adjustment_amount NUMERIC,
  adjustment_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_balance NUMERIC;
  new_balance NUMERIC;
  wallet_uuid UUID;
BEGIN
  -- Check if caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can adjust wallet balances';
  END IF;

  -- Get current wallet
  SELECT id, balance INTO wallet_uuid, current_balance
  FROM public.wallets
  WHERE user_id = target_user_id;

  -- Calculate new balance
  new_balance := current_balance + adjustment_amount;

  -- Ensure balance doesn't go negative
  IF new_balance < 0 THEN
    RAISE EXCEPTION 'Adjustment would result in negative balance';
  END IF;

  -- Update wallet balance
  UPDATE public.wallets
  SET balance = new_balance, updated_at = now()
  WHERE user_id = target_user_id;

  -- Create transaction record
  INSERT INTO public.transactions (
    wallet_id,
    type,
    amount,
    balance_before,
    balance_after,
    reference_type,
    description,
    status,
    created_by
  ) VALUES (
    wallet_uuid,
    'adjustment',
    adjustment_amount,
    current_balance,
    new_balance,
    'admin_adjustment',
    adjustment_reason,
    'completed',
    auth.uid()
  );

  -- Log admin action
  INSERT INTO public.audit_logs (
    admin_id,
    action,
    entity_type,
    entity_id,
    old_value,
    new_value
  ) VALUES (
    auth.uid(),
    'wallet_adjustment',
    'wallet',
    wallet_uuid,
    jsonb_build_object('balance', current_balance),
    jsonb_build_object('balance', new_balance, 'reason', adjustment_reason)
  );

  RETURN TRUE;
END;
$$;

-- 5. Create function to update user status
CREATE OR REPLACE FUNCTION public.admin_update_user_status(
  target_user_id UUID,
  new_status BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_status BOOLEAN;
BEGIN
  -- Check if caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can update user status';
  END IF;

  -- Get old status
  SELECT is_active INTO old_status FROM public.users WHERE id = target_user_id;

  -- Update user status
  UPDATE public.users
  SET is_active = new_status, updated_at = now()
  WHERE id = target_user_id;

  -- Log admin action
  INSERT INTO public.audit_logs (
    admin_id,
    action,
    entity_type,
    entity_id,
    old_value,
    new_value
  ) VALUES (
    auth.uid(),
    'user_status_update',
    'user',
    target_user_id,
    jsonb_build_object('is_active', old_status),
    jsonb_build_object('is_active', new_status)
  );

  RETURN TRUE;
END;
$$;

-- 6. Add RLS policies for admin access to all tables
-- Admin can view all users
DROP POLICY IF EXISTS "admin_view_all_users" ON public.users;
CREATE POLICY "admin_view_all_users"
ON public.users
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all orders
DROP POLICY IF EXISTS "admin_view_all_orders" ON public.orders;
CREATE POLICY "admin_view_all_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all drivers
DROP POLICY IF EXISTS "admin_view_all_drivers" ON public.drivers;
CREATE POLICY "admin_view_all_drivers"
ON public.drivers
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all stores
DROP POLICY IF EXISTS "admin_view_all_stores" ON public.stores;
CREATE POLICY "admin_view_all_stores"
ON public.stores
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all transactions
DROP POLICY IF EXISTS "admin_view_all_transactions" ON public.transactions;
CREATE POLICY "admin_view_all_transactions"
ON public.transactions
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all wallets
DROP POLICY IF EXISTS "admin_view_all_wallets" ON public.wallets;
CREATE POLICY "admin_view_all_wallets"
ON public.wallets
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all merchants
DROP POLICY IF EXISTS "admin_view_all_merchants" ON public.merchants;
CREATE POLICY "admin_view_all_merchants"
ON public.merchants
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all subscription plans
DROP POLICY IF EXISTS "admin_view_all_subscription_plans" ON public.subscription_plans;
CREATE POLICY "admin_view_all_subscription_plans"
ON public.subscription_plans
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all promo codes
DROP POLICY IF EXISTS "admin_view_all_promo_codes" ON public.promo_codes;
CREATE POLICY "admin_view_all_promo_codes"
ON public.promo_codes
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all push campaigns
DROP POLICY IF EXISTS "admin_view_all_push_campaigns" ON public.push_campaigns;
CREATE POLICY "admin_view_all_push_campaigns"
ON public.push_campaigns
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admin can view all system settings
DROP POLICY IF EXISTS "admin_view_all_system_settings" ON public.system_settings;
CREATE POLICY "admin_view_all_system_settings"
ON public.system_settings
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Admin can view all audit logs
DROP POLICY IF EXISTS "admin_view_all_audit_logs" ON public.audit_logs;
CREATE POLICY "admin_view_all_audit_logs"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (public.is_admin());

-- 7. Create initial admin user (if not exists)
DO $$
DECLARE
  admin_user_id UUID;
BEGIN
  -- Check if admin user already exists
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'admin@kjdelivery.com' LIMIT 1;
  
  IF admin_user_id IS NULL THEN
    -- Create admin user in auth.users
    admin_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
      is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
      recovery_token, recovery_sent_at, email_change_token_new, email_change,
      email_change_sent_at, email_change_token_current, email_change_confirm_status,
      reauthentication_token, reauthentication_sent_at, phone, phone_change,
      phone_change_token, phone_change_sent_at
    ) VALUES (
      admin_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'admin@kjdelivery.com', crypt('Admin@123', gen_salt('bf', 10)), now(), now(), now(),
      jsonb_build_object('full_name', 'System Administrator', 'role', 'admin'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    )
    ON CONFLICT (id) DO NOTHING;

    -- Create admin user profile
    INSERT INTO public.users (
      id, email, full_name, role, is_verified, is_active
    ) VALUES (
      admin_user_id, 'admin@kjdelivery.com', 'System Administrator', 'admin', true, true
    )
    ON CONFLICT (id) DO NOTHING;

    -- Create wallet for admin
    INSERT INTO public.wallets (user_id, balance)
    VALUES (admin_user_id, 0.00)
    ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE 'Admin user created: admin@kjdelivery.com / Admin@123';
  ELSE
    RAISE NOTICE 'Admin user already exists';
  END IF;
END $$;