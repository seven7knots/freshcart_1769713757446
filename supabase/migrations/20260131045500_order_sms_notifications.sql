-- Location: supabase/migrations/20260131045500_order_sms_notifications.sql
-- Real-time SMS notifications for order status updates via Twilio

-- 1. Create function to send SMS notification via Edge Function
CREATE OR REPLACE FUNCTION public.send_order_status_sms()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  customer_phone_number TEXT;
  order_num TEXT;
  estimated_time TEXT;
  supabase_url TEXT;
  service_role_key TEXT;
BEGIN
  -- Only send SMS for specific status changes
  IF NEW.status IN ('accepted', 'picked_up', 'delivered') THEN
    -- Get customer phone from order or user table
    IF NEW.customer_phone IS NOT NULL AND NEW.customer_phone != '' THEN
      customer_phone_number := NEW.customer_phone;
    ELSE
      SELECT phone INTO customer_phone_number
      FROM public.users
      WHERE id = NEW.customer_id;
    END IF;

    -- Only proceed if we have a phone number
    IF customer_phone_number IS NOT NULL AND customer_phone_number != '' THEN
      -- Get order number
      order_num := COALESCE(NEW.order_number, 'KJ' || SUBSTRING(NEW.id::TEXT, 1, 6));
      
      -- Format estimated delivery time if available
      IF NEW.estimated_delivery_time IS NOT NULL THEN
        estimated_time := TO_CHAR(NEW.estimated_delivery_time, 'HH24:MI');
      END IF;

      -- Get Supabase URL from environment
      supabase_url := current_setting('app.settings.supabase_url', true);
      
      -- Call Edge Function asynchronously (fire and forget)
      PERFORM
        net.http_post(
          url := supabase_url || '/functions/v1/send-order-sms',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
          ),
          body := jsonb_build_object(
            'to', customer_phone_number,
            'orderNumber', order_num,
            'status', NEW.status,
            'estimatedTime', estimated_time
          )
        );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Create trigger for order status changes
DROP TRIGGER IF EXISTS order_status_sms_trigger ON public.orders;
CREATE TRIGGER order_status_sms_trigger
AFTER UPDATE OF status ON public.orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.send_order_status_sms();

-- 3. Create settings table for storing Supabase configuration (if not exists)
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Enable RLS on app_settings
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- 5. Create policy for app_settings (admin only)
DROP POLICY IF EXISTS "admin_manage_app_settings" ON public.app_settings;
CREATE POLICY "admin_manage_app_settings"
ON public.app_settings
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- 6. Insert default settings (will be updated by admin)
INSERT INTO public.app_settings (key, value)
VALUES 
  ('supabase_url', 'https://your-project.supabase.co'),
  ('service_role_key', 'your-service-role-key')
ON CONFLICT (key) DO NOTHING;

-- 7. Create function to update app_settings updated_at
CREATE OR REPLACE FUNCTION public.update_app_settings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 8. Create trigger for app_settings
DROP TRIGGER IF EXISTS app_settings_updated_at_trigger ON public.app_settings;
CREATE TRIGGER app_settings_updated_at_trigger
BEFORE UPDATE ON public.app_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_app_settings_updated_at();