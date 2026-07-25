# DevCollab Database Schema

## Overview
DevCollab uses a multi-tenant PostgreSQL database structure in Supabase where organizations manage members, projects, sprint tasks, real-time chat channels, and shareable join codes.

---

## Core Entities & Tables

### 1. `profiles`
Represents authenticated users of the platform.
- `id` (UUID, Primary Key, references `auth.users`)
- `full_name` / `username` (TEXT)
- `avatar_url` (TEXT, points to Supabase Storage bucket `"profile pics"`)
- `bio` (TEXT)
- `dob` (DATE)
- `job_description` (TEXT)
- `current_company` (TEXT)
- `current_teams` (TEXT[], private array visible only to user)
- `created_at` / `updated_at` (TIMESTAMPTZ)

### 2. `organizations`
Represents a company or startup workspace.
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `description` (TEXT)
- `owner_id` (UUID, references `auth.users`)
- `created_at` (TIMESTAMPTZ)

### 3. `organization_members`
Stores membership and roles within an organization.
- `id` (UUID, Primary Key)
- `organization_id` (UUID, references `organizations`)
- `user_id` (UUID, references `profiles`)
- `role` (TEXT: `'owner'`, `'admin'`, `'md'`, `'mg'`, `'emp'`, `'member'`)
- `joined_at` (TIMESTAMPTZ)

### 4. `projects`
Kanban sprint projects inside an organization.
- `id` (UUID, Primary Key)
- `org_id` (UUID, references `organizations`)
- `title` (TEXT)
- `description` (TEXT)
- `created_by` (UUID)
- `created_at` (TIMESTAMPTZ)

### 5. `tasks`
Sprint work items inside an organization/project.
- `id` (UUID, Primary Key)
- `org_id` (UUID, references `organizations`)
- `project_id` (UUID, references `projects`, optional)
- `title` (TEXT)
- `description` (TEXT)
- `status` (TEXT: `'todo'`, `'in_progress'`, `'code_review'`, `'done'`)
- `priority` (TEXT: `'low'`, `'medium'`, `'high'`, `'urgent'`)
- `assignee_id`, `assignee_name`, `assignee_avatar` (TEXT)
- `due_date` (DATE)
- `created_at` (TIMESTAMPTZ)

### 6. `org_messages`
Real-time collaboration chat channel messages.
- `id` (UUID, Primary Key)
- `org_id` (UUID, references `organizations`)
- `user_id` (UUID, references `profiles`)
- `user_name` / `user_avatar` (TEXT)
- `content` (TEXT)
- `is_announcement` (BOOLEAN)
- `created_at` (TIMESTAMPTZ)

### 7. `org_invites`
Shareable join codes for rapid onboarding.
- `id` (UUID, Primary Key)
- `org_id` (UUID, references `organizations`)
- `invite_code` (TEXT, unique, e.g. `'DEV-12345'`)
- `role` (TEXT)
- `created_at` (TIMESTAMPTZ)