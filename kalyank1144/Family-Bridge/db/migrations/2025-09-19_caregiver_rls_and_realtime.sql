alter table if exists caregiver_patients enable row level security;

create policy caregiver_self_select on caregiver_patients for select using (caregiver_id = auth.uid());
create policy elder_self_select on caregiver_patients for select using (elder_id = auth.uid());
create policy caregiver_manage on caregiver_patients for insert with check (caregiver_id = auth.uid());
create policy caregiver_remove on caregiver_patients for delete using (caregiver_id = auth.uid());

-- Allow admins to view profiles
create policy if not exists profiles_admin_select on profiles for select using (
  exists(select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- Let caregivers see elder profiles they are assigned to
create policy if not exists profiles_caregiver_select on profiles for select using (
  exists (
    select 1 from caregiver_patients cp
    where cp.caregiver_id = auth.uid() and cp.elder_id = profiles.id
  )
);

-- Optional: full_name for UI
alter table profiles add column if not exists full_name text;

-- Add to realtime publication
alter publication supabase_realtime add table caregiver_patients, profiles;