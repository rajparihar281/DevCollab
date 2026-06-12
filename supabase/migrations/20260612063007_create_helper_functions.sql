/*
|--------------------------------------------------------------------------
| TEAM MEMBER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_team_member(team_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.memberships
        where team_id = team_uuid
        and user_id = auth.uid()
    );
$$;

/*
|--------------------------------------------------------------------------
| TEAM ADMIN CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_team_admin(team_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.memberships
        where team_id = team_uuid
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    );
$$;

/*
|--------------------------------------------------------------------------
| ORGANIZATION MEMBER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_org_member(org_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.memberships
        where organization_id = org_uuid
        and user_id = auth.uid()
    );
$$;

/*
|--------------------------------------------------------------------------
| ORGANIZATION OWNER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_org_owner(org_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.organizations
        where id = org_uuid
        and owner_id = auth.uid()
    );
$$;

/*
|--------------------------------------------------------------------------
| PROJECT MEMBER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_project_member(project_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = project_uuid
        and m.user_id = auth.uid()
    );
$$;

/*
|--------------------------------------------------------------------------
| PROJECT ADMIN CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_project_admin(project_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = project_uuid
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    );
$$;

/*
|--------------------------------------------------------------------------
| TASK MEMBER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_task_member(task_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.tasks t
        join public.projects p
            on p.id = t.project_id
        join public.memberships m
            on m.team_id = p.team_id
        where t.id = task_uuid
        and m.user_id = auth.uid()
    );
$$;

/*
|--------------------------------------------------------------------------
| TASK ADMIN CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_task_admin(task_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.tasks t
        join public.projects p
            on p.id = t.project_id
        join public.memberships m
            on m.team_id = p.team_id
        where t.id = task_uuid
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    );
$$;

/*
|--------------------------------------------------------------------------
| COMMENT OWNER CHECK
|--------------------------------------------------------------------------
*/

create or replace function public.is_comment_owner(comment_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.comments
        where id = comment_uuid
        and author_id = auth.uid()
    );
$$;