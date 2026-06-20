k-- Migration: Fix Membership RLS Recursion and Add Organization Owner Bootstrap Trigger
-- Up:

-- 1. Drop the recursive memberships select policy
drop policy if exists "members_can_view_memberships" on public.memberships;

-- 2. Create the simple safe select policy
create policy "members_can_view_memberships"
on public.memberships
for select
to authenticated
using (
    user_id = auth.uid()
);

-- 3. Create the SECURITY DEFINER trigger function to automatically create organization owner membership
create or replace function public.handle_new_organization()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.memberships (
        organization_id,
        user_id,
        role
    )
    values (
        new.id,
        new.owner_id,
        'owner'
    );
    return new;
end;
$$;

-- 4. Create the trigger on organizations
drop trigger if exists on_organization_created on public.organizations;
create trigger on_organization_created
    after insert on public.organizations
    for each row execute function public.handle_new_organization();
