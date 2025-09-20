-- Development seed data for FamilyBridge
-- Replace the placeholder UUIDs with real auth.users IDs before running

-- Base users (profile rows)
INSERT INTO public.users (id, name, role)
VALUES 
  ('{{PRIMARY_CAREGIVER_USER_ID}}', 'Caregiver Demo', 'caregiver'),
  ('{{ELDER_USER_ID}}', 'Elder Demo', 'elder'),
  ('{{YOUTH_USER_ID}}', 'Youth Demo', 'youth')
ON CONFLICT (id) DO NOTHING;

-- Family group
INSERT INTO public.family_groups (id, name, created_by)
VALUES ('{{FAMILY_ID}}', 'Demo Family', '{{PRIMARY_CAREGIVER_USER_ID}}')
ON CONFLICT (id) DO NOTHING;

-- Family members
INSERT INTO public.family_members (family_id, user_id, role, permissions)
VALUES 
  ('{{FAMILY_ID}}', '{{PRIMARY_CAREGIVER_USER_ID}}', 'primary-caregiver', 'owner'),
  ('{{FAMILY_ID}}', '{{ELDER_USER_ID}}', 'elder', 'member'),
  ('{{FAMILY_ID}}', '{{YOUTH_USER_ID}}', 'youth', 'member')
ON CONFLICT (family_id, user_id) DO NOTHING;

-- Example chat message
INSERT INTO public.messages (
  id, family_id, sender_id, sender_name, sender_type, content, type, status, priority
) VALUES (
  gen_random_uuid(), '{{FAMILY_ID}}', '{{PRIMARY_CAREGIVER_USER_ID}}', 'Caregiver Demo', 'caregiver',
  'Welcome to FamilyBridge! 🎉', 'text', 'sent', 'normal'
);
