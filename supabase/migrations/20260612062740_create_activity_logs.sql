create table public.activity_logs (
    id uuid primary key default gen_random_uuid(),

    organization_id uuid not null
        references public.organizations(id)
        on delete cascade,

    actor_id uuid not null
        references auth.users(id),

    entity_type text not null,
    entity_id uuid not null,

    action text not null,

    metadata jsonb default '{}'::jsonb,

    created_at timestamptz not null default now()
);

create index idx_activity_logs_org
on public.activity_logs(organization_id);

create index idx_activity_logs_created
on public.activity_logs(created_at desc);