create table public.projects (
    id uuid primary key default gen_random_uuid(),

    team_id uuid not null
        references public.teams(id)
        on delete cascade,

    name text not null,
    description text,

    created_by uuid not null
        references auth.users(id),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_projects_team
on public.projects(team_id);