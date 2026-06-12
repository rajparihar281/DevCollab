/*
|--------------------------------------------------------------------------
| ORGANIZATIONS
|--------------------------------------------------------------------------
*/

create policy "organization_members_can_view"
on public.organizations
for select
to authenticated
using (
    owner_id = auth.uid()
    or exists (
        select 1
        from public.memberships m
        where m.organization_id = organizations.id
        and m.user_id = auth.uid()
    )
);

create policy "organization_owners_can_update"
on public.organizations
for update
to authenticated
using (
    owner_id = auth.uid()
);

create policy "authenticated_users_can_create_organizations"
on public.organizations
for insert
to authenticated
with check (
    owner_id = auth.uid()
);

create policy "organization_owners_can_delete"
on public.organizations
for delete
to authenticated
using (
    owner_id = auth.uid()
);

/*
|--------------------------------------------------------------------------
| TEAMS
|--------------------------------------------------------------------------
*/

create policy "team_members_can_view"
on public.teams
for select
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.team_id = teams.id
        and m.user_id = auth.uid()
    )
);

create policy "team_admins_can_modify"
on public.teams
for update
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.team_id = teams.id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

create policy "team_admins_can_delete"
on public.teams
for delete
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.team_id = teams.id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

create policy "organization_members_can_create_teams"
on public.teams
for insert
to authenticated
with check (
    exists (
        select 1
        from public.memberships m
        where m.organization_id = teams.organization_id
        and m.user_id = auth.uid()
    )
);

/*
|--------------------------------------------------------------------------
| PROJECTS
|--------------------------------------------------------------------------
*/

create policy "project_team_members_can_view"
on public.projects
for select
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        join public.teams t on t.id = projects.team_id
        where m.team_id = t.id
        and m.user_id = auth.uid()
    )
);

create policy "project_team_members_can_create"
on public.projects
for insert
to authenticated
with check (
    exists (
        select 1
        from public.memberships m
        where m.team_id = projects.team_id
        and m.user_id = auth.uid()
    )
);

create policy "project_admins_can_modify"
on public.projects
for update
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.team_id = projects.team_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

create policy "project_admins_can_delete"
on public.projects
for delete
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.team_id = projects.team_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

/*
|--------------------------------------------------------------------------
| TASKS
|--------------------------------------------------------------------------
*/

create policy "task_team_members_can_view"
on public.tasks
for select
to authenticated
using (
    exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = tasks.project_id
        and m.user_id = auth.uid()
    )
);

create policy "task_team_members_can_create"
on public.tasks
for insert
to authenticated
with check (
    exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = tasks.project_id
        and m.user_id = auth.uid()
    )
);

create policy "task_team_members_can_update"
on public.tasks
for update
to authenticated
using (
    exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = tasks.project_id
        and m.user_id = auth.uid()
    )
);

create policy "task_admins_can_delete"
on public.tasks
for delete
to authenticated
using (
    exists (
        select 1
        from public.projects p
        join public.memberships m
            on m.team_id = p.team_id
        where p.id = tasks.project_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
);

/*
|--------------------------------------------------------------------------
| COMMENTS
|--------------------------------------------------------------------------
*/

create policy "comment_members_can_view"
on public.comments
for select
to authenticated
using (
    exists (
        select 1
        from public.tasks t
        join public.projects p on p.id = t.project_id
        join public.memberships m on m.team_id = p.team_id
        where t.id = comments.task_id
        and m.user_id = auth.uid()
    )
);

create policy "comment_members_can_create"
on public.comments
for insert
to authenticated
with check (
    author_id = auth.uid()
);

create policy "comment_author_can_update"
on public.comments
for update
to authenticated
using (
    author_id = auth.uid()
);

create policy "comment_author_can_delete"
on public.comments
for delete
to authenticated
using (
    author_id = auth.uid()
);

/*
|--------------------------------------------------------------------------
| MEMBERSHIPS
|--------------------------------------------------------------------------
*/

create policy "members_can_view_memberships"
on public.memberships
for select
to authenticated
using (
    user_id = auth.uid()
    or exists (
        select 1
        from public.memberships m
        where m.team_id = memberships.team_id
        and m.user_id = auth.uid()
    )
);

/*
|--------------------------------------------------------------------------
| ACTIVITY LOGS
|--------------------------------------------------------------------------
*/

create policy "members_can_view_activity_logs"
on public.activity_logs
for select
to authenticated
using (
    exists (
        select 1
        from public.memberships m
        where m.organization_id = activity_logs.organization_id
        and m.user_id = auth.uid()
    )
);