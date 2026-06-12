create type member_role as enum (
    'owner',
    'admin',
    'member'
);

create table public.memberships (
    id uuid primary key default gen_random_uuid(),

    organization_id uuid not null
        references public.organizations(id)
        on delete cascade,

    team_id uuid
        references public.teams(id)
        on delete cascade,

    user_id uuid not null
        references auth.users(id)
        on delete cascade,

    role member_role not null default 'member',

    created_at timestamptz not null default now(),

    unique(team_id, user_id)
);

create index idx_memberships_user
on public.memberships(user_id);

create index idx_memberships_team
on public.memberships(team_id);

create index idx_memberships_org
on public.memberships(organization_id);