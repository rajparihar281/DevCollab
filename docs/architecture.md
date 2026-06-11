# DevCollab Architecture
## Overview

DevCollab is a full-stack collaborative task management platforms built using Flutter and Supabase.

The System follows a client-server architecture where Flutter serves as the client application and Supabase proviedes authentication, database, realtime communication, and files storage services.

# High-Level Architecture

```text
User
↓
Flutter Application
↓
Supabase Services
├── Auth
├── PostgreSQL Database
├── Realtime Channels
└── Storage
↓
Other Connected Clients
```
## Frontend Layer
- **Flutter**

  Responsible for:
  - User Interface
  - Navigation
  - State Management
  - Offline Data Handling
  - Deep Linking 
 ## Local Storage
 
 Used for:

 - Offline queue
 - Cachced data
 - Temporary synchronization state

 Techology:

 - Drift
 - Hive

 ## Backend Layer
 ## Supabase Auth

 Responsible for:
 - Organizations
 - Teams
 - Projects
 - Tasks
 - Comments
 - Acitivty Logs

 ## Supabase Realtime

 Responsible for:

 - Task updates
 - Comment synchronization
 - Board synchronization
 - Team Chat Events

 ## Supabase Storage

 Responsible for:
 - File uploads
 - File downloads
 - Attachment management

 ## Multi-Tenant Design

 Data is isolated at the organization level.
```text
Organization
└── Teams
└── Projects
└── Tasks
```
Row Level Security (RLS) ensures users can only access data belonging to organizations they are members of.


## Realtime Flow
```text 
User A updates a task
↓
PostgreSQL Update
↓
Supabase Realtime Event
↓
User B receives update instantly
```

## Offline Strategy

Changes created while offline are stored locally
1. Local changes are queued.
2. Queue is synchronized with supabase.
3. Realtime updates refresh connected clients.

## Security 
- Supabase Authentication
- Row Level Security (RLS)
- Organization-based access control
- Role-based permissions
- Secure file access policies
