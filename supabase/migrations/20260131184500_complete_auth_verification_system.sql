-- ============================================================
-- COMPLETE AUTH VERIFICATION & ROLE UPGRADE SYSTEM
-- Migration: 20260131184500
-- ============================================================

-- ============================================================
-- SECTION 1: Add verification columns to users table
-- ============================================================

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_otp TEXT,
ADD COLUMN IF NOT EXISTS phone_otp TEXT,
ADD COLUMN IF NOT EXISTS email_otp_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS phone_otp_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS verification_completed_at TIMESTAMPTZ;

-- ============================================================
-- SECTION 2: Create role_upgrade_requests table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.role_upgrade_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone TEXT,
    requested_role TEXT NOT NULL CHECK (requested_role IN ('driver', 'merchant')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    application_data JSONB DEFAULT '{}'::jsonb,
    notes TEXT,
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_role_upgrade_requests_user_id ON public.role_upgrade_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_role_upgrade_requests_status ON public.role_upgrade_requests(status);
CREATE INDEX IF NOT EXISTS idx_role_upgrade_requests_created_at ON public.role_upgrade_requests(created_at DESC);

-- ============================================================
-- SECTION 3: Enable RLS
-- ============================================================

ALTER TABLE public.role_upgrade_requests ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 4: RLS Policies for role_upgrade_requests
-- ============================================================

-- Users can view their own requests
DROP POLICY IF EXISTS "users_view_own_role_upgrade_requests" ON public.role_upgrade_requests;
CREATE POLICY "users_view_own_role_upgrade_requests"
ON public.role_upgrade_requests
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own requests
DROP POLICY IF EXISTS "users_create_own_role_upgrade_requests" ON public.role_upgrade_requests;
CREATE POLICY "users_create_own_role_upgrade_requests"
ON public.role_upgrade_requests
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Admins can view all requests
DROP POLICY IF EXISTS "admins_view_all_role_upgrade_requests" ON public.role_upgrade_requests;
CREATE POLICY "admins_view_all_role_upgrade_requests"
ON public.role_upgrade_requests
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Admins can update all requests
DROP POLICY IF EXISTS "admins_update_all_role_upgrade_requests" ON public.role_upgrade_requests;
CREATE POLICY "admins_update_all_role_upgrade_requests"
ON public.role_upgrade_requests
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- ============================================================
-- SECTION 5: Functions for OTP generation and verification
-- ============================================================

-- Generate 6-digit OTP
CREATE OR REPLACE FUNCTION public.generate_otp()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$;

-- Send email OTP (stores in database, actual sending via Supabase Auth)
CREATE OR REPLACE FUNCTION public.send_email_otp(user_email TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    otp_code TEXT;
    user_record RECORD;
BEGIN
    -- Generate OTP
    otp_code := public.generate_otp();
    
    -- Update user record
    UPDATE public.users
    SET 
        email_otp = otp_code,
        email_otp_expires_at = NOW() + INTERVAL '10 minutes'
    WHERE email = user_email
    RETURNING * INTO user_record;
    
    IF user_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User not found'
        );
    END IF;
    
    -- Return success (actual email sending handled by Supabase Auth)
    RETURN jsonb_build_object(
        'success', true,
        'message', 'OTP sent to email',
        'otp', otp_code,
        'expires_at', user_record.email_otp_expires_at
    );
END;
$$;

-- Verify email OTP
CREATE OR REPLACE FUNCTION public.verify_email_otp(user_email TEXT, otp_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Check OTP
    SELECT * INTO user_record
    FROM public.users
    WHERE email = user_email
    AND email_otp = otp_code
    AND email_otp_expires_at > NOW();
    
    IF user_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid or expired OTP'
        );
    END IF;
    
    -- Mark email as verified
    UPDATE public.users
    SET 
        email_verified = true,
        email_otp = NULL,
        email_otp_expires_at = NULL
    WHERE email = user_email;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Email verified successfully'
    );
END;
$$;

-- Send phone OTP (stores in database, actual sending via Twilio edge function)
CREATE OR REPLACE FUNCTION public.send_phone_otp(user_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    otp_code TEXT;
    user_record RECORD;
BEGIN
    -- Generate OTP
    otp_code := public.generate_otp();
    
    -- Update user record
    UPDATE public.users
    SET 
        phone_otp = otp_code,
        phone_otp_expires_at = NOW() + INTERVAL '10 minutes'
    WHERE phone = user_phone
    RETURNING * INTO user_record;
    
    IF user_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User not found'
        );
    END IF;
    
    -- Return success (actual SMS sending handled by Twilio edge function)
    RETURN jsonb_build_object(
        'success', true,
        'message', 'OTP sent to phone',
        'otp', otp_code,
        'expires_at', user_record.phone_otp_expires_at
    );
END;
$$;

-- Verify phone OTP
CREATE OR REPLACE FUNCTION public.verify_phone_otp(user_phone TEXT, otp_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Check OTP
    SELECT * INTO user_record
    FROM public.users
    WHERE phone = user_phone
    AND phone_otp = otp_code
    AND phone_otp_expires_at > NOW();
    
    IF user_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid or expired OTP'
        );
    END IF;
    
    -- Mark phone as verified and complete verification
    UPDATE public.users
    SET 
        phone_verified = true,
        phone_otp = NULL,
        phone_otp_expires_at = NULL,
        is_verified = true,
        verification_completed_at = NOW()
    WHERE phone = user_phone;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Phone verified successfully'
    );
END;
$$;

-- ============================================================
-- SECTION 6: Trigger for role upgrade approval
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_role_upgrade_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- When request is approved, update user role
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        UPDATE public.users
        SET role = NEW.requested_role
        WHERE id = NEW.user_id;
        
        -- Set reviewed timestamp
        NEW.reviewed_at := NOW();
        NEW.reviewed_by := auth.uid();
    END IF;
    
    -- Set updated timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_role_upgrade_approval ON public.role_upgrade_requests;
CREATE TRIGGER on_role_upgrade_approval
    BEFORE UPDATE ON public.role_upgrade_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_role_upgrade_approval();

-- ============================================================
-- SECTION 7: Function to create user profile on signup
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Create user profile with customer role by default
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone,
        role,
        is_verified,
        email_verified,
        phone_verified
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        'customer',
        false,
        false,
        false
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_signup();

-- ============================================================
-- SECTION 8: Helper function to check verification status
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_user_fully_verified(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COALESCE(
        (SELECT email_verified AND phone_verified
         FROM public.users
         WHERE id = user_id),
        false
    );
$$;

-- ============================================================
-- SECTION 9: Grant necessary permissions
-- ============================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.role_upgrade_requests TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_otp() TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_email_otp(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_email_otp(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_phone_otp(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_phone_otp(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_user_fully_verified(UUID) TO authenticated;

RAISE NOTICE '✅ Auth verification and role upgrade system migration completed successfully';