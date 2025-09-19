-- Ensure caregiver_patients has FKs to profiles for PostgREST embeds
alter table caregiver_patients
  add constraint fk_caregiver_patients_elder_profile
  foreign key (elder_id) references profiles(id) on delete cascade;

alter table caregiver_patients
  add constraint fk_caregiver_patients_caregiver_profile
  foreign key (caregiver_id) references profiles(id) on delete cascade;