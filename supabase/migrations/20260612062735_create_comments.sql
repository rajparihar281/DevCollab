create table public.comments (
    id uuid primary key default gen_random_uuid(),

    task_id uuid not null
        references public.tasks(id)
        on delete cascade,

    author_id uuid not null
        references auth.users(id),

    content text not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_comments_task
on public.comments(task_id);