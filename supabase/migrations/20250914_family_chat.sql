-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Profiles table referencing auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  avatar_url TEXT,
  user_type TEXT CHECK (user_type IN (elder,caregiver,youth)),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Families
CREATE TABLE IF NOT EXISTS public.families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Family members
CREATE TABLE IF NOT EXISTS public.family_members (
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN (elder,caregiver,youth,admin)),
  added_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (family_id, user_id)
);

-- Messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  sender_name TEXT NOT NULL,
  sender_type TEXT NOT NULL CHECK (sender_type IN (elder,caregiver,youth)),
  content TEXT,
  type TEXT NOT NULL CHECK (type IN (text,voice,image,video,location,careNote,announcement,achievement)),
  status TEXT NOT NULL DEFAULT sent CHECK (status IN (sending,sent,delivered,read,failed)),
  priority TEXT NOT NULL DEFAULT normal CHECK (priority IN (normal,important,urgent,emergency)),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at TIMESTAMPTZ,
  read_by TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  reactions JSONB NOT NULL DEFAULT []::JSONB,
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
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY IF NOT EXISTS "profiles_select_all"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY IF NOT EXISTS "profiles_insert_self"
  ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY IF NOT EXISTS "profiles_update_self"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Families policies
CREATE POLICY IF NOT EXISTS "families_select_member_or_creator"
  ON public.families FOR SELECT
  USING (
    EXISTS(SELECT 1 FROM public.family_members fm WHERE fm.family_id = id AND fm.user_id = auth.uid())
    OR created_by = auth.uid()
  );

CREATE POLICY IF NOT EXISTS "families_insert_creator_only"
  ON public.families FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY IF NOT EXISTS "families_update_creator_only"
  ON public.families FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Family members policies
CREATE POLICY IF NOT EXISTS "family_members_select_member"
  ON public.family_members FOR SELECT
  USING (
    EXISTS(SELECT 1 FROM public.family_members fm WHERE fm.family_id = family_id AND fm.user_id = auth.uid())
  );

CREATE POLICY IF NOT EXISTS "family_members_insert_added_by"
  ON public.family_members FOR INSERT
  WITH CHECK (added_by = auth.uid());

CREATE POLICY IF NOT EXISTS "family_members_update_creator_or_self"
  ON public.family_members FOR UPDATE
  USING (added_by = auth.uid() OR user_id = auth.uid())
  WITH CHECK (added_by = auth.uid() OR user_id = auth.uid());

CREATE POLICY IF NOT EXISTS "family_members_delete_creator"
  ON public.family_members FOR DELETE
  USING (added_by = auth.uid());

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
DECLARE v_family UUID; v_read_by TEXT[];
BEGIN
  SELECT family_id, read_by INTO v_family, v_read_by
  FROM public.messages WHERE id = p_message_id;
  IF v_family IS NULL THEN RAISE EXCEPTION message not found; END IF;
  IF NOT public.is_family_member(v_family) THEN RAISE EXCEPTION not a family member; END IF;

  UPDATE public.messages
  SET read_by = (
    SELECT ARRAY_AGG(DISTINCT e)
    FROM UNNEST(COALESCE(v_read_by, {}::TEXT[]) || COALESCE(auth.uid()::TEXT, anon)) AS e
  )
  WHERE id = p_message_id;
END; $$;

-- RPC: add/replace reaction by current user
CREATE OR REPLACE FUNCTION public.add_message_reaction(p_message_id UUID, p_emoji TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_family UUID; v_reactions JSONB;
BEGIN
  SELECT family_id, reactions INTO v_family, v_reactions
  FROM public.messages WHERE id = p_message_id;
  IF v_family IS NULL THEN RAISE EXCEPTION message not found; END IF;
  IF NOT public.is_family_member(v_family) THEN RAISE EXCEPTION not a family member; END IF;

  v_reactions := COALESCE(v_reactions, []::JSONB);
  v_reactions := (
    SELECT COALESCE(jsonb_agg(elem), []::JSONB)
    FROM jsonb_array_elements(v_reactions) elem
    WHERE (elem->>user_id)::UUID IS DISTINCT FROM auth.uid()
  );

  UPDATE public.messages
  SET reactions = v_reactions || jsonb_build_array(
      jsonb_build_object(
        user_id, auth.uid(),
        emoji, p_emoji,
        timestamp, now()
      )
    )
  WHERE id = p_message_id;
END; $$;

GRANT EXECUTE ON FUNCTION public.mark_message_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_message_reaction(UUID, TEXT) TO authenticated;

-- Storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES
  (chat_images,chat_images, FALSE),
  (chat_videos,chat_videos, FALSE),
  (voice_messages,voice_messages, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for chat media
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = storage AND tablename = objects AND policyname = allow_read_chat_media
  ) THEN
    CREATE POLICY allow_read_chat_media
      ON storage.objects FOR SELECT
      USING (bucket_id IN (chat_images,chat_videos,voice_messages));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = storage AND tablename = objects AND policyname = allow_insert_chat_media_owner
  ) THEN
    CREATE POLICY allow_insert_chat_media_owner
      ON storage.objects FOR INSERT
      WITH CHECK (bucket_id IN (chat_images,chat_videos,voice_messages) AND (owner = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = storage AND tablename = objects AND policyname = allow_update_chat_media_owner
  ) THEN
    CREATE POLICY allow_update_chat_media_owner
      ON storage.objects FOR UPDATE
      USING (bucket_id IN (chat_images,chat_videos,voice_messages) AND (owner = auth.uid()))
      WITH CHECK (bucket_id IN (chat_images,chat_videos,voice_messages) AND (owner = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = storage AND tablename = objects AND policyname = allow_delete_chat_media_owner
  ) THEN
    CREATE POLICY allow_delete_chat_media_owner
      ON storage.objects FOR DELETE
      USING (bucket_id IN (chat_images,chat_videos,voice_messages) AND (owner = auth.uid()));
  END IF;
END $$;

-- Note: Supabase Realtime streams from WAL; no custom triggers required for realtime events.
