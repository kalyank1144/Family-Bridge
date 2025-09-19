Apply migrations using Supabase SQL editor or CLI.

1. Open Supabase SQL editor and run migrations in order.
2. Ensure Realtime is enabled for tables.
3. Verify RLS policies.

After applying:
- Insert message_memberships per channel for each user who should access it
- Add caregiver_patients rows to grant caregivers access
- Insert initial medications, appointments, tasks
