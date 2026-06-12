-- organizations
alter table public.organizations
enable row level security;

-- teams
alter table public.teams
enable row level security;

-- projects
alter table public.projects
enable row level security;

-- tasks
alter table public.tasks
enable row level security;

-- comments
alter table public.comments
enable row level security;

-- memberships
alter table public.memberships
enable row level security;

-- activity_logs
alter table public.activity_logs
enable row level security;