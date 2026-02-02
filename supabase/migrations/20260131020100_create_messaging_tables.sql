-- ========================================
-- MESSAGING SYSTEM FOR MARKETPLACE
-- ========================================
-- Creates conversations and messages tables for buyer-seller communication
-- with real-time subscriptions, unread count tracking, and proper RLS policies

-- ========== CONVERSATIONS TABLE ==========

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
    CONSTRAINT unique_conversation UNIQUE(buyer_id, seller_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_buyer_id ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller_id ON public.conversations(seller_id);
CREATE INDEX IF NOT EXISTS idx_conversations_listing_id ON public.conversations(listing_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations(last_message_at DESC);

-- ========== MESSAGES TABLE ==========

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'inquiry')),
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

-- ========== TRIGGER FUNCTIONS ==========

-- Function to update conversation last_message_at and increment unread count
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

    -- Update conversation timestamp and increment unread count for recipient
    IF NEW.sender_id = conv_buyer_id THEN
        -- Message from buyer, increment seller unread count
        UPDATE public.conversations
        SET 
            last_message_at = NEW.created_at,
            seller_unread_count = seller_unread_count + 1,
            updated_at = now()
        WHERE id = NEW.conversation_id;
    ELSE
        -- Message from seller, increment buyer unread count
        UPDATE public.conversations
        SET 
            last_message_at = NEW.created_at,
            buyer_unread_count = buyer_unread_count + 1,
            updated_at = now()
        WHERE id = NEW.conversation_id;
    END IF;

    RETURN NEW;
END;
$$;

-- Function to update conversation timestamp
CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ========== TRIGGERS ==========

DROP TRIGGER IF EXISTS on_message_created ON public.messages;
CREATE TRIGGER on_message_created
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_message();

DROP TRIGGER IF EXISTS on_conversation_updated ON public.conversations;
CREATE TRIGGER on_conversation_updated
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_timestamp();

-- ========== ENABLE RLS ==========

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ========== RLS POLICIES ==========

-- Conversations: Users can see conversations they participate in
DROP POLICY IF EXISTS "users_view_own_conversations" ON public.conversations;
CREATE POLICY "users_view_own_conversations"
ON public.conversations
FOR SELECT
TO authenticated
USING (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Conversations: Users can create conversations as buyers
DROP POLICY IF EXISTS "users_create_conversations_as_buyer" ON public.conversations;
CREATE POLICY "users_create_conversations_as_buyer"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (buyer_id = auth.uid());

-- Conversations: Users can update their own conversation settings
DROP POLICY IF EXISTS "users_update_own_conversations" ON public.conversations;
CREATE POLICY "users_update_own_conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (buyer_id = auth.uid() OR seller_id = auth.uid())
WITH CHECK (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Messages: Users can view messages in their conversations
DROP POLICY IF EXISTS "users_view_conversation_messages" ON public.messages;
CREATE POLICY "users_view_conversation_messages"
ON public.messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation_id
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
);

-- Messages: Users can send messages in their conversations
DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation_id
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
);

-- Messages: Users can update their sent messages (mark as read)
DROP POLICY IF EXISTS "users_update_messages" ON public.messages;
CREATE POLICY "users_update_messages"
ON public.messages
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation_id
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation_id
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
);

-- ========== DEMO DATA ==========

DO $$
DECLARE
    demo_buyer_id UUID;
    demo_seller_id UUID;
    demo_listing_id UUID;
    demo_conversation_id UUID;
BEGIN
    -- Get existing users (from previous migrations)
    SELECT id INTO demo_buyer_id FROM public.users WHERE email = 'user@example.com' LIMIT 1;
    SELECT id INTO demo_seller_id FROM public.users WHERE email = 'seller@marketplace.com' LIMIT 1;
    
    -- Get an existing marketplace listing
    SELECT id INTO demo_listing_id FROM public.marketplace_listings WHERE user_id = demo_seller_id LIMIT 1;
    
    IF demo_buyer_id IS NOT NULL AND demo_seller_id IS NOT NULL AND demo_listing_id IS NOT NULL THEN
        -- Create demo conversation
        INSERT INTO public.conversations (
            id,
            buyer_id,
            seller_id,
            listing_id,
            last_message_at,
            buyer_unread_count,
            seller_unread_count
        ) VALUES (
            gen_random_uuid(),
            demo_buyer_id,
            demo_seller_id,
            demo_listing_id,
            now() - INTERVAL '1 hour',
            1,
            0
        )
        ON CONFLICT (buyer_id, seller_id, listing_id) DO NOTHING
        RETURNING id INTO demo_conversation_id;
        
        -- If conversation was created, add demo messages
        IF demo_conversation_id IS NOT NULL THEN
            -- Buyer inquiry
            INSERT INTO public.messages (
                conversation_id,
                sender_id,
                content,
                message_type,
                is_read,
                created_at
            ) VALUES (
                demo_conversation_id,
                demo_buyer_id,
                'Hi! Is this item still available?',
                'inquiry',
                true,
                now() - INTERVAL '1 hour'
            ) ON CONFLICT DO NOTHING;
            
            -- Seller response
            INSERT INTO public.messages (
                conversation_id,
                sender_id,
                content,
                message_type,
                is_read,
                created_at
            ) VALUES (
                demo_conversation_id,
                demo_seller_id,
                'Yes, it is! Would you like to know more details?',
                'text',
                true,
                now() - INTERVAL '50 minutes'
            ) ON CONFLICT DO NOTHING;
            
            -- Buyer follow-up (unread)
            INSERT INTO public.messages (
                conversation_id,
                sender_id,
                content,
                message_type,
                is_read,
                created_at
            ) VALUES (
                demo_conversation_id,
                demo_buyer_id,
                'Can you negotiate on the price?',
                'text',
                false,
                now() - INTERVAL '30 minutes'
            ) ON CONFLICT DO NOTHING;
            
            RAISE NOTICE 'Demo conversation and messages created successfully';
        END IF;
    ELSE
        RAISE NOTICE 'Required demo users or listings not found. Skipping demo data creation.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating demo messaging data: %', SQLERRM;
END $$;

RAISE NOTICE 'Messaging system migration completed successfully';