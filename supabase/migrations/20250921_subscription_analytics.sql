-- Subscription analytics schema
create table if not exists public.trial_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  event_type text not null,
  event_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_trial_events_user on public.trial_events(user_id);
create index if not exists idx_trial_events_type on public.trial_events(event_type);
create index if not exists idx_trial_events_created on public.trial_events(created_at desc);

alter table public.trial_events enable row level security;
create policy if not exists "trial_events_authenticated_read" on public.trial_events for select to authenticated using (true);
create policy if not exists "trial_events_owner_write" on public.trial_events for insert to authenticated with check (auth.uid() = user_id or user_id = 'bulk');

create table if not exists public.conversion_experiments (
  id uuid primary key default gen_random_uuid(),
  experiment_name text not null,
  user_id uuid references public.users(id) on delete cascade,
  variant text not null,
  converted boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_conv_exp_user on public.conversion_experiments(user_id);
create index if not exists idx_conv_exp_name on public.conversion_experiments(experiment_name);

alter table public.conversion_experiments enable row level security;
create policy if not exists "conv_exp_authenticated_read" on public.conversion_experiments for select to authenticated using (true);
create policy if not exists "conv_exp_owner_write" on public.conversion_experiments for insert to authenticated with check (auth.uid() = user_id);
create policy if not exists "conv_exp_owner_update" on public.conversion_experiments for update to authenticated using (auth.uid() = user_id);

create or replace function public.avg_days_to_conversion()
returns numeric language sql as $$
with starts as (
  select user_id, min(created_at) as started_at
  from public.trial_events
  where event_type = 'trial_started'
  group by user_id
),
conversions as (
  select user_id, min(created_at) as converted_at
  from public.trial_events
  where event_type = 'converted'
  group by user_id
)
select coalesce(avg(extract(day from (c.converted_at - s.started_at))), 0)
from starts s
join conversions c using (user_id);
$$;

create or replace function public.get_mrr()
returns numeric language sql as $$
select 0::numeric;$$;

create or replace function public.get_arpu()
returns numeric language sql as $$
select 0::numeric;$$;