create type user_type as enum ('elder', 'caregiver', 'youth');

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  phone text,
  user_type user_type not null,
  created_at timestamptz default now()
);

create table if not exists families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  owner_id uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role user_type not null,
  relation text,
  permissions jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (family_id, user_id)
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  title text not null,
  description text,
  scheduled_at timestamptz not null,
  created_by uuid not null references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  name text not null,
  phone text not null,
  relation text,
  created_at timestamptz default now()
);

create table if not exists medications (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  elder_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  dosage text,
  schedule jsonb,
  created_at timestamptz default now()
);

create table if not exists medication_logs (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references medications(id) on delete cascade,
  taken_at timestamptz not null default now(),
  taken_by uuid references auth.users(id),
  status text check (status in ('taken','missed','skipped')) not null default 'taken'
);

create table if not exists health_data (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  value jsonb not null,
  recorded_at timestamptz not null default now()
);

create table if not exists daily_checkins (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  elder_id uuid not null references auth.users(id) on delete cascade,
  mood text,
  note text,
  created_at timestamptz default now()
);

create table if not exists care_points (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  points int not null default 0,
  reason text,
  created_at timestamptz default now()
);

create table if not exists stories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete set null,
  title text not null,
  content text,
  media jsonb,
  created_at timestamptz default now()
);

create table if not exists trusted_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  device_name text,
  created_at timestamptz default now(),
  unique (user_id, device_id)
);

create table if not exists user_approvals (
  id uuid primary key default gen_random_uuid(),
  youth_id uuid not null references auth.users(id) on delete cascade,
  guardian_email text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  token text unique,
  created_at timestamptz default now()
);

alter table profiles enable row level security;
alter table families enable row level security;
alter table family_members enable row level security;
alter table messages enable row level security;
alter table appointments enable row level security;
alter table emergency_contacts enable row level security;
alter table medications enable row level security;
alter table medication_logs enable row level security;
alter table health_data enable row level security;
alter table daily_checkins enable row level security;
alter table care_points enable row level security;
alter table stories enable row level security;
alter table trusted_devices enable row level security;
alter table user_approvals enable row level security;

create publication supabase_realtime for table messages, appointments, medications, medication_logs, health_data, daily_checkins, stories;