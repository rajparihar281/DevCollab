# DevCollab Database Design

## Overview

DevCollab follows a multi-tenant architecture where organizations own teams, teams own projects, and projects contain tasks. All application data is scoped to an organization to ensure proper tenant isolation and secure access control.

---

## Profiles

Stores user profile information linked to Supabase Authentication.

| Column     | Type      | Description                             |
| ---------- | --------- | --------------------------------------- |
| id         | UUID      | User identifier (matches auth.users.id) |
| full_name  | TEXT      | User display name                       |
| avatar_url | TEXT      | Profile image URL                       |
| created_at | TIMESTAMP | Profile creation timestamp              |
| updated_at | TIMESTAMP | Last update timestamp                   |

---

## Organizations

Represents a company, startup, or group using DevCollab.

| Column      | Type      | Description              |
| ----------- | --------- | ------------------------ |
| id          | UUID      | Organization identifier  |
| name        | TEXT      | Organization name        |
| description | TEXT      | Organization description |
| owner_id    | UUID      | Organization creator     |
| created_at  | TIMESTAMP | Creation timestamp       |
| updated_at  | TIMESTAMP | Last update timestamp    |

---

## Organization Members

Maps users to organizations and stores their roles.

| Column          | Type      | Description                  |
| --------------- | --------- | ---------------------------- |
| id              | UUID      | Membership identifier        |
| organization_id | UUID      | Related organization         |
| user_id         | UUID      | Related user                 |
| role            | TEXT      | owner, admin, member, viewer |
| joined_at       | TIMESTAMP | Join timestamp               |

---

## Teams

Represents groups inside an organization.

| Column          | Type      | Description           |
| --------------- | --------- | --------------------- |
| id              | UUID      | Team identifier       |
| organization_id | UUID      | Parent organization   |
| name            | TEXT      | Team name             |
| description     | TEXT      | Team description      |
| created_at      | TIMESTAMP | Creation timestamp    |
| updated_at      | TIMESTAMP | Last update timestamp |

---

## Team Members

Maps users to teams.

| Column    | Type      | Description           |
| --------- | --------- | --------------------- |
| id        | UUID      | Membership identifier |
| team_id   | UUID      | Team identifier       |
| user_id   | UUID      | User identifier       |
| joined_at | TIMESTAMP | Join timestamp        |

---

## Projects

Represents workspaces managed by teams.

| Column          | Type      | Description           |
| --------------- | --------- | --------------------- |
| id              | UUID      | Project identifier    |
| organization_id | UUID      | Parent organization   |
| team_id         | UUID      | Parent team           |
| name            | TEXT      | Project name          |
| description     | TEXT      | Project description   |
| status          | TEXT      | active, archived      |
| created_by      | UUID      | Creator               |
| created_at      | TIMESTAMP | Creation timestamp    |
| updated_at      | TIMESTAMP | Last update timestamp |

---

## Tasks

Represents work items displayed on the Kanban board.

| Column          | Type      | Description                     |
| --------------- | --------- | ------------------------------- |
| id              | UUID      | Task identifier                 |
| organization_id | UUID      | Parent organization             |
| project_id      | UUID      | Parent project                  |
| title           | TEXT      | Task title                      |
| description     | TEXT      | Task details                    |
| status          | TEXT      | todo, in_progress, review, done |
| priority        | TEXT      | low, medium, high, critical     |
| assignee_id     | UUID      | Assigned user                   |
| created_by      | UUID      | Task creator                    |
| due_date        | TIMESTAMP | Due date                        |
| position        | INTEGER   | Board ordering                  |
| created_at      | TIMESTAMP | Creation timestamp              |
| updated_at      | TIMESTAMP | Last update timestamp           |

---

## Comments

Stores task discussions.

| Column     | Type      | Description           |
| ---------- | --------- | --------------------- |
| id         | UUID      | Comment identifier    |
| task_id    | UUID      | Related task          |
| user_id    | UUID      | Comment author        |
| content    | TEXT      | Comment text          |
| created_at | TIMESTAMP | Creation timestamp    |
| updated_at | TIMESTAMP | Last update timestamp |

---

## Attachments

Stores uploaded files linked to tasks.

| Column      | Type      | Description           |
| ----------- | --------- | --------------------- |
| id          | UUID      | Attachment identifier |
| task_id     | UUID      | Related task          |
| uploaded_by | UUID      | User who uploaded     |
| file_name   | TEXT      | Original file name    |
| file_path   | TEXT      | Storage path          |
| file_size   | BIGINT    | File size             |
| uploaded_at | TIMESTAMP | Upload timestamp      |

---

## Activity Logs

Tracks important events for auditing and collaboration.

| Column          | Type      | Description                  |
| --------------- | --------- | ---------------------------- |
| id              | UUID      | Activity identifier          |
| organization_id | UUID      | Related organization         |
| user_id         | UUID      | User performing action       |
| entity_type     | TEXT      | project, task, comment, etc. |
| entity_id       | UUID      | Related entity               |
| action          | TEXT      | create, update, delete, move |
| metadata        | JSONB     | Additional event details     |
| created_at      | TIMESTAMP | Event timestamp              |

---
```
## Relationships

Organization
├── Organization Members
├── Teams
│   └── Team Members
├── Projects
│   └── Tasks
│       ├── Comments
│       ├── Attachments
│       └── Activity Logs
└── Activity Logs

User
├── Organization Memberships
├── Team Memberships
├── Assigned Tasks
├── Comments
└── Activity Logs
```
---

## Multi-Tenant Strategy

Every major business entity contains an organization reference.

This allows:

* Row Level Security (RLS)
* Organization-based isolation
* Secure multi-tenant access control
* Simplified permission checks

All queries should be restricted to organizations the authenticated user belongs to.
