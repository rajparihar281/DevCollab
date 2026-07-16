# DevCollab Functional & System Requirements

## Problem Statement
Modern teams often use multiple tools for task management, communication, file sharing, and project tracking. DevCollab provides a centralized collaborative workspace where teams manage projects, track tasks, communicate, and collaborate in real time.

---

## Core Features Implemented

### 1. Authentication & Multi-Account Management
- User registration and login via Supabase Auth.
- **Instagram-style Saved Credentials Vault**: Users can opt to save credentials locally upon login to enable 1-click account switching without re-entering passwords.
- Option to remove saved accounts directly from account switcher cards.

### 2. Organization & Workspace Management
- Create organizations and access dynamic 3-tab workspaces (`OrgWorkspacePage`).
- **Kanban Task Board & Sprint Tracker**:
  - Filter tasks by `All`, `To Do`, `In Progress`, `Code Review`, and `Done`.
  - Assign priority levels (`Low`, `Medium`, `High`, `Urgent`) and due dates.
  - Interactive status transition menus.
- **Real-Time Team Chat & Announcements**:
  - Live team chat room powered by Supabase Realtime WebSocket streams.
  - Announcement broadcasting with highlighted badges for leaders.
- **Member Hierarchy & Invite Code Management**:
  - Role hierarchy: `OWNER`, `ADMIN`, `MD`, `MG`, `EMP`, `MEMBER`.
  - Direct member invitation dialog (`AddOrganizationMemberDialog`).
  - Shareable join code generation (`DEV-XXXXX`) and instant join modal.
  - Ability to delete/revoke invite codes.

### 3. Profile & Avatar Management
- Custom avatar upload to Supabase Storage `"profile pics"` bucket with interactive cropping and rotation.
- Editable rich fields: `bio`, `dob`, `job_description`, `current_company`, and private `current_teams` list.