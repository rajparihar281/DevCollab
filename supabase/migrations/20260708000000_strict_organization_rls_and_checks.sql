-- Migration: Strict Organization & Membership RLS Policies and Helper Functions
-- Ensures strict isolation so users can ONLY view/edit/update organizations where they are owner/admin/member.

-- 1. Updated Helper Functions to check organization_members correctly
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
    ) or exists (
        select 1
        from public.organizations
        where id = org_uuid
        and owner_id = auth.uid()
    );
$$;

create or replace function public.is_org_admin(org_uuid uuid)
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
        and role in ('owner', 'admin')
    ) or exists (
        select 1
        from public.organizations
        where id = org_uuid
        and owner_id = auth.uid()
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

-- 2. Drop all existing policies on public.organizations and enforce strict isolation
alter table public.organizations enable row level security;

drop policy if exists "organization_members_can_view" on public.organizations;
drop policy if exists "organization_owners_can_update" on public.organizations;
drop policy if exists "authenticated_users_can_create_organizations" on public.organizations;
drop policy if exists "organization_owners_can_delete" on public.organizations;
drop policy if exists "Organizations readable by members" on public.organizations;
drop policy if exists "Organizations updatable by owners or admins" on public.organizations;

-- SELECT policy: Only users who are owner or part of organization_members can view the organization
create policy "Strict org view policy"
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

-- INSERT policy: Any authenticated user can create an organization where they set themselves as owner
create policy "Strict org insert policy"
on public.organizations
for insert
to authenticated
with check (
    owner_id = auth.uid()
);

-- UPDATE policy: Only owners or organization admins can update the organization
create policy "Strict org update policy"
on public.organizations
for update
to authenticated
using (
    owner_id = auth.uid()
    or exists (
        select 1
        from public.organization_members m
        where m.organization_id = organizations.id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

-- DELETE policy: Only the owner can delete the organization
create policy "Strict org delete policy"
on public.organizations
for delete
to authenticated
using (
    owner_id = auth.uid()
    or exists (
        select 1
        from public.organization_members m
        where m.organization_id = organizations.id
        and m.user_id = auth.uid()
        and m.role = 'owner'
    )
);

-- 3. Drop and enforce strict policies on public.organization_members
alter table public.organization_members enable row level security;

drop policy if exists "Organization members can view membership" on public.organization_members;
drop policy if exists "Owners and admins can create org members" on public.organization_members;
drop policy if exists "Owners can update org members" on public.organization_members;
drop policy if exists "Owners can delete org members" on public.organization_members;

create policy "Strict org members view policy"
on public.organization_members
for select
to authenticated
using (
    user_id = auth.uid()
    or public.is_org_member(organization_id)
);

create policy "Strict org members insert policy"
on public.organization_members
for insert
to authenticated
with check (
    user_id = auth.uid()
    or public.is_org_admin(organization_id)
);

create policy "Strict org members update policy"
on public.organization_members
for update
to authenticated
using (
    public.is_org_admin(organization_id)
);

create policy "Strict org members delete policy"
on public.organization_members
for delete
to authenticated
using (
    user_id = auth.uid()
    or public.is_org_admin(organization_id)
);
