-- Migration: Align Schema with Documentation (docs/supabase-schema.md)
-- Creates profiles, organization_members, team_members, attachments,
-- migrates existing data from memberships table, and sets up RLS policies & triggers.

-- 1. PROFILES TABLE & ONBOARDING TRIGGER
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, full_name, avatar_url, created_at, updated_at)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url',
        now(),
        now()
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
    after insert on auth.users
    for each row execute function public.handle_new_user_profile();

-- Backfill any existing auth.users into profiles
insert into public.profiles (id, full_name, created_at, updated_at)
select id, coalesce(raw_user_meta_data->>'full_name', split_part(email, '@', 1)), created_at, coalesce(last_sign_in_at, created_at)
from auth.users
on conflict (id) do nothing;

drop policy if exists "Profiles are readable by authenticated users" on public.profiles;
create policy "Profiles are readable by authenticated users"
on public.profiles
for select
to authenticated
using (true);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);


-- 2. ORGANIZATION MEMBERS TABLE
create table if not exists public.organization_members (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null check (role in ('owner', 'admin', 'member', 'viewer')),
    joined_at timestamptz not null default now(),
    unique(organization_id, user_id)
);
alter table public.organization_members enable row level security;

create index if not exists idx_org_members_org on public.organization_members(organization_id);
create index if not exists idx_org_members_user on public.organization_members(user_id);


-- 3. TEAM MEMBERS TABLE
create table if not exists public.team_members (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    joined_at timestamptz not null default now(),
    unique(team_id, user_id)
);
alter table public.team_members enable row level security;

create index if not exists idx_team_members_team on public.team_members(team_id);
create index if not exists idx_team_members_user on public.team_members(user_id);


-- 4. ATTACHMENTS TABLE
create table if not exists public.attachments (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks(id) on delete cascade,
    uploaded_by uuid references public.profiles(id) on delete set null,
    file_name text not null,
    file_path text not null,
    file_size bigint,
    uploaded_at timestamptz not null default now()
);
alter table public.attachments enable row level security;

create index if not exists idx_attachments_task on public.attachments(task_id);


-- 5. MIGRATE EXISTING DATA FROM LEGACY MEMBERSHIPS TABLE IF PRESENT
do $$
begin
    if exists (select from information_schema.tables where table_schema = 'public' and table_name = 'memberships') then
        -- Migrate org members
        insert into public.organization_members (id, organization_id, user_id, role, joined_at)
        select id, organization_id, user_id, role::text, created_at
        from public.memberships
        where team_id is null
        on conflict (organization_id, user_id) do nothing;
        
        -- Migrate team members
        insert into public.team_members (id, team_id, user_id, joined_at)
        select id, team_id, user_id, created_at
        from public.memberships
        where team_id is not null
        on conflict (team_id, user_id) do nothing;
    end if;
end $$;


-- 6. UPDATE HELPER FUNCTIONS
create or replace function public.is_org_member(org_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.organization_members
        where organization_id = org_uuid
        and user_id = auth.uid()
    );
$$;

create or replace function public.is_org_owner(org_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.organization_members
        where organization_id = org_uuid
        and user_id = auth.uid()
        and role = 'owner'
    ) or exists (
        select 1
        from public.organizations
        where id = org_uuid
        and owner_id = auth.uid()
    );
$$;

create or replace function public.is_team_member(team_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.team_members
        where team_id = team_uuid
        and user_id = auth.uid()
    );
$$;

create or replace function public.is_team_admin(team_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.team_members tm
        join public.teams t on t.id = tm.team_id
        join public.organization_members om on om.organization_id = t.organization_id and om.user_id = auth.uid()
        where tm.team_id = team_uuid
        and om.role in ('owner', 'admin')
    );
$$;


-- 7. ORGANIZATION CREATOR BOOTSTRAP TRIGGER
create or replace function public.handle_new_organization()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.organization_members (
        organization_id,
        user_id,
        role,
        joined_at
    )
    values (
        new.id,
        new.owner_id,
        'owner',
        now()
    )
    on conflict (organization_id, user_id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_organization_created on public.organizations;
create trigger on_organization_created
    after insert on public.organizations
    for each row execute function public.handle_new_organization();


-- 8. RLS POLICIES FOR NEW TABLES
-- Organization Members RLS
drop policy if exists "Organization members can view membership" on public.organization_members;
create policy "Organization members can view membership"
on public.organization_members
for select
to authenticated
using (
    public.is_org_member(organization_id)
);

drop policy if exists "Owners and admins can create org members" on public.organization_members;
create policy "Owners and admins can create org members"
on public.organization_members
for insert
to authenticated
with check (
    exists (
        select 1 from public.organization_members om
        where om.organization_id = organization_members.organization_id
        and om.user_id = auth.uid()
        and om.role in ('owner', 'admin')
    ) or (
        user_id = auth.uid() and role = 'owner' and exists (
            select 1 from public.organizations o where o.id = organization_members.organization_id and o.owner_id = auth.uid()
        )
    )
);

drop policy if exists "Owners can update org members" on public.organization_members;
create policy "Owners can update org members"
on public.organization_members
for update
to authenticated
using (
    exists (
        select 1 from public.organization_members om
        where om.organization_id = organization_members.organization_id
        and om.user_id = auth.uid()
        and om.role = 'owner'
    )
);

drop policy if exists "Owners can delete org members" on public.organization_members;
create policy "Owners can delete org members"
on public.organization_members
for delete
to authenticated
using (
    exists (
        select 1 from public.organization_members om
        where om.organization_id = organization_members.organization_id
        and om.user_id = auth.uid()
        and om.role = 'owner'
    ) or user_id = auth.uid()
);

-- Team Members RLS
drop policy if exists "Team members and org admins can view team members" on public.team_members;
create policy "Team members and org admins can view team members"
on public.team_members
for select
to authenticated
using (
    exists (
        select 1 from public.teams t
        where t.id = team_members.team_id
        and public.is_org_member(t.organization_id)
    )
);

drop policy if exists "Org admins can insert team members" on public.team_members;
create policy "Org admins can insert team members"
on public.team_members
for insert
to authenticated
with check (
    exists (
        select 1 from public.teams t
        join public.organization_members om on om.organization_id = t.organization_id
        where t.id = team_members.team_id
        and om.user_id = auth.uid()
        and om.role in ('owner', 'admin')
    ) or (
        user_id = auth.uid() and exists (
            select 1 from public.teams t where t.id = team_members.team_id and t.created_by = auth.uid()
        )
    )
);

drop policy if exists "Org admins can delete team members" on public.team_members;
create policy "Org admins can delete team members"
on public.team_members
for delete
to authenticated
using (
    exists (
        select 1 from public.teams t
        join public.organization_members om on om.organization_id = t.organization_id
        where t.id = team_members.team_id
        and om.user_id = auth.uid()
        and om.role in ('owner', 'admin')
    ) or user_id = auth.uid()
);

-- Attachments RLS
drop policy if exists "Org members can view attachments" on public.attachments;
create policy "Org members can view attachments"
on public.attachments
for select
to authenticated
using (
    exists (
        select 1 from public.tasks tk
        join public.projects p on p.id = tk.project_id
        join public.teams tm on tm.id = p.team_id
        where tk.id = attachments.task_id
        and public.is_org_member(tm.organization_id)
    )
);

drop policy if exists "Org members can upload attachments" on public.attachments;
create policy "Org members can upload attachments"
on public.attachments
for insert
to authenticated
with check (
    exists (
        select 1 from public.tasks tk
        join public.projects p on p.id = tk.project_id
        join public.teams tm on tm.id = p.team_id
        where tk.id = attachments.task_id
        and public.is_org_member(tm.organization_id)
    )
);

drop policy if exists "Uploaders and admins can delete attachments" on public.attachments;
create policy "Uploaders and admins can delete attachments"
on public.attachments
for delete
to authenticated
using (
    uploaded_by = auth.uid() or exists (
        select 1 from public.tasks tk
        join public.projects p on p.id = tk.project_id
        join public.teams tm on tm.id = p.team_id
        join public.organization_members om on om.organization_id = tm.organization_id
        where tk.id = attachments.task_id
        and om.user_id = auth.uid()
        and om.role in ('owner', 'admin')
    )
);


-- 9. UPDATE RLS POLICIES ON EXISTING TABLES TO USE NEW MEMBERSHIP TABLES
-- Organizations
drop policy if exists "organization_members_can_view" on public.organizations;
create policy "organization_members_can_view"
on public.organizations
for select
to authenticated
using (
    owner_id = auth.uid()
    or exists (
        select 1
        from public.organization_members m
        where m.organization_id = organizations.id
        and m.user_id = auth.uid()
    )
);

-- Teams
drop policy if exists "team_members_can_view" on public.teams;
create policy "team_members_can_view"
on public.teams
for select
to authenticated
using (
    exists (
        select 1
        from public.organization_members m
        where m.organization_id = teams.organization_id
        and m.user_id = auth.uid()
    )
);

drop policy if exists "team_admins_can_modify" on public.teams;
create policy "team_admins_can_modify"
on public.teams
for update
to authenticated
using (
    exists (
        select 1
        from public.organization_members m
        where m.organization_id = teams.organization_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

drop policy if exists "team_admins_can_delete" on public.teams;
create policy "team_admins_can_delete"
on public.teams
for delete
to authenticated
using (
    exists (
        select 1
        from public.organization_members m
        where m.organization_id = teams.organization_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

drop policy if exists "organization_members_can_create_teams" on public.teams;
create policy "organization_members_can_create_teams"
on public.teams
for insert
to authenticated
with check (
    exists (
        select 1
        from public.organization_members m
        where m.organization_id = teams.organization_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    ) or exists (
        select 1 from public.organizations o where o.id = teams.organization_id and o.owner_id = auth.uid()
    )
);

-- Projects
drop policy if exists "project_members_can_view" on public.projects;
drop policy if exists "project_team_members_can_view" on public.projects;
create policy "project_team_members_can_view"
on public.projects
for select
to authenticated
using (
    exists (
        select 1
        from public.team_members m
        where m.team_id = projects.team_id
        and m.user_id = auth.uid()
    ) or exists (
        select 1 from public.teams tm where tm.id = projects.team_id and public.is_org_member(tm.organization_id)
    )
);

drop policy if exists "team_members_can_create_projects" on public.projects;
drop policy if exists "project_team_members_can_create" on public.projects;
create policy "project_team_members_can_create"
on public.projects
for insert
to authenticated
with check (
    exists (
        select 1
        from public.team_members m
        where m.team_id = projects.team_id
        and m.user_id = auth.uid()
    ) or exists (
        select 1 from public.teams tm join public.organization_members om on om.organization_id = tm.organization_id where tm.id = projects.team_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
    )
);

drop policy if exists "project_admins_can_modify" on public.projects;
create policy "project_admins_can_modify"
on public.projects
for update
to authenticated
using (
    exists (
        select 1 from public.teams tm join public.organization_members om on om.organization_id = tm.organization_id where tm.id = projects.team_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
    )
);

drop policy if exists "project_admins_can_delete" on public.projects;
create policy "project_admins_can_delete"
on public.projects
for delete
to authenticated
using (
    exists (
        select 1 from public.teams tm join public.organization_members om on om.organization_id = tm.organization_id where tm.id = projects.team_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
    )
);

-- Tasks
drop policy if exists "project_members_can_view_tasks" on public.tasks;
drop policy if exists "task_team_members_can_view" on public.tasks;
create policy "task_team_members_can_view"
on public.tasks
for select
to authenticated
using (
    exists (
        select 1 from public.projects p join public.teams tm on tm.id = p.team_id where p.id = tasks.project_id and (public.is_team_member(p.team_id) or public.is_org_member(tm.organization_id))
    )
);

drop policy if exists "project_members_can_create_tasks" on public.tasks;
drop policy if exists "task_team_members_can_create" on public.tasks;
create policy "task_team_members_can_create"
on public.tasks
for insert
to authenticated
with check (
    exists (
        select 1 from public.projects p join public.teams tm on tm.id = p.team_id join public.organization_members om on om.organization_id = tm.organization_id where p.id = tasks.project_id and om.user_id = auth.uid() and om.role in ('owner', 'admin', 'member')
    )
);

drop policy if exists "project_members_can_update_tasks" on public.tasks;
drop policy if exists "task_team_members_can_update" on public.tasks;
create policy "task_team_members_can_update"
on public.tasks
for update
to authenticated
using (
    exists (
        select 1 from public.projects p join public.teams tm on tm.id = p.team_id join public.organization_members om on om.organization_id = tm.organization_id where p.id = tasks.project_id and om.user_id = auth.uid() and om.role in ('owner', 'admin', 'member')
    )
);

drop policy if exists "project_admins_can_delete_tasks" on public.tasks;
drop policy if exists "task_admins_can_delete" on public.tasks;
create policy "task_admins_can_delete"
on public.tasks
for delete
to authenticated
using (
    exists (
        select 1 from public.projects p join public.teams tm on tm.id = p.team_id join public.organization_members om on om.organization_id = tm.organization_id where p.id = tasks.project_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
    ) or created_by = auth.uid()
);

-- Comments
drop policy if exists "task_members_can_view_comments" on public.comments;
drop policy if exists "comment_members_can_view" on public.comments;
create policy "comment_members_can_view"
on public.comments
for select
to authenticated
using (
    exists (
        select 1 from public.tasks tk join public.projects p on p.id = tk.project_id join public.teams tm on tm.id = p.team_id where tk.id = comments.task_id and (public.is_team_member(p.team_id) or public.is_org_member(tm.organization_id))
    )
);

drop policy if exists "task_members_can_create_comments" on public.comments;
drop policy if exists "comment_members_can_create" on public.comments;
create policy "comment_members_can_create"
on public.comments
for insert
to authenticated
with check (
    author_id = auth.uid() and exists (
        select 1 from public.tasks tk join public.projects p on p.id = tk.project_id join public.teams tm on tm.id = p.team_id where tk.id = comments.task_id and (public.is_team_member(p.team_id) or public.is_org_member(tm.organization_id))
    )
);

drop policy if exists "comment_authors_can_modify" on public.comments;
drop policy if exists "comment_author_can_update" on public.comments;
create policy "comment_author_can_update"
on public.comments
for update
to authenticated
using (author_id = auth.uid());

drop policy if exists "comment_authors_can_delete" on public.comments;
drop policy if exists "comment_author_can_delete" on public.comments;
create policy "comment_author_can_delete"
on public.comments
for delete
to authenticated
using (author_id = auth.uid() or exists (
    select 1 from public.tasks tk join public.projects p on p.id = tk.project_id join public.teams tm on tm.id = p.team_id join public.organization_members om on om.organization_id = tm.organization_id where tk.id = comments.task_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
));

-- Activity Logs
drop policy if exists "organization_members_can_view_logs" on public.activity_logs;
drop policy if exists "members_can_view_activity_logs" on public.activity_logs;
create policy "members_can_view_activity_logs"
on public.activity_logs
for select
to authenticated
using (
    exists (
        select 1
        from public.organization_members m
        where m.organization_id = activity_logs.organization_id
        and m.user_id = auth.uid()
    )
);

drop policy if exists "authenticated_users_can_create_logs" on public.activity_logs;
create policy "authenticated_users_can_create_logs"
on public.activity_logs
for insert
to authenticated
with check (
    actor_id = auth.uid()
);
