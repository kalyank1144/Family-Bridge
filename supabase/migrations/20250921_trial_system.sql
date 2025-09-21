-- Add trial fields to user_profiles
ALTER TABLE user_profiles ADD COLUMN trial_start_date TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE user_profiles ADD COLUMN trial_end_date TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days');
ALTER TABLE user_profiles ADD COLUMN subscription_status TEXT DEFAULT 'trial';
ALTER TABLE user_profiles ADD COLUMN feature_usage_tracking JSONB DEFAULT '{}';

-- Create subscription_plans table
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price_monthly DECIMAL(10,2),
  features JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert basic plans
INSERT INTO subscription_plans (name, price_monthly, features) VALUES 
('free', 0.00, '{"media_storage_gb": 1, "emergency_contacts": 3, "story_recordings_per_month": 3, "voice_transcription_minutes": 60}'),
('premium', 9.99, '{"media_storage_gb": -1, "emergency_contacts": -1, "story_recordings_per_month": -1, "voice_transcription_minutes": -1}');