-- RLS Test Matrix for FamilyBridge
-- Usage: In Supabase SQL editor, set request.jwt.claims to impersonate users
-- Replace the UUIDs below with real auth.users IDs after creating users

-- Helper: impersonate function
create or replace function test_impersonate(uid uuid, role text default 'authenticated') returns void as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid::text, 'role', role)::text, true);
end;$$ language plpgsql;

-- Test users (replace with actual IDs)
-- elder: 00000000-0000-0000-0000-000000000001
-- caregiver: 00000000-0000-0000-0000-000000000002
-- youth: 00000000-0000-0000-0000-000000000003
-- admin: 00000000-0000-0000-0000-000000000004

-- Profiles visibility
select test_impersonate('00000000-0000-0000-0000-000000000001'); -- elder
select * from profiles; -- expect only own row

select test_impersonate('00000000-0000-0000-0000-000000000002'); -- caregiver
select * from profiles; -- expect only assigned elders + own row

select test_impersonate('00000000-0000-0000-0000-000000000004'); -- admin
select * from profiles; -- expect all

-- Health data owner access
select test_impersonate('00000000-0000-0000-0000-000000000001'); -- elder
select count(*) from health_data where user_id = '00000000-0000-0000-0000-000000000001'; -- ok
select count(*) from health_data where user_id <> '00000000-0000-0000-0000-000000000001'; -- 0

-- Caregiver access to assigned elder health
select test_impersonate('00000000-0000-0000-0000-000000000002');
select count(*) from health_data where user_id = '00000000-0000-0000-0000-000000000001'; -- ok if caregiver_patients link exists

-- Medications owner access
select test_impersonate('00000000-0000-0000-0000-000000000001');
insert into medications(user_id, name, dosage, schedule) values ('00000000-0000-0000-0000-000000000001', 'TestMed', '10mg', '08:00'); -- ok
update medications set taken = true where user_id = '00000000-0000-0000-0000-000000000001'; -- ok

-- Medications denied cross-user
select test_impersonate('00000000-0000-0000-0000-000000000003'); -- youth
update medications set taken = false where user_id = '00000000-0000-0000-0000-000000000001'; -- should fail

-- Appointments owner
select test_impersonate('00000000-0000-0000-0000-000000000001');
insert into appointments(user_id, title, time, location) values ('00000000-0000-0000-0000-000000000001', 'Checkup', now() + interval '1 day', 'Clinic'); -- ok

-- Messages: only channel members
select test_impersonate('00000000-0000-0000-0000-000000000001'); -- elder
insert into messages(channel_id, sender_id, content) values ('family', '00000000-0000-0000-0000-000000000001', 'hi'); -- ok if membership exists

select test_impersonate('00000000-0000-0000-0000-000000000003'); -- youth
select * from messages where channel_id = 'care_team'; -- should be empty if not a member

-- Tasks: owner only
select test_impersonate('00000000-0000-0000-0000-000000000003');
insert into tasks(user_id, title) values ('00000000-0000-0000-0000-000000000003', 'Read a story'); -- ok
update tasks set done = true where user_id = '00000000-0000-0000-0000-000000000003'; -- ok

-- Audit logs: admin only
select test_impersonate('00000000-0000-0000-0000-000000000001');
select * from audit_logs limit 1; -- should fail/return none

select test_impersonate('00000000-0000-0000-0000-000000000004');
select * from audit_logs limit 1; -- ok

-- Reset impersonation
select set_config('request.jwt.claims', null, true);