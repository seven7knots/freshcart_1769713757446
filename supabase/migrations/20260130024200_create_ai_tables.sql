-- Migration: Create AI logs and meal plans tables
-- Purpose: Support AI conversation logging and meal planning features
-- Created: 2026-01-30

-- =====================================================
-- AI LOGS TABLE
-- =====================================================
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ai_logs') THEN
    CREATE TABLE public.ai_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
      conversation_id UUID NOT NULL,
      message_type TEXT NOT NULL CHECK (message_type IN ('user', 'assistant', 'system')),
      content TEXT NOT NULL,
      context_data JSONB,
      tool_calls JSONB,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create indexes for performance
    CREATE INDEX IF NOT EXISTS idx_ai_logs_user_id ON public.ai_logs(user_id);
    CREATE INDEX IF NOT EXISTS idx_ai_logs_conversation_id ON public.ai_logs(conversation_id);
    CREATE INDEX IF NOT EXISTS idx_ai_logs_created_at ON public.ai_logs(created_at DESC);

    -- Enable RLS
    ALTER TABLE public.ai_logs ENABLE ROW LEVEL SECURITY;

    -- RLS Policies
    CREATE POLICY "Users can view their own AI logs"
      ON public.ai_logs
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own AI logs"
      ON public.ai_logs
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Admins can view all AI logs"
      ON public.ai_logs
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM public.users
          WHERE users.id = auth.uid()
          AND users.role = 'admin'
        )
      );
  END IF;
END $$;

-- =====================================================
-- MEAL PLANS TABLE
-- =====================================================
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'meal_plans') THEN
    CREATE TABLE public.meal_plans (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      diet_type TEXT NOT NULL,
      budget DECIMAL(10, 2) NOT NULL,
      household_size INTEGER NOT NULL DEFAULT 1,
      meal_count INTEGER NOT NULL DEFAULT 7,
      cuisine_preferences TEXT[],
      meals JSONB NOT NULL,
      grocery_list JSONB NOT NULL,
      estimated_cost DECIMAL(10, 2) NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create indexes
    CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON public.meal_plans(user_id);
    CREATE INDEX IF NOT EXISTS idx_meal_plans_created_at ON public.meal_plans(created_at DESC);

    -- Enable RLS
    ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;

    -- RLS Policies
    CREATE POLICY "Users can view their own meal plans"
      ON public.meal_plans
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own meal plans"
      ON public.meal_plans
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own meal plans"
      ON public.meal_plans
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own meal plans"
      ON public.meal_plans
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;
