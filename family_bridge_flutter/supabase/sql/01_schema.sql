-- Enable extensions if needed
create extension if not exists pgcrypto;

-- User type enum
create type user_type as enum ('elder', 'caregiver', 'youth');

-- Users table linking to auth.users
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  user_type user_type not null,
  display_name text not null default '',
  phone text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Families
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Family members
create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role user_type not null,
  invited_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- Health data
create table if not exists public.health_data (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  systolic int,
  diastolic int,
  heart_rate int,
  notes text,
  recorded_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Medications
create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  dosage text,
  schedule jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Medication logs
create table if not exists public.medication_logs (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  status text check (status in ('taken','skipped','missed')),
  taken_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  recipient_id uuid references public.users(id),
  content text not null,
  created_at timestamptz not null default now()
);

-- Emergency contacts
create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid references public.users(id),
  name text not null,
  phone text not null,
  relation text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Appointments
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  location text,
  scheduled_at timestamptz not null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Daily check-ins
create table if not exists public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  mood int check (mood between 1 and 5),
  energy int check (energy between 1 and 5),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Care points
create table if not exists public.care_points (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  points int not null default 0,
  reason text,
  created_at timestamptz not null default now()
);

-- Stories
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  author_id uuid not null references public.users(id) on delete cascade,
  title text,
  body text,
  media_urls text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger users_updated_at before update on public.users for each row execute function public.set_updated_at();
create trigger families_updated_at before update on public.families for each row execute function public.set_updated_at();
create trigger health_data_updated_at before update on public.health_data for each row execute function public.set_updated_at();
create trigger medications_updated_at before update on public.medications for each row execute function public.set_updated_at();
create trigger medication_logs_updated_at before update on public.medication_logs for each row execute function public.set_updated_at();
create trigger emergency_contacts_updated_at before update on public.emergency_contacts for each row execute function public.set_updated_at();
create trigger appointments_updated_at before update on public.appointments for each row execute function public.set_updated_at();
create trigger daily_checkins_updated_at before update on public.daily_checkins for each row execute function public.set_updated_at();
create trigger stories_updated_at before update on public.stories for each row execute function public.set_updated_at();

-- Helpful indexes
create index if not exists idx_family_members_user on public.family_members(user_id);
create index if not exists idx_family_members_family on public.family_members(family_id);
create index if not exists idx_health_data_family on public.health_data(family_id);
create index if not exists idx_medications_family on public.medications(family_id);
create index if not exists idx_medication_logs_family on public.medication_logs(family_id);
create index if not exists idx_messages_family on public.messages(family_id);
create index if not exists idx_appointments_family on public.appointments(family_id);
create index if not exists idx_daily_checkins_family on public.daily_checkins(family_id);
create index if not exists idx_stories_family on public.stories(family_id);
