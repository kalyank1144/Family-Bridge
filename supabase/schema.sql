-- FamilyBridge Supabase Schema
-- Run this in Supabase SQL Editor

-- Extensions
create extension if not exists pgcrypto;

-- USERS (profile) table referencing auth.users
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  role text check (role in ('elder','caregiver','youth')) default 'elder',
  date_of_birth date,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;

-- Only the user can see or edit their profile
create policy if not exists "Users can view own profile" on public.users
for select using (auth.uid() = id);

create policy if not exists "Users can update own profile" on public.users
for update using (auth.uid() = id);

-- EMERGENCY CONTACTS
create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  relationship text,
  phone text not null,
  photo_url text,
  priority int default 999,
  created_at timestamptz not null default now()
);

alter table public.emergency_contacts enable row level security;

create policy if not exists "Elder read own contacts" on public.emergency_contacts
for select using (auth.uid() = elder_id);

create policy if not exists "Elder manage own contacts" on public.emergency_contacts
for all using (auth.uid() = elder_id) with check (auth.uid() = elder_id);

-- MEDICATIONS
create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  dosage text not null,
  frequency text default 'daily',
  next_dose_time timestamptz not null,
  instructions text,
  photo_url text,
  requires_photo_confirmation boolean default false,
  times text[] default '{}',
  created_at timestamptz not null default now()
);

alter table public.medications enable row level security;

create policy if not exists "Elder read own medications" on public.medications
for select using (auth.uid() = elder_id);

create policy if not exists "Elder manage own medications" on public.medications
for all using (auth.uid() = elder_id) with check (auth.uid() = elder_id);

-- MEDICATION LOGS
create table if not exists public.medication_logs (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  elder_id uuid not null references public.users(id) on delete cascade,
  taken_at timestamptz not null default now(),
  photo_url text,
  confirmed boolean default false,
  skipped boolean default false,
  skip_reason text,
  created_at timestamptz not null default now()
);

create index if not exists idx_med_logs_elder_time on public.medication_logs(elder_id, taken_at desc);

alter table public.medication_logs enable row level security;

create policy if not exists "Elder read own med logs" on public.medication_logs
for select using (auth.uid() = elder_id);

create policy if not exists "Elder insert med logs" on public.medication_logs
for insert with check (auth.uid() = elder_id);

-- DAILY CHECKINS
create table if not exists public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references public.users(id) on delete cascade,
  mood text,
  sleep_quality text,
  meal_eaten boolean default false,
  medication_taken boolean default false,
  physical_activity boolean default false,
  pain_level int default 0,
  notes text,
  voice_note_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_checkins_elder_time on public.daily_checkins(elder_id, created_at desc);

alter table public.daily_checkins enable row level security;

create policy if not exists "Elder read own checkins" on public.daily_checkins
for select using (auth.uid() = elder_id);

create policy if not exists "Elder insert checkins" on public.daily_checkins
for insert with check (auth.uid() = elder_id);


-- STORAGE buckets (for photos and voice notes)
-- Create buckets in Storage UI named 'medication-photos' and 'voice-notes'
-- Then run these policies in SQL editor

-- Allow users to manage their own files in medication-photos
insert into storage.buckets (id, name, public) values ('medication-photos','medication-photos', false)
  on conflict (id) do nothing;

insert into storage.buckets (id, name, public) values ('voice-notes','voice-notes', false)
  on conflict (id) do nothing;

create policy if not exists "Users can upload medication photos" on storage.objects
for insert to authenticated
with check (bucket_id = 'medication-photos' and owner = auth.uid());

create policy if not exists "Users can read own medication photos" on storage.objects
for select using (bucket_id = 'medication-photos' and owner = auth.uid());

create policy if not exists "Users can upload voice notes" on storage.objects
for insert to authenticated
with check (bucket_id = 'voice-notes' and owner = auth.uid());

create policy if not exists "Users can read own voice notes" on storage.objects
for select using (bucket_id = 'voice-notes' and owner = auth.uid());
