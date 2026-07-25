-- Migration: Collaboration Modules (Kanban Board, Real-Time Team Chat, Member Invites & Join Codes)
-- Date: 2026-07-10

-- =========================================================
-- 1. PROJECTS TABLE (Kanban Projects inside Organization)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated access to projects"
ON public.projects
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- =========================================================
-- 2. TASKS TABLE (Kanban Tasks inside Project/Org)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'todo',       -- 'todo', 'in_progress', 'code_review', 'done'
  priority TEXT NOT NULL DEFAULT 'medium',   -- 'low', 'medium', 'high', 'urgent'
  assignee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  assignee_name TEXT,
  assignee_avatar TEXT,
  due_date DATE,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated access to tasks"
ON public.tasks
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- =========================================================
-- 3. ORG_MESSAGES TABLE (Real-Time Chat & Announcements)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.org_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_name TEXT NOT NULL,
  user_avatar TEXT,
  content TEXT NOT NULL,
  is_announcement BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.org_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated access to org_messages"
ON public.org_messages
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- =========================================================
-- 4. ORG_INVITES TABLE (Shareable Join Codes & Invites)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.org_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL,          -- e.g., 'DEV-89A4B1'
  role TEXT NOT NULL DEFAULT 'member',       -- 'admin', 'member'
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.org_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated access to org_invites"
ON public.org_invites
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- =========================================================
-- 5. ENABLE SUPABASE REALTIME STREAMING
-- =========================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.org_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
