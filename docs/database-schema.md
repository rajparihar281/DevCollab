# DevCollab Database Schema

## Overview

DevCollab uses a multi-tenant database structure where organizations own teams, teams own projects, and projects contain tasks.

# Entities
 - **Profiles**
 
   Represents authenticated users of the platform.
 - **Organizations**

   Represents a company, startup, or group using DevCollab.
 - **Organization Members**
     
    Stores membership and roles within an organization.

- **Teams** 

    Groups of users inside an organization.

- **Projects**
 

    Represents a project managed by a team.

 - **Tasks**

    Represents work items within a project.

- **Comments**

    Represents discussions attached to tasks.

- **Attachments**

     Represents files uploaded to tasks.
    
- **Activity Logs**

     Stores important actions performed within the platform.

## Relationships


```text
Organization
└── Teams
    └── Projects
        └── Tasks
            ├── Comments
            ├── Attachments
            └── Activity Logs


Organization
└── Members

Team
└── Members