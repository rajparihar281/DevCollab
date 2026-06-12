# DevCollab Supabase Schema

## Overview

DevCollab uses a multi-tenant database architecture where organizations own teams, teams own projects, and projects contain tasks. Data isolation is enforced using Row Level Security (RLS) policies based on organization membership.

---

# Profiles

Stores user profile information linked to Supabase Authentication.

```text
profiles
-------------
id uuid primary key
full_name text not null
avatar_url text
created_at timestamptz not null
updated_at timestamptz not null
```

---

# Organizations

Represents a company, startup, or group using DevCollab.

```text
organizations
-------------
id uuid primary key
name text not null
description text
owner_id uuid references profiles(id)
created_at timestamptz not null
updated_at timestamptz not null
```

---

# Organization Members

Stores organization membership and roles.

```text
organization_members
-------------
id uuid primary key
organization_id uuid references organizations(id)
user_id uuid references profiles(id)
role text not null
joined_at timestamptz not null
```

### Supported Roles

```text
owner
admin
member
viewer
```

---

# Teams

Represents groups within an organization.

```text
teams
-------------
id uuid primary key
organization_id uuid references organizations(id)
name text not null
description text
created_at timestamptz not null
updated_at timestamptz not null
```

---

# Team Members

Stores team membership information.

```text
team_members
-------------
id uuid primary key
team_id uuid references teams(id)
user_id uuid references profiles(id)
joined_at timestamptz not null
```

---

# Projects

Represents projects managed by teams.

```text
projects
-------------
id uuid primary key
organization_id uuid references organizations(id)
team_id uuid references teams(id)
name text not null
description text
status text not null
created_by uuid references profiles(id)
created_at timestamptz not null
updated_at timestamptz not null
```

### Supported Statuses

```text
active
archived
```

---

# Tasks

Represents work items displayed on the Kanban board.

```text
tasks
-------------
id uuid primary key
organization_id uuid references organizations(id)
project_id uuid references projects(id)
title text not null
description text
status text not null
priority text not null
assignee_id uuid references profiles(id)
created_by uuid references profiles(id)
due_date timestamptz
position integer
created_at timestamptz not null
updated_at timestamptz not null
```

### Supported Statuses

```text
todo
in_progress
review
done
```

### Supported Priorities

```text
low
medium
high
critical
```

---

# Comments

Stores task discussions.

```text
comments
-------------
id uuid primary key
task_id uuid references tasks(id)
user_id uuid references profiles(id)
content text not null
created_at timestamptz not null
updated_at timestamptz not null
```

---

# Attachments

Stores files uploaded to tasks.

```text
attachments
-------------
id uuid primary key
task_id uuid references tasks(id)
uploaded_by uuid references profiles(id)
file_name text not null
file_path text not null
file_size bigint
uploaded_at timestamptz not null
```

---

# Activity Logs

Tracks important user actions for auditing and collaboration.

```text
activity_logs
-------------
id uuid primary key
organization_id uuid references organizations(id)
user_id uuid references profiles(id)
entity_type text not null
entity_id uuid not null
action text not null
metadata jsonb
created_at timestamptz not null
```

---

# Relationships

```text
Organization
├── Organization Members
├── Teams
│   ├── Team Members
│   └── Projects
│       └── Tasks
│           ├── Comments
│           ├── Attachments
│           └── Activity Logs
└── Activity Logs
```

```text
User
├── Organization Memberships
├── Team Memberships
├── Created Projects
├── Assigned Tasks
├── Comments
└── Activity Logs
```

---

# Multi-Tenant Strategy

Every business entity is scoped to an organization.

```text
Organization
└── Team
    └── Project
        └── Task
```

This structure enables:

* Organization-level data isolation
* Row Level Security (RLS)
* Secure multi-tenant access control
* Efficient permission management

Only users who belong to an organization may access its resources.

---

# Future Enhancements

The following entities may be introduced in later versions:

* Team Chat Messages
* Notifications
* User Preferences
* Activity Feed Aggregations
* Audit Events
* Workspace Settings
* Project Templates

```
```
