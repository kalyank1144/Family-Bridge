-- Stripe Payment Integration Migration
-- This migration adds Stripe subscription and payment processing capabilities
-- Run this after existing authentication and family system migrations

-- Extensions needed for UUID generation and encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Add Stripe customer and subscription fields to user_profiles
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'trial';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS subscription_current_period_end TIMESTAMPTZ;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days';

-- Payment methods storage (encrypted for PCI compliance)
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_payment_method_id TEXT NOT NULL,
  card_last_four TEXT,
  card_brand TEXT,
  card_exp_month INTEGER,
  card_exp_year INTEGER,
  billing_name TEXT,
  billing_email TEXT,
  billing_address JSONB DEFAULT '{}'::JSONB,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- Users can only access their own payment methods
CREATE POLICY "Users manage own payment methods" ON public.payment_methods
  FOR ALL USING (auth.uid() = user_id);

-- Subscription events log (for webhook processing and audit trail)
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_event_id TEXT UNIQUE,
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  event_type TEXT NOT NULL,
  event_data JSONB DEFAULT '{}'::JSONB,
  processed BOOLEAN DEFAULT FALSE,
  processing_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Admins can view all events, users can view their own
CREATE POLICY "Users view own subscription events" ON public.subscription_events
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.user_profiles up 
      WHERE up.user_id = auth.uid() AND up.consent->>'admin_role' = 'true'
    )
  );

-- Simple billing history for user transparency
CREATE TABLE IF NOT EXISTS public.billing_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_invoice_id TEXT,
  stripe_payment_intent_id TEXT,
  amount_paid DECIMAL(10,2),
  currency TEXT DEFAULT 'usd',
  status TEXT,
  billing_reason TEXT,
  invoice_url TEXT,
  receipt_url TEXT,
  description TEXT,
  period_start TIMESTAMPTZ,
  period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.billing_history ENABLE ROW LEVEL SECURITY;

-- Users can only view their own billing history
CREATE POLICY "Users view own billing history" ON public.billing_history
  FOR SELECT USING (auth.uid() = user_id);

-- Subscription plan configurations (stored in database for flexibility)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  stripe_price_id TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'usd',
  interval TEXT NOT NULL CHECK (interval IN ('day', 'week', 'month', 'year')),
  interval_count INTEGER DEFAULT 1,
  trial_period_days INTEGER DEFAULT 30,
  features JSONB DEFAULT '{}'::JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default premium plan
INSERT INTO public.subscription_plans (name, description, stripe_price_id, amount, interval, trial_period_days, features)
VALUES (
  'Premium Family Plan',
  'Complete family care coordination with unlimited features',
  'price_dev_premium_monthly', -- Will be replaced in production
  9.99,
  'month',
  30,
  '{
    "unlimited_family_members": true,
    "advanced_health_monitoring": true,
    "professional_reports": true,
    "priority_support": true,
    "offline_mode": true,
    "data_export": true,
    "custom_reminders": true
  }'::JSONB
) ON CONFLICT DO NOTHING;

-- Failed payment attempts tracking (for retry logic)
CREATE TABLE IF NOT EXISTS public.failed_payment_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_subscription_id TEXT,
  stripe_payment_intent_id TEXT,
  failure_code TEXT,
  failure_message TEXT,
  decline_code TEXT,
  attempt_number INTEGER DEFAULT 1,
  next_retry_at TIMESTAMPTZ,
  max_retries INTEGER DEFAULT 3,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.failed_payment_attempts ENABLE ROW LEVEL SECURITY;

-- Users can view their own payment failures
CREATE POLICY "Users view own payment failures" ON public.failed_payment_attempts
  FOR SELECT USING (auth.uid() = user_id);

-- Offline payment queue (for when payments fail due to connectivity)
CREATE TABLE IF NOT EXISTS public.offline_payment_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  payment_type TEXT NOT NULL CHECK (payment_type IN ('subscription_upgrade', 'payment_method_update', 'retry_failed_payment')),
  payment_data JSONB NOT NULL DEFAULT '{}'::JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5,
  next_attempt_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

ALTER TABLE public.offline_payment_queue ENABLE ROW LEVEL SECURITY;

-- Users can view their own payment queue
CREATE POLICY "Users view own payment queue" ON public.offline_payment_queue
  FOR SELECT USING (auth.uid() = user_id);

-- Function to check if user has active subscription
CREATE OR REPLACE FUNCTION public.has_active_subscription(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  profile_record RECORD;
BEGIN
  SELECT * INTO profile_record
  FROM public.user_profiles
  WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Check if trial is still active
  IF profile_record.subscription_status = 'trial' AND profile_record.trial_ends_at > NOW() THEN
    RETURN TRUE;
  END IF;
  
  -- Check if paid subscription is active
  IF profile_record.subscription_status = 'active' AND 
     profile_record.subscription_current_period_end > NOW() THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$;

-- Function to get subscription status with details
CREATE OR REPLACE FUNCTION public.get_subscription_status(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  profile_record RECORD;
  result JSON;
BEGIN
  SELECT * INTO profile_record
  FROM public.user_profiles
  WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'status', 'not_found',
      'message', 'User profile not found'
    );
  END IF;
  
  -- Build status response
  result := json_build_object(
    'status', profile_record.subscription_status,
    'trial_started_at', profile_record.trial_started_at,
    'trial_ends_at', profile_record.trial_ends_at,
    'current_period_end', profile_record.subscription_current_period_end,
    'stripe_customer_id', profile_record.stripe_customer_id,
    'stripe_subscription_id', profile_record.stripe_subscription_id,
    'is_trial_active', (profile_record.subscription_status = 'trial' AND profile_record.trial_ends_at > NOW()),
    'is_subscription_active', (profile_record.subscription_status = 'active' AND profile_record.subscription_current_period_end > NOW()),
    'days_remaining', CASE 
      WHEN profile_record.subscription_status = 'trial' THEN EXTRACT(days FROM (profile_record.trial_ends_at - NOW()))
      WHEN profile_record.subscription_status = 'active' THEN EXTRACT(days FROM (profile_record.subscription_current_period_end - NOW()))
      ELSE 0
    END
  );
  
  RETURN result;
END;
$$;

-- Function to start trial for new user
CREATE OR REPLACE FUNCTION public.start_user_trial(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update user profile to start trial
  UPDATE public.user_profiles
  SET 
    subscription_status = 'trial',
    trial_started_at = NOW(),
    trial_ends_at = NOW() + INTERVAL '30 days'
  WHERE user_id = p_user_id;
  
  RETURN FOUND;
END;
$$;

-- Function to update subscription status from webhooks
CREATE OR REPLACE FUNCTION public.update_subscription_status(
  p_stripe_customer_id TEXT,
  p_stripe_subscription_id TEXT,
  p_status TEXT,
  p_current_period_end TIMESTAMPTZ DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected_rows INTEGER;
BEGIN
  UPDATE public.user_profiles
  SET 
    subscription_status = p_status,
    stripe_subscription_id = p_stripe_subscription_id,
    subscription_current_period_end = COALESCE(p_current_period_end, subscription_current_period_end),
    updated_at = NOW()
  WHERE stripe_customer_id = p_stripe_customer_id;
  
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  RETURN affected_rows > 0;
END;
$$;

-- Function to log subscription events (from webhooks)
CREATE OR REPLACE FUNCTION public.log_subscription_event(
  p_user_id UUID,
  p_stripe_event_id TEXT,
  p_stripe_subscription_id TEXT,
  p_stripe_customer_id TEXT,
  p_event_type TEXT,
  p_event_data JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  event_id UUID;
BEGIN
  INSERT INTO public.subscription_events (
    user_id,
    stripe_event_id,
    stripe_subscription_id,
    stripe_customer_id,
    event_type,
    event_data
  )
  VALUES (
    p_user_id,
    p_stripe_event_id,
    p_stripe_subscription_id,
    p_stripe_customer_id,
    p_event_type,
    p_event_data
  )
  RETURNING id INTO event_id;
  
  RETURN event_id;
END;
$$;

-- Trigger to update payment_methods updated_at
CREATE OR REPLACE FUNCTION public.update_payment_methods_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_payment_methods_updated_at
  BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION public.update_payment_methods_updated_at();

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_stripe_customer ON public.user_profiles(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_status ON public.user_profiles(subscription_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_trial_ends ON public.user_profiles(trial_ends_at);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_stripe_id ON public.payment_methods(stripe_payment_method_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_user ON public.subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_stripe_event ON public.subscription_events(stripe_event_id);
CREATE INDEX IF NOT EXISTS idx_billing_history_user ON public.billing_history(user_id);
CREATE INDEX IF NOT EXISTS idx_failed_payment_attempts_user ON public.failed_payment_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_payment_queue_user ON public.offline_payment_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_payment_queue_status ON public.offline_payment_queue(status, next_attempt_at);

-- Storage bucket for receipts and invoices
INSERT INTO storage.buckets (id, name, public) 
VALUES ('billing-documents','billing-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Billing document policies
CREATE POLICY "Users upload own billing documents" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'billing-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users view own billing documents" ON storage.objects
FOR SELECT USING (bucket_id = 'billing-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create view for subscription dashboard
CREATE OR REPLACE VIEW public.user_subscription_view AS
SELECT 
  up.user_id,
  u.name,
  u.email,
  up.subscription_status,
  up.stripe_customer_id,
  up.stripe_subscription_id,
  up.trial_started_at,
  up.trial_ends_at,
  up.subscription_current_period_end,
  CASE 
    WHEN up.subscription_status = 'trial' AND up.trial_ends_at > NOW() THEN 
      EXTRACT(days FROM (up.trial_ends_at - NOW()))
    WHEN up.subscription_status = 'active' AND up.subscription_current_period_end > NOW() THEN 
      EXTRACT(days FROM (up.subscription_current_period_end - NOW()))
    ELSE 0
  END as days_remaining,
  (up.subscription_status = 'trial' AND up.trial_ends_at > NOW()) OR 
  (up.subscription_status = 'active' AND up.subscription_current_period_end > NOW()) as has_active_access,
  up.trial_ends_at - INTERVAL '3 days' <= NOW() AND up.subscription_status = 'trial' as trial_ending_soon
FROM public.user_profiles up
JOIN auth.users u ON up.user_id = u.id;