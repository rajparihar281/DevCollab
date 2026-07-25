# DevCollab Row-Level Security (RLS) Strategy

## Overview
DevCollab uses Supabase Row-Level Security (RLS) across 100% of tables (`profiles`, `organizations`, `organization_members`, `projects`, `tasks`, `org_messages`, `org_invites`) and Storage buckets (`profile pics`).

---

## RLS Policies Summary

### 1. `profiles`
- **SELECT**: Public/Authenticated users can read profiles (`true`).
- **UPDATE / INSERT**: Users can only update or insert their own profile (`auth.uid() = id`).

### 2. `organizations` & `organization_members`
- **SELECT**: Users can read organizations where they are listed in `organization_members` or are the `owner_id`.
- **INSERT**: Any authenticated user can create an organization.
- **DELETE**: Only `owner_id` can delete the organization.

### 3. Collaboration Tables (`projects`, `tasks`, `org_messages`, `org_invites`)
- **SELECT**: Users can select rows where `org_id` exists in their `organization_members` entries.
- **INSERT / UPDATE**: Authenticated members of the organization can insert or modify tasks, messages, and invites.
- **DELETE (`org_invites`)**: Authenticated members or owners can delete invite codes.

### 4. Storage Bucket (`profile pics`)
- **SELECT**: Public read access to all avatars.
- **INSERT / UPDATE**: Authenticated users can upload avatars to their own folder/prefix (`auth.uid()`).
