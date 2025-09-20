# Supabase Setup for FamilyBridge

This guide wires the app to your Supabase project and creates all required tables, policies, and storage buckets.

## 1) Create a Supabase Project
- Go to https://supabase.com/ and create a new project
- Copy the Project URL and anon public key from Project Settings → API

## 2) Configure Environment
1. Copy `.env.example` to `.env` and fill values:
```
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_PUBLIC_KEY
```
2. Local run options:
- Using flutter_dotenv (dev): just keep `.env` in project root
- Using dart-define (recommended for CI/builds):
```
flutter run --dart-define-from-file=.env
```

## 3) Create Database Schema
Apply the SQL files in this order via Supabase → SQL Editor:
1. `supabase/schema.sql`
2. `supabase/migrations/20250919_auth_system.sql`
3. `supabase/migrations/20250914_family_chat.sql`
4. `supabase/migrations/20250919_multimedia.sql`

This will create:
- users (profile) – linked to auth.users
- emergency_contacts, medications, medication_logs, daily_checkins
- auth system: user_profiles, family_groups, family_members, family_invites, family_members_view
- chat: messages table, RPCs, triggers, storage buckets for chat media
- storage buckets for `medication-photos` and `voice-notes` with safe policies

Row Level Security is enabled with sensible policies: users can only access their own rows; messages are readable by sender or recipient.

## 4) Initialize Auth Profiles
When a user signs in the first time, insert a corresponding row in `public.users` with their `auth.uid()` and name/role. For development, you can manually insert a row in `public.users` using your user id.

Example:
```sql
insert into public.users (id, name, role)
values ('<your-auth-uid>', 'Elder Demo', 'elder')
on conflict (id) do nothing;
```

## 5) App Wiring
- The app loads environment from `.env` (and supports `--dart-define`) via `flutter_dotenv`.
- Supabase initialization occurs in `lib/main.dart` using values from `lib/core/utils/env.dart`.
- Environment validation runs via `EnvConfig` during startup to ensure required keys are set.
- All Elder data operations use Supabase in `lib/features/elder/providers/elder_provider.dart`.
- Realtime updates are subscribed via `SupabaseRealtime` channels for messages and medications.

## 6) Storage (optional)
Use buckets:
- `medication-photos` – store medication confirmation images
- `voice-notes` – store check-in voice notes

Upload with Supabase Storage API and save file URLs in respective tables.

## 6) Auth Providers
- Enable Email/Password in Project Settings → Authentication
- (Optional) Enable Google and Apple providers
  - Set Redirect URLs:
    - Web: https://your-domain/auth/v1/callback
    - Android: com.your.bundle.id://login-callback
    - iOS: com.your.bundle.id://login-callback

## 7) Running the app
```
flutter pub get
flutter run --dart-define-from-file=.env
```

## 8) Seed Development Data
If you already have test users in `auth.users`, run:
```
-- Replace placeholders first
supabase/schema editor → paste supabase/seeds/dev_seed.sql
```

## 8) Troubleshooting
- If you see RLS errors (permission denied), confirm the `users` table has a row for the logged-in user and your policies from `schema.sql` are applied.
- Ensure Realtime is enabled for the `public` schema. In your Realtime config, enable `messages` and `medications` tables.
- If voice features fail, verify microphone permissions and test on a physical device.

---
This setup provides a secure baseline for Elder features. You can extend policies to allow caregiver accounts to read their assigned elder’s data in future PRs.
