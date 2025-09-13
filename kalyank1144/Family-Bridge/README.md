# FamilyBridge (Flutter + Supabase)

This repository contains the Flutter application scaffold for FamilyBridge with Supabase integration, feature-based architecture, role-based routing, theming, and offline-first primitives.

## Project layout

```
lib/
  core/            # constants, providers, themes
  features/        # auth, elder, caregiver, youth
  services/        # supabase, local storage, offline sync, notifications
  shared/          # shared widgets
supabase/sql/      # database schema, RLS policies, realtime config
docs/              # wireframes & specifications
```

Wireframes: `docs/wireframes/`
Specs: `docs/specs/`

## Prerequisites
- Flutter SDK 3.22+
- A Supabase project (URL + anon key)

## Environment variables
Pass the following at run time via `--dart-define`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Example:

```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

## Installing packages
```
flutter pub get
```

## Database setup
Apply the SQL files in Supabase SQL editor (or CLI):

1. `supabase/sql/01_schema.sql`
2. `supabase/sql/02_policies.sql`
3. `supabase/sql/03_realtime.sql`

These create the `users`, `families`, `family_members`, `health_data`, `medications`, `medication_logs`, `messages`, `emergency_contacts`, `appointments`, `daily_checkins`, `care_points`, and `stories` tables with RLS and realtime enabled.

## Authentication
- Email/password for caregivers & youth
- Phone OTP for elders

The `LoginPage` demonstrates both flows.

## Offline-first
- Hive is initialized in `main.dart`
- A simple sync queue is provided in `services/offline_sync.dart`

You can enqueue writes when offline; call `SyncService.processQueue()` when connectivity is restored.

## Routing & theming
- Role-based routing with GoRouter in `features/navigation/router.dart`
- Dynamic theming based on user type in `core/theme/*`

## Notifications & Deep Links
- Local notifications scaffold in `services/notifications.dart`
- A deep link route exists at `/notification/:type`

## Next steps
- Connect UI to the database tables according to specs
- Implement realtime listeners for family-scoped data
- Flesh out feature screens per wireframes
- Add unit and widget tests
