-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Messages schema for Family Chat
-- Depends on: public.family_groups, public.family_members (from auth_system migration)

-- Messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  sender_name TEXT NOT NULL,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('elder','caregiver','youth')),
  content TEXT,
  type TEXT NOT NULL CHECK (type IN ('text','voice','image','video','location','careNote','announcement','achievement')),
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sending','sent','delivered','read','failed')),
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal','important','urgent','emergency')),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at TIMESTAMPTZ,
  read_by TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  reactions JSONB NOT NULL DEFAULT '[]'::JSONB,
  metadata JSONB,
  reply_to_id UUID NULL REFERENCES public.messages(id) ON DELETE SET NULL,
  voice_transcription TEXT,
  voice_duration INTEGER,
  media_url TEXT,
  media_thumbnail TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_name TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  thread_id UUID NULL,
  mentions TEXT[]
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_messages_family_time ON public.messages (family_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_thread ON public.messages (thread_id);
CREATE INDEX IF NOT EXISTS idx_messages_reactions ON public.messages USING GIN (reactions);
CREATE INDEX IF NOT EXISTS idx_messages_mentions ON public.messages USING GIN (mentions);

-- Helper: is family member
CREATE OR REPLACE FUNCTION public.is_family_member(family UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.family_members fm
    WHERE fm.family_id = family
      AND fm.user_id = auth.uid()
  );
$$;

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Messages policies
CREATE POLICY IF NOT EXISTS "messages_select_family_member"
  ON public.messages FOR SELECT
  USING (public.is_family_member(family_id));

CREATE POLICY IF NOT EXISTS "messages_insert_sender_in_family"
  ON public.messages FOR INSERT
  WITH CHECK (public.is_family_member(family_id) AND sender_id = auth.uid());

CREATE POLICY IF NOT EXISTS "messages_update_sender_only"
  ON public.messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

-- No hard deletes
CREATE POLICY IF NOT EXISTS "messages_delete_disabled" ON public.messages
  FOR DELETE USING (false);

-- Trigger: set edited_at when content changes
CREATE OR REPLACE FUNCTION public.set_message_edit_timestamps()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.content IS DISTINCT FROM OLD.content) THEN
    NEW.is_edited := TRUE;
    NEW.edited_at := now();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_set_edit ON public.messages;
CREATE TRIGGER trg_messages_set_edit
BEFORE UPDATE ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.set_message_edit_timestamps();

-- RPC: mark as read (appends auth.uid())
CREATE OR REPLACE FUNCTION public.mark_message_read(p_message_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE 
  v_family UUID; 
  v_read_by TEXT[];
BEGIN
  SELECT family_id, read_by INTO v_family, v_read_by
  FROM public.messages WHERE id = p_message_id;
  IF v_family IS NULL THEN RAISE EXCEPTION 'message not found'; END IF;
  IF NOT public.is_family_member(v_family) THEN RAISE EXCEPTION 'not a family member'; END IF;

  UPDATE public.messages
  SET read_by = (
    SELECT ARRAY(SELECT DISTINCT e FROM UNNEST(COALESCE(v_read_by, ARRAY[]::TEXT[]) || auth.uid()::TEXT) AS e)
  )
  WHERE id = p_message_id;
END; $$;

-- RPC: add/replace reaction by current user
CREATE OR REPLACE FUNCTION public.add_message_reaction(p_message_id UUID, p_emoji TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE 
  v_family UUID; 
  v_reactions JSONB;
BEGIN
  SELECT family_id, reactions INTO v_family, v_reactions
  FROM public.messages WHERE id = p_message_id;
  IF v_family IS NULL THEN RAISE EXCEPTION 'message not found'; END IF;
  IF NOT public.is_family_member(v_family) THEN RAISE EXCEPTION 'not a family member'; END IF;

  v_reactions := COALESCE(v_reactions, '[]'::JSONB);
  v_reactions := (
    SELECT COALESCE(jsonb_agg(elem), '[]'::JSONB)
    FROM jsonb_array_elements(v_reactions) elem
    WHERE (elem->>'user_id') IS DISTINCT FROM auth.uid()::TEXT
  );

  UPDATE public.messages
  SET reactions = v_reactions || jsonb_build_array(
      jsonb_build_object(
        'user_id', auth.uid()::TEXT,
        'emoji', p_emoji,
        'timestamp', now()
      )
    )
  WHERE id = p_message_id;
END; $$;

GRANT EXECUTE ON FUNCTION public.mark_message_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_message_reaction(UUID, TEXT) TO authenticated;

-- Storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('chat_images','chat_images', FALSE),
  ('chat_videos','chat_videos', FALSE),
  ('voice_messages','voice_messages', FALSE)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for chat media
DROP POLICY IF EXISTS allow_read_chat_media ON storage.objects;
CREATE POLICY allow_read_chat_media
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('chat_images','chat_videos','voice_messages'));

DROP POLICY IF EXISTS allow_insert_chat_media_owner ON storage.objects;
CREATE POLICY allow_insert_chat_media_owner
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('chat_images','chat_videos','voice_messages') AND (owner = auth.uid()));

DROP POLICY IF EXISTS allow_update_chat_media_owner ON storage.objects;
CREATE POLICY allow_update_chat_media_owner
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id IN ('chat_images','chat_videos','voice_messages') AND (owner = auth.uid()))
  WITH CHECK (bucket_id IN ('chat_images','chat_videos','voice_messages') AND (owner = auth.uid()));

DROP POLICY IF EXISTS allow_delete_chat_media_owner ON storage.objects;
CREATE POLICY allow_delete_chat_media_owner
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id IN ('chat_images','chat_videos','voice_messages') AND (owner = auth.uid()));

-- Note: Supabase Realtime streams from WAL; no custom triggers required for realtime events.
