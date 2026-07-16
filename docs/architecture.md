# DevCollab Architecture

## Overview
DevCollab is a full-stack, enterprise-grade collaborative task management and team workspace platform built using **Flutter** and **Supabase PostgreSQL & Realtime**.

The system follows a clean multi-layer architecture with feature-driven organization:
- **Presentation Layer**: Riverpod 2.x (`AsyncNotifier`, `StreamProvider`, `StateNotifierProvider`), responsive layouts, glassmorphism dark/light themes.
- **Domain Layer**: Strongly-typed immutable models (`Organization`, `OrganizationMember`, `KanbanProject`, `KanbanTask`, `OrgMessage`, `OrgInvite`, `Profile`).
- **Data Layer**: Clean repositories communicating directly with Supabase Auth, PostgreSQL tables, Storage buckets, and Realtime WebSocket channels.

---

## High-Level System Diagram

```text
User
 ↓
Flutter Application (DevCollab)
 ├── Multi-Account Local Credential Vault (Instagram-style fast account switching)
 ├── Organization & Team Workspace Hub (3-Tab Dynamic Workspace)
 │    ├── Kanban Board & Sprint Tracker (Draggable/clickable tasks, priority tags, due dates)
 │    ├── Real-Time Team Chat & Announcements (Live Supabase WebSocket streaming)
 │    └── Members (MD/MG/EMP/Admin) & Join Code Manager
 └── Interactive Profile & Avatar Editor (Client-side crop/rotate + Supabase Storage)
 ↓
Supabase Services
 ├── Auth (Row-Level Security & Multi-Session capabilities)
 ├── PostgreSQL Database (profiles, organizations, organization_members, projects, tasks, org_messages, org_invites)
 ├── Realtime Channels (PostgreSQL WAL replication for instant chat & task board updates)
 └── Storage Buckets ("profile pics" public bucket with RLS policies)
```

---

## Key Modules Implemented

### 1. Multi-Account Credential Vault & Fast Account Switcher
- Stores encrypted login tokens locally so users who opt to save credentials can tap their saved account card and switch instantly.
- Individual accounts can be removed with a single click.

### 2. Organization Workspace (`OrgWorkspacePage`)
- **Kanban Board & Sprint Tracker**:
  - Filter tasks across `All`, `To Do`, `In Progress`, `Code Review`, and `Done`.
  - Priority levels: `Low`, `Medium`, `High`, `Urgent`.
  - Interactive status transitions and due date tracking.
- **Real-Time Team Chat**:
  - Direct live streams via `org_messages` table.
  - High-priority highlighted **Announcements** for owners and admins.
- **Member & Role Management**:
  - Supports role hierarchy: `OWNER`, `ADMIN`, `MD` (Managing Director), `MG` (Manager), `EMP` (Employee), `MEMBER`.
  - Add members directly by email or share instant join codes (`DEV-XXXXX`).

### 3. Profile & Avatar Editor
- Interactive client-side image cropping and rotation before upload.
- Extended profile attributes: `bio`, `dob`, `job_description`, `current_company`, and private `current_teams` list.
