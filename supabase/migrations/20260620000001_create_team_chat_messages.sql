-- Team Chat Messages Table
-- Run this in your Supabase SQL Editor or as a new migration

create table if not exists public.team_chat_messages (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.team_chat_messages enable row level security;

-- RLS: Organization members can read team chat messages
create policy "Team members can read chat messages"
  on public.team_chat_messages
  for select
  using (
    exists (
      select 1 from public.team_members tm
      where tm.team_id = team_chat_messages.team_id
        and tm.user_id = auth.uid()
    )
  );

-- RLS: Organization members can insert messages
create policy "Team members can send chat messages"
  on public.team_chat_messages
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.team_members tm
      where tm.team_id = team_chat_messages.team_id
        and tm.user_id = auth.uid()
    )
  );

-- Index for performance
create index if not exists team_chat_messages_team_id_idx
  on public.team_chat_messages(team_id, created_at desc);

-- Enable realtime for this table (run in Supabase dashboard if needed)
-- alter publication supabase_realtime add table public.team_chat_messages;
