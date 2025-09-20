-- Add multimedia fields to existing tables
ALTER TABLE IF EXISTS daily_checkins ADD COLUMN IF NOT EXISTS voice_note_url TEXT;
ALTER TABLE IF EXISTS medication_logs ADD COLUMN IF NOT EXISTS confirmation_photo_url TEXT;
ALTER TABLE IF EXISTS emergency_events ADD COLUMN IF NOT EXISTS emergency_photo_url TEXT;
