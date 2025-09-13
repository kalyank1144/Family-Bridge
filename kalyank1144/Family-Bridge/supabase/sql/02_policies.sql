-- Enable RLS
alter table public.users enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.health_data enable row level security;
alter table public.medications enable row level security;
alter table public.medication_logs enable row level security;
alter table public.messages enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.appointments enable row level security;
alter table public.daily_checkins enable row level security;
alter table public.stories enable row level security;

-- Helper function: is user a member of family
create or replace function public.is_family_member(f_id uuid)
returns boolean as $$
  select exists(
    select 1 from public.family_members fm
    where fm.family_id = f_id and fm.user_id = auth.uid()
  );
$$ language sql stable;

-- Users: self access
create policy "Users can view self" on public.users for select using (id = auth.uid());
create policy "Users can update self" on public.users for update using (id = auth.uid());

-- Families: member can read; caregivers can create
create policy "Members read family" on public.families for select using (public.is_family_member(id));
create policy "Caregiver create family" on public.families for insert with check (
  exists (select 1 from public.users u where u.id = auth.uid() and u.user_type = 'caregiver')
);
create policy "Caregiver update family" on public.families for update using (
  exists (
    select 1 from public.family_members fm where fm.family_id = id and fm.user_id = auth.uid() and fm.role in ('caregiver')
  )
);

-- Family members: members can view; caregiver can manage
create policy "Members read membership" on public.family_members for select using (public.is_family_member(family_id));
create policy "Caregiver manage membership" on public.family_members for all using (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
) with check (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
);

-- Generic family-scoped tables
-- Health data
create policy "Members read health_data" on public.health_data for select using (public.is_family_member(family_id));
create policy "Owner write health_data" on public.health_data for insert with check (user_id = auth.uid());
create policy "Owner update health_data" on public.health_data for update using (user_id = auth.uid());

-- Medications
create policy "Members read medications" on public.medications for select using (public.is_family_member(family_id));
create policy "Caregiver manage medications" on public.medications for all using (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
) with check (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
);

-- Medication logs: members can insert for themselves, and caregivers can insert for elders
create policy "Members read medication_logs" on public.medication_logs for select using (public.is_family_member(family_id));
create policy "User insert own medication_logs" on public.medication_logs for insert with check (user_id = auth.uid());
create policy "User update own medication_logs" on public.medication_logs for update using (user_id = auth.uid());

-- Messages
create policy "Members read messages" on public.messages for select using (public.is_family_member(family_id));
create policy "Members insert messages" on public.messages for insert with check (public.is_family_member(family_id));

-- Emergency contacts
create policy "Members read emergency_contacts" on public.emergency_contacts for select using (public.is_family_member(family_id));
create policy "Caregiver manage emergency_contacts" on public.emergency_contacts for all using (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
) with check (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
);

-- Appointments
create policy "Members read appointments" on public.appointments for select using (public.is_family_member(family_id));
create policy "Caregiver manage appointments" on public.appointments for all using (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
) with check (
  exists (
    select 1 from public.family_members fm where fm.family_id = family_id and fm.user_id = auth.uid() and fm.role = 'caregiver'
  )
);

-- Daily check-ins: users write own, members read
create policy "Members read daily_checkins" on public.daily_checkins for select using (public.is_family_member(family_id));
create policy "User write own checkins" on public.daily_checkins for insert with check (user_id = auth.uid());
create policy "User update own checkins" on public.daily_checkins for update using (user_id = auth.uid());

-- Stories: members read, caregivers/youth insert, author update
create policy "Members read stories" on public.stories for select using (public.is_family_member(family_id));
create policy "Members insert stories" on public.stories for insert with check (public.is_family_member(family_id));
create policy "Author update stories" on public.stories for update using (author_id = auth.uid());
