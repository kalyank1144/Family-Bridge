-- Replace placeholders with real auth.users IDs
\set elder_id 00000000-0000-0000-0000-000000000001
\set caregiver_id 00000000-0000-0000-0000-000000000002
\set youth_id 00000000-0000-0000-0000-000000000003
\set admin_id 00000000-0000-0000-0000-000000000004

-- Profiles (assumes auth.users already has these ids)
insert into profiles(id, email, user_type, role, phone, full_name)
values
  (:'elder_id', 'elder@example.com', 'elder', 'elder', '555-0101', 'Mary Johnson')
, (:'caregiver_id', 'care@example.com', 'caregiver', 'caregiver', '555-0202', 'Nurse Alex')
, (:'youth_id', 'youth@example.com', 'youth', 'youth', '555-0303', 'Sam Young')
, (:'admin_id', 'admin@example.com', 'admin', 'admin', '555-0404', 'Admin User')
on conflict (id) do update set email = excluded.email;

-- Caregiver assignment
insert into caregiver_patients(caregiver_id, elder_id)
values (:'caregiver_id', :'elder_id')
on conflict do nothing;

-- Channel memberships
insert into message_memberships(channel_id, user_id) values
  ('family', :'elder_id'),
  ('family', :'caregiver_id'),
  ('care_team', :'caregiver_id'),
  ('youth', :'youth_id')
on conflict do nothing;

-- Medications
insert into medications(user_id, name, dosage, schedule) values
  (:'elder_id', 'Atenolol', '50mg', '08:00'),
  (:'elder_id', 'Metformin', '500mg', '12:00');

-- Appointments
insert into appointments(user_id, title, time, location) values
  (:'elder_id', 'General Checkup', now() + interval '1 day', 'Clinic A'),
  (:'elder_id', 'Cardiology', now() + interval '3 days', 'Hospital B');

-- Health data samples (for charts)
insert into health_data(user_id, heart_rate, systolic, diastolic, medication_taken, mood, pain, created_at)
select :'elder_id', 68 + (i%8), 118 + (i%5), 78 + (i%3), (i%2)=0, 'Good', false, now() - (i||' days')::interval
from generate_series(0,6) s(i);

-- Youth tasks
insert into tasks(user_id, title, done) values
  (:'youth_id', 'Drink water', false),
  (:'youth_id', '10 min exercise', true),
  (:'youth_id', 'Read a story', false);
