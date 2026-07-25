-- Migration: Fix Missing Columns and Foreign Keys across Legacy Tables
-- Aligns organizations, teams, projects, tasks, comments, and activity_logs exactly with docs/supabase-schema.md and Dart repositories.

-- 1. ORGANIZATIONS
ALTER TABLE public.organizations ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.organizations ADD COLUMN IF NOT EXISTS updated_at timestamptz not null default now();

DO $$
BEGIN
    ALTER TABLE public.organizations DROP CONSTRAINT IF EXISTS organizations_owner_id_fkey;
    ALTER TABLE public.organizations ADD CONSTRAINT organizations_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 2. TEAMS
ALTER TABLE public.teams ALTER COLUMN created_by DROP NOT NULL;

DO $$
BEGIN
    ALTER TABLE public.teams DROP CONSTRAINT IF EXISTS teams_created_by_fkey;
    ALTER TABLE public.teams ADD CONSTRAINT teams_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 3. PROJECTS
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';
ALTER TABLE public.projects ALTER COLUMN created_by DROP NOT NULL;

-- Backfill organization_id for projects from teams
UPDATE public.projects p
SET organization_id = t.organization_id
FROM public.teams t
WHERE p.team_id = t.id AND p.organization_id IS NULL;

DO $$
BEGIN
    ALTER TABLE public.projects DROP CONSTRAINT IF EXISTS projects_created_by_fkey;
    ALTER TABLE public.projects ADD CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 4. TASKS
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS priority text NOT NULL DEFAULT 'medium';

-- Rename assigned_to to assignee_id if assigned_to exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'assigned_to')
       AND NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'assignee_id') THEN
        ALTER TABLE public.tasks RENAME COLUMN assigned_to TO assignee_id;
    END IF;
END $$;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS assignee_id uuid;

-- Change status column from enum to text so any text value ('todo', 'in_progress', etc.) works cleanly without casting errors
DO $$
BEGIN
    ALTER TABLE public.tasks ALTER COLUMN status TYPE text USING status::text;
    ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'todo';
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- Backfill organization_id for tasks from projects
UPDATE public.tasks tk
SET organization_id = p.organization_id
FROM public.projects p
WHERE tk.project_id = p.id AND tk.organization_id IS NULL;

-- Update foreign keys on tasks for Postgrest embedding
DO $$
BEGIN
    ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_assigned_to_fkey;
    ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_assignee_id_fkey;
    ALTER TABLE public.tasks ADD CONSTRAINT tasks_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

    ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_created_by_fkey;
    ALTER TABLE public.tasks ADD CONSTRAINT tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 5. COMMENTS
-- Rename author_id to user_id if author_id exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'comments' AND column_name = 'author_id')
       AND NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'comments' AND column_name = 'user_id') THEN
        ALTER TABLE public.comments RENAME COLUMN author_id TO user_id;
    END IF;
END $$;

ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS user_id uuid;

DO $$
BEGIN
    ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_author_id_fkey;
    ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_user_id_fkey;
    ALTER TABLE public.comments ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- Recreate comments RLS policies with user_id
drop policy if exists "comment_author_can_update" on public.comments;
create policy "comment_author_can_update"
on public.comments
for update
to authenticated
using (user_id = auth.uid());

drop policy if exists "comment_author_can_delete" on public.comments;
create policy "comment_author_can_delete"
on public.comments
for delete
to authenticated
using (user_id = auth.uid() or exists (
    select 1 from public.tasks tk join public.projects p on p.id = tk.project_id join public.teams tm on tm.id = p.team_id join public.organization_members om on om.organization_id = tm.organization_id where tk.id = comments.task_id and om.user_id = auth.uid() and om.role in ('owner', 'admin')
));

drop policy if exists "comment_members_can_create" on public.comments;
create policy "comment_members_can_create"
on public.comments
for insert
to authenticated
with check (
    user_id = auth.uid() and exists (
        select 1 from public.tasks tk join public.projects p on p.id = tk.project_id join public.teams tm on tm.id = p.team_id where tk.id = comments.task_id and (public.is_team_member(p.team_id) or public.is_org_member(tm.organization_id))
    )
);


-- 6. ACTIVITY LOGS
-- Rename actor_id to user_id if actor_id exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'activity_logs' AND column_name = 'actor_id')
       AND NOT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'activity_logs' AND column_name = 'user_id') THEN
        ALTER TABLE public.activity_logs RENAME COLUMN actor_id TO user_id;
    END IF;
END $$;

ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS user_id uuid;

DO $$
BEGIN
    ALTER TABLE public.activity_logs DROP CONSTRAINT IF EXISTS activity_logs_actor_id_fkey;
    ALTER TABLE public.activity_logs DROP CONSTRAINT IF EXISTS activity_logs_user_id_fkey;
    ALTER TABLE public.activity_logs ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- Recreate activity_logs insert policy with user_id
drop policy if exists "authenticated_users_can_create_logs" on public.activity_logs;
create policy "authenticated_users_can_create_logs"
on public.activity_logs
for insert
to authenticated
with check (
    user_id = auth.uid()
);

-- 7. RE-GRANT PRIVILEGES
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO authenticated, anon, service_role;
