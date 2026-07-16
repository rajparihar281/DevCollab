# DevCollab Database Design & Entity Dictionary

## Overview
DevCollab follows a multi-tenant relational schema scoped by organizations. Every table adheres to Row-Level Security (RLS) policies guaranteeing strict tenant isolation.

---

## 1. Profiles (`profiles`)
Stores user identity, avatar references, and professional background details.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | User ID (references `auth.users.id`) |
| `full_name` | TEXT | Display name / username |
| `avatar_url` | TEXT | URL or storage path in `"profile pics"` bucket |
| `bio` | TEXT | Short biography |
| `dob` | DATE | Date of birth |
| `job_description` | TEXT | Role title / profession |
| `current_company` | TEXT | Company name |
| `current_teams` | TEXT[] | Private array of team names |
| `created_at` / `updated_at` | TIMESTAMPTZ | Record timestamps |

---

## 2. Organizations (`organizations`)
Represents a team workspace or startup organization.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `name` | TEXT | Organization name |
| `description` | TEXT | Workspace description |
| `owner_id` | UUID | References `auth.users(id)` |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

---

## 3. Organization Members (`organization_members`)
Associates users with organizations and assigns hierarchical roles.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `organization_id` | UUID | References `organizations.id` |
| `user_id` | UUID | References `profiles.id` |
| `role` | TEXT | `'owner'`, `'admin'`, `'md'`, `'mg'`, `'emp'`, `'member'` |
| `joined_at` | TIMESTAMPTZ | Joining timestamp |

---

## 4. Projects (`projects`)
Sprint projects inside an organization.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `org_id` | UUID | References `organizations.id` |
| `title` | TEXT | Project title |
| `description` | TEXT | Project goals |
| `created_by` | UUID | References creator ID |

---

## 5. Tasks (`tasks`)
Kanban sprint work items.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `org_id` | UUID | References `organizations.id` |
| `project_id` | UUID | Optional project reference |
| `title` | TEXT | Task summary |
| `description` | TEXT | Detailed specification |
| `status` | TEXT | `'todo'`, `'in_progress'`, `'code_review'`, `'done'` |
| `priority` | TEXT | `'low'`, `'medium'`, `'high'`, `'urgent'` |
| `assignee_id` | TEXT | User ID assigned to task |
| `assignee_name` | TEXT | Assignee display name |
| `due_date` | DATE | Calendar due date |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

---

## 6. Real-Time Chat Messages (`org_messages`)
Streamed collaboration messages.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `org_id` | UUID | References `organizations.id` |
| `user_id` | UUID | Sender user ID |
| `user_name` | TEXT | Sender name |
| `content` | TEXT | Message body |
| `is_announcement` | BOOLEAN | Highlights pinned announcement messages |
| `created_at` | TIMESTAMPTZ | Send timestamp |

---

## 7. Organization Invites (`org_invites`)
Shareable join codes.

| Column | Type | Description |
| --- | --- | --- |
| `id` | UUID | Primary Key |
| `org_id` | UUID | References `organizations.id` |
| `invite_code` | TEXT | Unique code (`DEV-XXXXX`) |
| `role` | TEXT | Role assigned upon joining |
