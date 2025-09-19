# Seeding FamilyBridge (Supabase)

## Prerequisites
- Supabase project set up
- Four auth users created (elder, caregiver, youth, admin)
- Capture their UUIDs from the Supabase Auth Users page

## Steps
1) Apply migrations
- Run migrations in this order via SQL editor:
  - migrations/2025-09-15_hipaa_schema.sql
  - migrations/2025-09-19_caregiver_rls_and_realtime.sql

2) Prepare seed file
- Open seed/seed.template.sql
- Replace placeholder UUIDs at the top with your real user IDs
- Save as seed/seed.sql

3) Execute seed
- Run the contents of seed/seed.sql in the Supabase SQL editor

4) Verify data
- profiles should contain 4 records
- caregiver_patients should link caregiver -> elder
- message_memberships should include family, care_team, youth
- medications, appointments, health_data, tasks should be populated

5) Test RLS
- Open tests/rls_test_matrix.sql
- Replace UUIDs
- Run the file to validate policies using test_impersonate()

## Notes
- auth.users cannot be inserted directly via SQL; create users via Auth UI or CLI
- After seeding, log in as each role in the app to verify realtime + offline caching
- You can add more memberships and assignments to broaden visibility
