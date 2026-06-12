# DevCollab RLS Strategy

## Overview

DevCollab uses Supabase Row Level Security (RLS) to enforce multi-tenant data isolation.

Users should only be able to access data belonging to organizations they are members of.

All database tables will have RLS enabled by default.

---

# Security Principles

## Principle 1: Deny By Default

No user should be able to access any data unless explicitly allowed by a policy.

```text
Default Access = Denied
```

---

## Principle 2: Organization Isolation

Users may only access data belonging to organizations where they have active membership.

```text
User
└── Organization Membership
    └── Organization Data
```

A user must never be able to access another organization's:

* Teams
* Projects
* Tasks
* Comments
* Attachments
* Activity Logs

---

## Principle 3: Role-Based Access Control

Permissions are determined by organization roles.

### Owner

Can:

* Manage organization settings
* Manage members
* Manage teams
* Manage projects
* Create tasks
* Update tasks
* Delete tasks
* Access all organization data

---

### Admin

Can:

* Manage teams
* Manage projects
* Create tasks
* Update tasks
* Delete tasks
* View all organization data

Cannot:

* Transfer organization ownership

---

### Member

Can:

* View organization data
* Create tasks
* Update assigned tasks
* Comment on tasks
* Upload attachments

Cannot:

* Manage organization members
* Delete organization resources

---

### Viewer

Can:

* View teams
* View projects
* View tasks
* View comments

Cannot:

* Create tasks
* Edit tasks
* Delete tasks
* Upload files

---

# Table Access Rules

## Profiles

### Read

Authenticated users may read their own profile.

### Update

Users may update their own profile.

### Delete

Not permitted.

---

## Organizations

### Read

Allowed only if user belongs to the organization.

### Create

Any authenticated user may create an organization.

### Update

Owner and Admin only.

### Delete

Owner only.

---

## Organization Members

### Read

Organization members may view membership information.

### Create

Owner and Admin only.

### Update

Owner only.

### Delete

Owner only.

---

## Teams

### Read

Organization members only.

### Create

Owner and Admin only.

### Update

Owner and Admin only.

### Delete

Owner and Admin only.

---

## Team Members

### Read

Team members and organization administrators.

### Create

Owner and Admin only.

### Update

Owner and Admin only.

### Delete

Owner and Admin only.

---

## Projects

### Read

Organization members only.

### Create

Owner, Admin, and Member.

### Update

Owner, Admin, and Project Creator.

### Delete

Owner and Admin only.

---

## Tasks

### Read

Organization members only.

### Create

Owner, Admin, and Member.

### Update

Owner, Admin, Task Creator, or Assigned User.

### Delete

Owner, Admin, or Task Creator.

---

## Comments

### Read

Organization members only.

### Create

Owner, Admin, and Member.

### Update

Comment Author only.

### Delete

Comment Author, Owner, or Admin.

---

## Attachments

### Read

Organization members only.

### Upload

Owner, Admin, and Member.

### Delete

Uploader, Owner, or Admin.

---

## Activity Logs

### Read

Organization members only.

### Create

System generated only.

### Update

Not permitted.

### Delete

Not permitted.

---

# Storage Security

Supabase Storage should follow the same organization-level isolation model.

File path convention:

```text
organizations/
    {organization_id}/
        projects/
            {project_id}/
                attachments/
```

Users should only access files belonging to organizations they are members of.

---

# Realtime Security

Realtime subscriptions must respect RLS policies.

Users may subscribe only to:

* Organizations they belong to
* Teams they belong to
* Projects they can access

Users must never receive events from unrelated organizations.

---

# Future Enhancements

Potential future improvements:

* Project-specific roles
* Team-specific roles
* Custom permission sets
* Guest users
* Temporary access invitations
* Audit approval workflows

---

# Summary

DevCollab follows a security-first architecture:

1. Deny access by default.
2. Isolate all data by organization.
3. Enforce role-based permissions.
4. Protect storage using organization ownership.
5. Apply RLS to every business table.
6. Ensure realtime events respect access policies.

This strategy ensures secure multi-tenant collaboration while maintaining a simple and scalable permission model.
