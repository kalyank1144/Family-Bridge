create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  user_type text check (user_type in ('elder','caregiver','youth','admin')) not null default 'elder',
  role text not null default 'elder',
  phone text,
  created_at timestamp with time zone default now()
);

create table if not exists health_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  heart_rate numeric,
  systolic numeric,
  diastolic numeric,
  medication_taken boolean,
  mood text,
  pain boolean,
  created_at timestamp with time zone default now()
);

create table if not exists medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  dosage text,
  schedule text,
  taken boolean default false,
  created_at timestamp with time zone default now()
);

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  time timestamp with time zone not null,
  location text,
  created_at timestamp with time zone default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  channel_id text not null,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamp with time zone default now()
);

create table if not exists message_memberships (
  channel_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key(channel_id, user_id)
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  done boolean default false,
  created_at timestamp with time zone default now()
);

create table if not exists caregiver_patients (
  caregiver_id uuid not null references auth.users(id) on delete cascade,
  elder_id uuid not null references auth.users(id) on delete cascade,
  primary key(caregiver_id, elder_id)
);

create table if not exists consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data_type text not null,
  purpose text not null,
  granted boolean not null,
  timestamp timestamp with time zone not null default now(),
  ip_address text,
  consent_version text not null,
  expires_at timestamp with time zone,
  active boolean default true,
  revoked_at timestamp with time zone
);

create table if not exists audit_logs (
  id text primary key,
  timestamp timestamp with time zone not null,
  category text not null,
  user_id text not null,
  event text not null,
  severity text not null,
  ip_address text,
  device_id text,
  details jsonb,
  checksum text not null
);

create table if not exists compliance_reports (
  report_id text primary key,
  generated_at timestamp with time zone not null,
  overall_score numeric,
  encrypted_data text not null
);

create table if not exists incident_reports (
  id text primary key,
  payload jsonb not null,
  created_at timestamp with time zone default now()
);

alter publication supabase_realtime add table health_data, medications, appointments, messages, tasks;

alter table profiles enable row level security;
alter table health_data enable row level security;
alter table medications enable row level security;
alter table appointments enable row level security;
alter table messages enable row level security;
alter table message_memberships enable row level security;
alter table tasks enable row level security;
alter table consents enable row level security;
alter table audit_logs enable row level security;

create policy profiles_self on profiles for select using (auth.uid() = id);

create policy health_owner_select on health_data for select using (auth.uid() = user_id);
create policy health_owner_ins on health_data for insert with check (auth.uid() = user_id);

create policy health_caregiver_select on health_data for select using (
  exists(
    select 1 from caregiver_patients cp
    where cp.caregiver_id = auth.uid() and cp.elder_id = health_data.user_id
  )
);

create policy meds_owner_all on medications for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy meds_caregiver_select on medications for select using (
  exists(
    select 1 from caregiver_patients cp
    where cp.caregiver_id = auth.uid() and cp.elder_id = medications.user_id
  )
);

create policy appt_owner_all on appointments for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy appt_caregiver_select on appointments for select using (
  exists(
    select 1 from caregiver_patients cp
    where cp.caregiver_id = auth.uid() and cp.elder_id = appointments.user_id
  )
);

create policy msg_member_select on messages for select using (
  exists (
    select 1 from message_memberships mm
    where mm.channel_id = messages.channel_id and mm.user_id = auth.uid()
  )
);
create policy msg_member_insert on messages for insert with check (
  exists (
    select 1 from message_memberships mm
    where mm.channel_id = messages.channel_id and mm.user_id = auth.uid()
  )
);

create policy membership_self on message_memberships for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy tasks_owner_all on tasks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy consents_owner_all on consents for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy audit_read_admin on audit_logs for select using (
  exists(select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);

create or replace function log_phi_change() returns trigger as $$
begin
  insert into audit_logs(id, timestamp, category, user_id, event, severity, details, checksum)
  values (
    concat(extract(epoch from now())::text, '_', gen_random_uuid()::text),
    now(),
    'PHI_MODIFICATION',
    coalesce(new.user_id::text, old.user_id::text, 'unknown'),
    tg_table_name || ':' || tg_op,
    case when tg_op in ('DELETE','UPDATE') then 'WARNING' else 'INFO' end,
    jsonb_build_object('table', tg_table_name, 'op', tg_op, 'new', to_jsonb(new), 'old', to_jsonb(old)),
    encode(digest(coalesce(row_to_json(new)::text, row_to_json(old)::text), 'sha256'), 'hex')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists tr_health_log on health_data;
create trigger tr_health_log after insert or update or delete on health_data
for each row execute procedure log_phi_change();

drop trigger if exists tr_meds_log on medications;
create trigger tr_meds_log after insert or update or delete on medications
for each row execute procedure log_phi_change();

drop trigger if exists tr_appt_log on appointments;
create trigger tr_appt_log after insert or update or delete on appointments
for each row execute procedure log_phi_change();

insert into message_memberships(channel_id, user_id)
select 'family', id from auth.users on conflict do nothing;
insert into message_memberships(channel_id, user_id)
select 'care_team', id from auth.users on conflict do nothing;
insert into message_memberships(channel_id, user_id)
select 'youth', id from auth.users on conflict do nothing;