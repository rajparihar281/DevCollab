create table public.teams (
    id uuid primary key default gen_random_uuid(),

    organization_id uuid not null
        references public.organizations(id)
        on delete cascade,

    name text not null,
    description text,

    created_by uuid not null
        references auth.users(id),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_teams_organization
on public.teams(organization_id);