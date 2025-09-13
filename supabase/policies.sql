begin;

create policy select_own_profile on profiles for select using (auth.uid() = id);
create policy insert_own_profile on profiles for insert with check (auth.uid() = id);
create policy update_own_profile on profiles for update using (auth.uid() = id);

-- Allow authenticated users to discover families (e.g., join by code)
create policy select_all_families_for_join on families for select to authenticated using (true);
create policy insert_family_any_auth on families for insert to authenticated with check (true);

create policy select_member_family_members on family_members for select using (
  exists (select 1 from family_members fm where fm.family_id = family_members.family_id and fm.user_id = auth.uid())
);
create policy insert_self_membership on family_members for insert with check (user_id = auth.uid());

create policy using_family_scope_messages on messages for select using (
  exists (select 1 from family_members fm where fm.family_id = messages.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_messages on messages for insert with check (
  exists (select 1 from family_members fm where fm.family_id = messages.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_appointments on appointments for select using (
  exists (select 1 from family_members fm where fm.family_id = appointments.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_appointments on appointments for insert with check (
  exists (select 1 from family_members fm where fm.family_id = appointments.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_emergency_contacts on emergency_contacts for select using (
  exists (select 1 from family_members fm where fm.family_id = emergency_contacts.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_emergency_contacts on emergency_contacts for insert with check (
  exists (select 1 from family_members fm where fm.family_id = emergency_contacts.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_medications on medications for select using (
  exists (select 1 from family_members fm where fm.family_id = medications.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_medications on medications for insert with check (
  exists (select 1 from family_members fm where fm.family_id = medications.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_medication_logs on medication_logs for select using (
  exists (
    select 1 from medications m join family_members fm on fm.family_id = m.family_id
    where m.id = medication_logs.medication_id and fm.user_id = auth.uid()
  )
);
create policy insert_family_scope_medication_logs on medication_logs for insert with check (
  exists (
    select 1 from medications m join family_members fm on fm.family_id = m.family_id
    where m.id = medication_logs.medication_id and fm.user_id = auth.uid()
  )
);

create policy using_family_scope_health_data on health_data for select using (
  exists (select 1 from family_members fm where fm.family_id = health_data.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_health_data on health_data for insert with check (
  exists (select 1 from family_members fm where fm.family_id = health_data.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_daily_checkins on daily_checkins for select using (
  exists (select 1 from family_members fm where fm.family_id = daily_checkins.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_daily_checkins on daily_checkins for insert with check (
  exists (select 1 from family_members fm where fm.family_id = daily_checkins.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_care_points on care_points for select using (
  exists (select 1 from family_members fm where fm.family_id = care_points.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_care_points on care_points for insert with check (
  exists (select 1 from family_members fm where fm.family_id = care_points.family_id and fm.user_id = auth.uid())
);

create policy using_family_scope_stories on stories for select using (
  exists (select 1 from family_members fm where fm.family_id = stories.family_id and fm.user_id = auth.uid())
);
create policy insert_family_scope_stories on stories for insert with check (
  exists (select 1 from family_members fm where fm.family_id = stories.family_id and fm.user_id = auth.uid())
);

-- Trusted devices
create policy select_own_trusted_devices on trusted_devices for select using (auth.uid() = user_id);
create policy insert_own_trusted_devices on trusted_devices for insert with check (auth.uid() = user_id);

-- Youth approvals
create policy select_own_approvals on user_approvals for select using (auth.uid() = youth_id);
create policy insert_own_approvals on user_approvals for insert with check (auth.uid() = youth_id);
create policy update_own_approvals on user_approvals for update using (auth.uid() = youth_id);

commit;