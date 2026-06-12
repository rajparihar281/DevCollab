create type task_status as enum (
    'todo',
    'in_progress',
    'review',
    'done'
);

create table public.tasks (
    id uuid primary key default gen_random_uuid(),

    project_id uuid not null
        references public.projects(id)
        on delete cascade,

    title text not null,
    description text,

    status task_status not null default 'todo',

    assigned_to uuid
        references auth.users(id),

    created_by uuid not null
        references auth.users(id),

    due_date timestamptz,

    position integer not null default 0,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_tasks_project
on public.tasks(project_id);

create index idx_tasks_assigned_to
on public.tasks(assigned_to);

create index idx_tasks_status
on public.tasks(status);