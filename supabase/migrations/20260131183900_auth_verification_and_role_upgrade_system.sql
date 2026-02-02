-- ============================================================
-- MIGRATION: Auth Verification & Role Upgrade System
-- Purpose: Add email/phone verification tracking, role upgrade requests, and admin approval workflow
-- Timestamp: 20260131183900
-- ============================================================

-- ============================================================
-- SECTION 1: Add verification columns to users table
-- ============================================================

-- Add email_verified and phone_verified columns if they don't exist
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verification_code TEXT,
ADD COLUMN IF NOT EXISTS phone_verification_code TEXT,
ADD COLUMN IF NOT EXISTS email_verification_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS phone_verification_expires_at TIMESTAMPTZ,
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
    user_current_role TEXT NOT NULL,
    requested_role TEXT NOT NULL CHECK (requested_role IN ('driver', 'merchant')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    request_notes TEXT,
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
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

-- Admins can update requests (approve/reject)
DROP POLICY IF EXISTS "admins_update_role_upgrade_requests" ON public.role_upgrade_requests;
CREATE POLICY "admins_update_role_upgrade_requests"
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
-- SECTION 5: Functions for role upgrade workflow
-- ============================================================

-- Function to approve role upgrade request
CREATE OR REPLACE FUNCTION public.approve_role_upgrade_request(
    request_id UUID,
    admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_requested_role TEXT;
    v_admin_role TEXT;
    result JSONB;
BEGIN
    -- Check if caller is admin
    SELECT role INTO v_admin_role
    FROM public.users
    WHERE id = admin_id;

    IF v_admin_role != 'admin' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Unauthorized: Only admins can approve requests'
        );
    END IF;

    -- Get request details
    SELECT user_id, requested_role
    INTO v_user_id, v_requested_role
    FROM public.role_upgrade_requests
    WHERE id = request_id AND status = 'pending';

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Request not found or already processed'
        );
    END IF;

    -- Update user role
    UPDATE public.users
    SET role = v_requested_role,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;

    -- Update request status
    UPDATE public.role_upgrade_requests
    SET status = 'approved',
        reviewed_by = admin_id,
        reviewed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = request_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Role upgrade approved successfully',
        'user_id', v_user_id,
        'new_role', v_requested_role
    );
END;
$$;

-- Function to reject role upgrade request
CREATE OR REPLACE FUNCTION public.reject_role_upgrade_request(
    request_id UUID,
    admin_id UUID,
    reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role TEXT;
    v_request_exists BOOLEAN;
    result JSONB;
BEGIN
    -- Check if caller is admin
    SELECT role INTO v_admin_role
    FROM public.users
    WHERE id = admin_id;

    IF v_admin_role != 'admin' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Unauthorized: Only admins can reject requests'
        );
    END IF;

    -- Check if request exists and is pending
    SELECT EXISTS(
        SELECT 1 FROM public.role_upgrade_requests
        WHERE id = request_id AND status = 'pending'
    ) INTO v_request_exists;

    IF NOT v_request_exists THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Request not found or already processed'
        );
    END IF;

    -- Update request status
    UPDATE public.role_upgrade_requests
    SET status = 'rejected',
        rejection_reason = reason,
        reviewed_by = admin_id,
        reviewed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = request_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Role upgrade request rejected'
    );
END;
$$;

-- ============================================================
-- SECTION 6: Trigger to update updated_at timestamp
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_role_upgrade_requests_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_role_upgrade_requests_updated_at ON public.role_upgrade_requests;
CREATE TRIGGER trigger_update_role_upgrade_requests_updated_at
    BEFORE UPDATE ON public.role_upgrade_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_role_upgrade_requests_updated_at();

-- ============================================================
-- SECTION 7: Grant permissions
-- ============================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.role_upgrade_requests TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_role_upgrade_request TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_role_upgrade_request TO authenticated;

-- ============================================================
-- SECTION 8: Comments for documentation
-- ============================================================

COMMENT ON TABLE public.role_upgrade_requests IS 'Stores role upgrade requests from customers to driver/merchant roles';
COMMENT ON COLUMN public.role_upgrade_requests.user_current_role IS 'The user role at the time of request (typically customer)';
COMMENT ON COLUMN public.role_upgrade_requests.requested_role IS 'The role the user wants to upgrade to (driver or merchant)';
COMMENT ON COLUMN public.role_upgrade_requests.status IS 'Request status: pending, approved, or rejected';
COMMENT ON FUNCTION public.approve_role_upgrade_request IS 'Admin function to approve a role upgrade request and update user role';
COMMENT ON FUNCTION public.reject_role_upgrade_request IS 'Admin function to reject a role upgrade request with optional reason';