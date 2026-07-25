-- Migration: Add extended profile fields (editable by user) and notification preferences
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS dob date,
  ADD COLUMN IF NOT EXISTS job_title text,
  ADD COLUMN IF NOT EXISTS current_company text,
  ADD COLUMN IF NOT EXISTS teams text[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS notify_task_assigned boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_mention boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_team_message boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_email_digest boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS notify_security_alerts boolean DEFAULT true;

-- Ensure RLS allows user to update their own profile and read their own teams list
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Reload PostgREST schema cache immediately so new columns are recognized
NOTIFY pgrst, 'reload schema';
