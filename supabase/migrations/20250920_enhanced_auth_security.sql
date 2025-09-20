-- Enhanced Authentication Security Migration
-- Adds device management, MFA settings, session tracking, and comprehensive audit logging

-- Device Management Table
CREATE TABLE IF NOT EXISTS public.user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT,
  device_type TEXT CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'web')),
  platform TEXT,
  os_version TEXT,
  app_version TEXT,
  push_token TEXT,
  is_trusted BOOLEAN DEFAULT FALSE,
  biometric_enabled BOOLEAN DEFAULT FALSE,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, device_id)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own devices" ON public.user_devices
  FOR ALL USING (auth.uid() = user_id);

-- Multi-Factor Authentication Settings
CREATE TABLE IF NOT EXISTS public.user_mfa_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  mfa_enabled BOOLEAN DEFAULT FALSE,
  methods JSONB DEFAULT '{
    "sms": false,
    "email": false,
    "authenticator": false,
    "biometric": false,
    "hardware_token": false
  }'::JSONB,
  backup_codes TEXT[] DEFAULT '{}',
  recovery_email TEXT,
  recovery_phone TEXT,
  require_mfa_for_sensitive_ops BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_mfa_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own MFA settings" ON public.user_mfa_settings
  FOR ALL USING (auth.uid() = user_id);

-- Session Management Table
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT,
  session_token TEXT UNIQUE NOT NULL,
  refresh_token TEXT UNIQUE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  location JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  mfa_verified BOOLEAN DEFAULT FALSE,
  last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '8 hours'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own sessions" ON public.user_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Enhanced Audit Log Table for HIPAA Compliance
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  metadata JSONB DEFAULT '{}'::JSONB,
  ip_address INET,
  user_agent TEXT,
  device_id TEXT,
  session_id UUID,
  phi_accessed BOOLEAN DEFAULT FALSE,
  success BOOLEAN DEFAULT TRUE,
  error_message TEXT,
  checksum TEXT, -- SHA-256 hash for integrity verification
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs should never be deleted, only archived
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins view audit logs" ON public.audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role IN ('Admin', 'SuperAdmin')
    )
  );

-- Emergency Access Table
CREATE TABLE IF NOT EXISTS public.emergency_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  elder_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  caregiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  access_type TEXT CHECK (access_type IN ('view_only', 'full_access', 'medical_only')),
  reason TEXT NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES auth.users(id),
  revocation_reason TEXT,
  UNIQUE(elder_id, caregiver_id, granted_at)
);

ALTER TABLE public.emergency_access ENABLE ROW LEVEL SECURITY;

-- Both elder and caregiver can view emergency access records
CREATE POLICY "Participants view emergency access" ON public.emergency_access
  FOR SELECT USING (
    auth.uid() = elder_id OR auth.uid() = caregiver_id
  );

-- Only caregivers can request emergency access
CREATE POLICY "Caregivers request emergency access" ON public.emergency_access
  FOR INSERT WITH CHECK (
    auth.uid() = caregiver_id AND
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'Caregiver'
    )
  );

-- Password History Table (HIPAA requirement)
CREATE TABLE IF NOT EXISTS public.password_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.password_history ENABLE ROW LEVEL SECURITY;

-- No one can directly view password history (only through functions)
CREATE POLICY "No direct password history access" ON public.password_history
  FOR SELECT USING (FALSE);

-- Login Attempts Table for Security Monitoring
CREATE TABLE IF NOT EXISTS public.login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_address INET,
  user_agent TEXT,
  device_id TEXT,
  success BOOLEAN DEFAULT FALSE,
  failure_reason TEXT,
  mfa_required BOOLEAN DEFAULT FALSE,
  mfa_success BOOLEAN,
  suspicious_activity BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_login_attempts_email ON public.login_attempts(email, created_at DESC);
CREATE INDEX idx_login_attempts_ip ON public.login_attempts(ip_address, created_at DESC);

-- Security Incidents Table
CREATE TABLE IF NOT EXISTS public.security_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type TEXT CHECK (incident_type IN (
    'unauthorized_access', 'data_exfiltration', 'system_intrusion',
    'insider_threat', 'malware', 'phishing', 'account_compromise', 'other'
  )),
  severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  status TEXT CHECK (status IN ('detected', 'investigating', 'contained', 'resolved')),
  affected_users UUID[] DEFAULT '{}',
  description TEXT NOT NULL,
  detection_method TEXT,
  response_actions JSONB DEFAULT '[]'::JSONB,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  contained_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  reported_by UUID REFERENCES auth.users(id),
  assigned_to UUID REFERENCES auth.users(id)
);

ALTER TABLE public.security_incidents ENABLE ROW LEVEL SECURITY;

-- Only security officers can manage incidents
CREATE POLICY "Security officers manage incidents" ON public.security_incidents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role IN ('Admin', 'SuperAdmin')
    )
  );

-- User Consent Tracking Table
CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type TEXT CHECK (consent_type IN (
    'terms_of_service', 'privacy_policy', 'hipaa_authorization',
    'data_sharing', 'marketing_communications', 'research_participation'
  )),
  version TEXT NOT NULL,
  granted BOOLEAN DEFAULT FALSE,
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own consents" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users manage own consents" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to log authentication events
CREATE OR REPLACE FUNCTION public.log_auth_event(
  p_action TEXT,
  p_metadata JSONB DEFAULT '{}'::JSONB,
  p_phi_accessed BOOLEAN DEFAULT FALSE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_checksum TEXT;
  v_log_data TEXT;
BEGIN
  v_user_id := auth.uid();
  
  -- Create log entry data for checksum
  v_log_data := COALESCE(v_user_id::TEXT, 'anonymous') || '|' || 
                p_action || '|' || 
                p_metadata::TEXT || '|' || 
                NOW()::TEXT;
  
  -- Generate checksum for integrity
  v_checksum := encode(digest(v_log_data, 'sha256'), 'hex');
  
  -- Insert audit log
  INSERT INTO public.audit_logs (
    user_id, action, resource_type, metadata, 
    phi_accessed, checksum
  ) VALUES (
    v_user_id, p_action, 'authentication', p_metadata,
    p_phi_accessed, v_checksum
  );
END;
$$;

-- Function to check password history (prevents reuse of last 5 passwords)
CREATE OR REPLACE FUNCTION public.check_password_history(
  p_user_id UUID,
  p_new_password_hash TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT password_hash 
    FROM public.password_history
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 5
  ) recent_passwords
  WHERE password_hash = p_new_password_hash;
  
  RETURN v_count = 0;
END;
$$;

-- Function to handle emergency access requests
CREATE OR REPLACE FUNCTION public.request_emergency_access(
  p_elder_id UUID,
  p_reason TEXT,
  p_access_type TEXT DEFAULT 'view_only'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caregiver_id UUID;
  v_access_id UUID;
BEGIN
  v_caregiver_id := auth.uid();
  
  -- Verify caregiver role
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = v_caregiver_id 
    AND role = 'Caregiver'
  ) THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Only caregivers can request emergency access'
    );
  END IF;
  
  -- Check if they're in the same family
  IF NOT EXISTS (
    SELECT 1 FROM public.family_members fm1
    JOIN public.family_members fm2 ON fm1.family_id = fm2.family_id
    WHERE fm1.user_id = v_caregiver_id 
    AND fm2.user_id = p_elder_id
  ) THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Not authorized - not in same family'
    );
  END IF;
  
  -- Create emergency access record
  INSERT INTO public.emergency_access (
    elder_id, caregiver_id, access_type, reason
  ) VALUES (
    p_elder_id, v_caregiver_id, p_access_type, p_reason
  ) RETURNING id INTO v_access_id;
  
  -- Log the emergency access
  PERFORM public.log_auth_event(
    'emergency_access_granted',
    json_build_object(
      'elder_id', p_elder_id,
      'reason', p_reason,
      'access_type', p_access_type
    ),
    TRUE
  );
  
  RETURN json_build_object(
    'success', true,
    'access_id', v_access_id,
    'expires_at', NOW() + INTERVAL '24 hours'
  );
END;
$$;

-- Function to validate device and create session
CREATE OR REPLACE FUNCTION public.create_user_session(
  p_device_id TEXT,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session_id UUID;
  v_session_token TEXT;
  v_refresh_token TEXT;
  v_device_trusted BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Check if device is trusted
  SELECT is_trusted INTO v_device_trusted
  FROM public.user_devices
  WHERE user_id = v_user_id AND device_id = p_device_id;
  
  IF NOT FOUND THEN
    -- Register new device
    INSERT INTO public.user_devices (user_id, device_id, last_used_at)
    VALUES (v_user_id, p_device_id, NOW());
    v_device_trusted := FALSE;
  ELSE
    -- Update last used
    UPDATE public.user_devices
    SET last_used_at = NOW()
    WHERE user_id = v_user_id AND device_id = p_device_id;
  END IF;
  
  -- Generate tokens
  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_refresh_token := encode(gen_random_bytes(32), 'hex');
  
  -- Create session
  INSERT INTO public.user_sessions (
    user_id, device_id, session_token, refresh_token,
    ip_address, user_agent
  ) VALUES (
    v_user_id, p_device_id, v_session_token, v_refresh_token,
    p_ip_address, p_user_agent
  ) RETURNING id INTO v_session_id;
  
  RETURN json_build_object(
    'success', true,
    'session_id', v_session_id,
    'session_token', v_session_token,
    'refresh_token', v_refresh_token,
    'device_trusted', v_device_trusted
  );
END;
$$;

-- Trigger to clean up old sessions
CREATE OR REPLACE FUNCTION public.cleanup_expired_sessions()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.user_sessions
  SET is_active = FALSE
  WHERE expires_at < NOW() AND is_active = TRUE;
  
  -- Delete very old inactive sessions (>30 days)
  DELETE FROM public.user_sessions
  WHERE is_active = FALSE 
  AND expires_at < NOW() - INTERVAL '30 days';
END;
$$;

-- Create indexes for performance
CREATE INDEX idx_user_devices_user_device ON public.user_devices(user_id, device_id);
CREATE INDEX idx_user_sessions_user_active ON public.user_sessions(user_id, is_active);
CREATE INDEX idx_user_sessions_token ON public.user_sessions(session_token) WHERE is_active = TRUE;
CREATE INDEX idx_audit_logs_user_created ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action, created_at DESC);
CREATE INDEX idx_emergency_access_active ON public.emergency_access(elder_id, caregiver_id) 
  WHERE revoked_at IS NULL AND expires_at > NOW();

-- Trigger for updating updated_at columns
CREATE TRIGGER update_user_mfa_settings_updated_at
  BEFORE UPDATE ON public.user_mfa_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Add comment for documentation
COMMENT ON TABLE public.user_devices IS 'Tracks user devices for trusted device management and biometric authentication';
COMMENT ON TABLE public.user_mfa_settings IS 'Multi-factor authentication configuration for enhanced security';
COMMENT ON TABLE public.user_sessions IS 'Active user sessions with timeout and activity tracking';
COMMENT ON TABLE public.audit_logs IS 'HIPAA-compliant audit trail for all system activities';
COMMENT ON TABLE public.emergency_access IS 'Temporary emergency access grants for caregivers';
COMMENT ON TABLE public.security_incidents IS 'Security incident tracking and response management';
COMMENT ON TABLE public.user_consents IS 'Legal consent tracking for HIPAA and privacy compliance';