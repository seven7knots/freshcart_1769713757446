-- =====================================================
-- MARKETPLACE MESSAGING SYSTEM MIGRATION
-- Purpose: Enable real-time messaging between marketplace buyers and sellers
-- =====================================================

-- ========== STEP 1: CREATE CONVERSATIONS TABLE ==========
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES public.marketplace_listings(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT now(),
    buyer_unread_count INTEGER DEFAULT 0,
    seller_unread_count INTEGER DEFAULT 0,
    is_archived_by_buyer BOOLEAN DEFAULT false,
    is_archived_by_seller BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(buyer_id, seller_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_buyer_id ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller_id ON public.conversations(seller_id);
CREATE INDEX IF NOT EXISTS idx_conversations_listing_id ON public.conversations(listing_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations(last_message_at DESC);

-- ========== STEP 2: CREATE MESSAGES TABLE ==========
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice', 'offer')),
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages(is_read);

-- ========== STEP 3: ENABLE RLS ==========
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ========== STEP 4: RLS POLICIES FOR CONVERSATIONS ==========

-- Users can view conversations where they are buyer or seller
DROP POLICY IF EXISTS "users_view_own_conversations" ON public.conversations;
CREATE POLICY "users_view_own_conversations"
ON public.conversations
FOR SELECT
TO authenticated
USING (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Users can create conversations (buyer initiates)
DROP POLICY IF EXISTS "users_create_conversations" ON public.conversations;
CREATE POLICY "users_create_conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (buyer_id = auth.uid());

-- Users can update their own conversations (unread counts, archive status)
DROP POLICY IF EXISTS "users_update_own_conversations" ON public.conversations;
CREATE POLICY "users_update_own_conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (buyer_id = auth.uid() OR seller_id = auth.uid())
WITH CHECK (buyer_id = auth.uid() OR seller_id = auth.uid());

-- ========== STEP 5: RLS POLICIES FOR MESSAGES ==========

-- Users can view messages in their conversations
DROP POLICY IF EXISTS "users_view_conversation_messages" ON public.messages;
CREATE POLICY "users_view_conversation_messages"
ON public.messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
);

-- Users can send messages in their conversations
DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
);

-- Users can update their own messages (mark as read)
DROP POLICY IF EXISTS "users_update_messages" ON public.messages;
CREATE POLICY "users_update_messages"
ON public.messages
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
);

-- ========== STEP 6: FUNCTIONS FOR UNREAD COUNT MANAGEMENT ==========

-- Function to update conversation timestamp and unread counts
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conv_buyer_id UUID;
    conv_seller_id UUID;
BEGIN
    -- Get conversation participants
    SELECT buyer_id, seller_id INTO conv_buyer_id, conv_seller_id
    FROM public.conversations
    WHERE id = NEW.conversation_id;
    
    -- Update conversation last_message_at
    UPDATE public.conversations
    SET 
        last_message_at = NEW.created_at,
        updated_at = NEW.created_at,
        -- Increment unread count for receiver
        buyer_unread_count = CASE 
            WHEN NEW.sender_id = conv_seller_id THEN buyer_unread_count + 1
            ELSE buyer_unread_count
        END,
        seller_unread_count = CASE 
            WHEN NEW.sender_id = conv_buyer_id THEN seller_unread_count + 1
            ELSE seller_unread_count
        END
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$;

-- Function to decrement unread count when message is read
CREATE OR REPLACE FUNCTION public.handle_message_read()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conv_buyer_id UUID;
    conv_seller_id UUID;
    current_user_id UUID;
BEGIN
    -- Only proceed if message was marked as read
    IF NEW.is_read = true AND OLD.is_read = false THEN
        current_user_id := auth.uid();
        
        -- Get conversation participants
        SELECT buyer_id, seller_id INTO conv_buyer_id, conv_seller_id
        FROM public.conversations
        WHERE id = NEW.conversation_id;
        
        -- Decrement unread count for the reader
        UPDATE public.conversations
        SET 
            buyer_unread_count = CASE 
                WHEN current_user_id = conv_buyer_id AND buyer_unread_count > 0 
                THEN buyer_unread_count - 1
                ELSE buyer_unread_count
            END,
            seller_unread_count = CASE 
                WHEN current_user_id = conv_seller_id AND seller_unread_count > 0 
                THEN seller_unread_count - 1
                ELSE seller_unread_count
            END,
            updated_at = now()
        WHERE id = NEW.conversation_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- ========== STEP 7: TRIGGERS ==========

-- Trigger to update conversation on new message
DROP TRIGGER IF EXISTS on_message_created ON public.messages;
CREATE TRIGGER on_message_created
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_message();

-- Trigger to update unread count when message is read
DROP TRIGGER IF EXISTS on_message_read ON public.messages;
CREATE TRIGGER on_message_read
    AFTER UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_message_read();

-- ========== STEP 8: MOCK DATA ==========

DO $$
DECLARE
    buyer_user_id UUID;
    seller_user_id UUID;
    listing_id UUID;
    conversation_id UUID;
BEGIN
    -- Get existing users (with LIMIT 1 for safety)
    SELECT id INTO buyer_user_id FROM public.users WHERE email = 'user@example.com' LIMIT 1;
    SELECT id INTO seller_user_id FROM public.users WHERE email = 'admin@example.com' LIMIT 1;
    
    -- Get an existing marketplace listing (with LIMIT 1 for safety)
    SELECT id INTO listing_id FROM public.marketplace_listings WHERE is_active = true LIMIT 1;
    
    IF buyer_user_id IS NOT NULL AND seller_user_id IS NOT NULL AND listing_id IS NOT NULL THEN
        -- Create conversation
        INSERT INTO public.conversations (id, buyer_id, seller_id, listing_id, last_message_at)
        VALUES (
            gen_random_uuid(),
            buyer_user_id,
            seller_user_id,
            listing_id,
            now() - INTERVAL '2 hours'
        )
        ON CONFLICT (buyer_id, seller_id, listing_id) DO UPDATE
        SET updated_at = now()
        RETURNING id INTO conversation_id;
        
        -- Create demo messages
        INSERT INTO public.messages (conversation_id, sender_id, content, is_read, created_at)
        VALUES
            (conversation_id, buyer_user_id, 'Hi! Is this item still available?', true, now() - INTERVAL '2 hours'),
            (conversation_id, seller_user_id, 'Yes, it is! Are you interested?', true, now() - INTERVAL '1 hour 50 minutes'),
            (conversation_id, buyer_user_id, 'Great! Can you tell me more about its condition?', true, now() - INTERVAL '1 hour 40 minutes'),
            (conversation_id, seller_user_id, 'It is in excellent condition, barely used. Would you like to see more photos?', false, now() - INTERVAL '30 minutes')
        ON CONFLICT (id) DO NOTHING;
        
        RAISE NOTICE 'Demo conversation and messages created successfully';
    ELSE
        RAISE NOTICE 'Required users or listings not found. Skipping mock data creation.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;