# Supabase Setup for Family Chat

This folder contains SQL migrations to provision the database schema, row-level security (RLS) policies, RPCs, and storage buckets for the Family Chat system.

## Apply Migrations
1. Open the Supabase SQL editor for your project.
2. Copy the contents of `supabase/migrations/20250914_family_chat.sql`.
3. Run the script. It is idempotent (uses IF NOT EXISTS) and safe to re-run.

## What this migration creates
- `profiles`, `families`, `family_members`, and `messages` tables
- Helper function: `public.is_family_member(family_id)`
- RLS policies across all tables
- RPCs:
  - `public.mark_message_read(message_id uuid)`
  - `public.add_message_reaction(message_id uuid, emoji text)`
- Storage buckets (private): `chat_images`, `chat_videos`, `voice_messages`
- Storage policies for read/insert/update/delete by object owner

## Notes
- Realtime is enabled automatically via WAL—no triggers required.
- The app uses signed URLs for media; buckets are private by default. If you prefer public URLs, set the bucket to public and adjust policies.
- Messages are soft-deleted (no `DELETE` policy). Edits set `is_edited` and `edited_at` automatically via trigger.

## Next steps
- Configure RLS on any additional tables you add (e.g., tasks derived from messages).
- Replace placeholder app keys in `lib/main.dart` with your Supabase project URL and anon key.
