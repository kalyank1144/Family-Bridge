-- Device tokens for push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('elder','caregiver','youth')),
  family_id uuid NULL,
  platform text NOT NULL CHECK (platform IN ('ios','android','web')),
  token text NOT NULL UNIQUE,
  topics text[] DEFAULT ARRAY[]::text[],
  last_seen timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY device_tokens_owner_select ON public.device_tokens FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY device_tokens_owner_upsert ON public.device_tokens FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY device_tokens_owner_update ON public.device_tokens FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User notification preferences
CREATE TABLE IF NOT EXISTS public.user_notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferences jsonb NOT NULL DEFAULT '{}',
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.user_notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_prefs_owner_select ON public.user_notification_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY user_prefs_owner_upsert ON public.user_notification_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY user_prefs_owner_update ON public.user_notification_preferences FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Notification delivery log
CREATE TABLE IF NOT EXISTS public.notifications_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,
  priority text NOT NULL,
  title text,
  body text,
  payload jsonb,
  delivered_at timestamptz DEFAULT now(),
  opened_at timestamptz,
  acknowledged_at timestamptz
);
ALTER TABLE public.notifications_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY notif_log_owner_select ON public.notifications_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY notif_log_owner_insert ON public.notifications_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Emergency events with escalation
CREATE TABLE IF NOT EXISTS public.emergency_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL,
  initiator_id uuid NOT NULL REFERENCES auth.users(id),
  title text,
  message text,
  help_type text NOT NULL,
  location text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','escalated','resolved')),
  acknowledged_by text[] DEFAULT ARRAY[]::text[],
  acknowledged_at timestamptz,
  escalated_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.emergency_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY emergency_events_family_read ON public.emergency_events FOR SELECT USING (true);
CREATE POLICY emergency_events_owner_insert ON public.emergency_events FOR INSERT WITH CHECK (auth.uid() = initiator_id);
CREATE POLICY emergency_events_owner_update ON public.emergency_events FOR UPDATE USING (auth.uid() = initiator_id);
