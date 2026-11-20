create extension if not exists pgcrypto;

create table if not exists public.sign_jobs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  original_name text not null,
  input_path text not null unique,
  output_path text,
  manifest_path text,
  status text not null default 'queued' check (status in ('queued','signing','complete','failed')),
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
 );

alter table public.sign_jobs enable row level security;
revoke all on public.sign_jobs from anon;
grant usage on schema public to authenticated, service_role;
grant select on public.sign_jobs to authenticated;
grant all on public.sign_jobs to service_role;

drop policy if exists "Users can view their own signing jobs" on public.sign_jobs;
create policy "Users can view their own signing jobs" on public.sign_jobs for select to authenticated using ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ipa-jobs','ipa-jobs',false,524288000,array['application/octet-stream','application/zip','application/xml'])
on conflict (id) do update set public=false, file_size_limit=524288000, allowed_mime_types=excluded.allowed_mime_types;