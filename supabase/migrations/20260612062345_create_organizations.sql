    create table organizations (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    owner_id uuid not null references auth.users(id),
    created_at timestamptz default now()
);

create index idx_organizations_owner
on organizations(owner_id); 