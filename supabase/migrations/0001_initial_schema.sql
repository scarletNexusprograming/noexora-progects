create extension if not exists pgcrypto;
create type public.member_role as enum ('admin','project_director','collaborator','observer');
create type public.activity_status as enum ('pending','in_progress','in_review','completed','blocked');
create type public.priority_level as enum ('low','medium','high','critical');

create table public.organizations (
 id uuid primary key default gen_random_uuid(), name text not null check(length(name) between 2 and 160),
 slug text not null unique, created_at timestamptz not null default now(), deleted_at timestamptz
);
create table public.workspaces (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 name text not null check(length(name) between 2 and 120), timezone text not null default 'America/Bogota',
 currency text not null default 'COP', created_at timestamptz not null default now(), deleted_at timestamptz,
 unique(id,organization_id)
);
create table public.memberships (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, user_id uuid not null references auth.users(id) on delete cascade,
 role public.member_role not null default 'collaborator', created_at timestamptz not null default now(),
 unique(workspace_id,user_id),
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.projects (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, name text not null check(length(name) between 3 and 120),
 description text not null default '', objective text not null default '',
 director_id uuid references auth.users(id), status text not null default 'active' check(status in ('draft','active','on_hold','completed','cancelled')),
 priority public.priority_level not null default 'medium', start_date date not null, end_date date not null,
 budget numeric(16,2) not null default 0 check(budget>=0), cost_actual numeric(16,2) not null default 0 check(cost_actual>=0),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), updated_by uuid references auth.users(id), version integer not null default 1,
 deleted_at timestamptz, check(end_date>=start_date),
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.phases (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, project_id uuid not null references public.projects(id),
 name text not null, position integer not null default 0, start_date date, end_date date, created_at timestamptz default now(),
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id),
 check(start_date is null or end_date is null or end_date>=start_date)
);
create table public.goals (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, project_id uuid not null references public.projects(id),
 title text not null, description text not null default '', indicator text not null, unit text not null,
 baseline numeric not null, target numeric not null, current_value numeric not null,
 direction text not null check(direction in ('increase','decrease')), due_date date not null,
 weight numeric not null default 1 check(weight>0 and weight<=100),
 owner_id uuid references auth.users(id), created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version integer not null default 1, deleted_at timestamptz,
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.activities (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, project_id uuid not null references public.projects(id),
 phase_id uuid references public.phases(id), goal_id uuid references public.goals(id),
 title text not null, description text not null default '', assignee_id uuid references auth.users(id),
 status public.activity_status not null default 'pending', priority public.priority_level not null default 'medium',
 start_date date not null, due_date date not null, completed_at timestamptz,
 progress numeric not null default 0 check(progress between 0 and 100),
 estimated_hours numeric not null default 0 check(estimated_hours>=0), actual_hours numeric not null default 0 check(actual_hours>=0),
 weight numeric not null default 1 check(weight>0 and weight<=100),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), updated_by uuid references auth.users(id), version integer not null default 1,
 deleted_at timestamptz, check(due_date>=start_date),
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.activity_collaborators (
 activity_id uuid references public.activities(id) on delete cascade, user_id uuid references auth.users(id) on delete cascade,
 primary key(activity_id,user_id)
);
create table public.activity_dependencies (
 activity_id uuid references public.activities(id) on delete cascade,
 depends_on_id uuid references public.activities(id) on delete cascade,
 created_at timestamptz default now(), primary key(activity_id,depends_on_id), check(activity_id<>depends_on_id)
);
create table public.documents (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, project_id uuid not null references public.projects(id),
 activity_id uuid references public.activities(id), storage_path text not null unique,
 name text not null, mime_type text not null, size_bytes bigint not null check(size_bytes between 1 and 8388608),
 uploaded_by uuid not null references auth.users(id), version integer not null default 1,
 created_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.comments (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 workspace_id uuid not null, activity_id uuid not null references public.activities(id),
 author_id uuid not null references auth.users(id), body text not null check(length(body) between 1 and 5000),
 created_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(workspace_id,organization_id) references public.workspaces(id,organization_id)
);
create table public.activity_events (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 activity_id uuid not null references public.activities(id), actor_id uuid not null references auth.users(id),
 event_type text not null, payload jsonb not null default '{}', created_at timestamptz not null default now()
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 user_id uuid not null references auth.users(id), title text not null, body text not null,
 read_at timestamptz, created_at timestamptz not null default now()
);

create index projects_workspace_active_idx on public.projects(workspace_id,created_at desc) where deleted_at is null;
create index activities_workspace_due_idx on public.activities(workspace_id,due_date) where deleted_at is null;
create index activities_project_status_idx on public.activities(project_id,status) where deleted_at is null;
create index activities_assignee_idx on public.activities(assignee_id,due_date) where deleted_at is null;
create index goals_project_idx on public.goals(project_id) where deleted_at is null;
create index documents_project_idx on public.documents(project_id,created_at desc) where deleted_at is null;
create index events_activity_created_idx on public.activity_events(activity_id,created_at desc);

create or replace function public.prevent_activity_dependency_cycles()
returns trigger language plpgsql as $$
declare has_cycle boolean;
begin
 with recursive reach(id) as (
  select new.depends_on_id
  union
  select d.depends_on_id from public.activity_dependencies d join reach r on d.activity_id=r.id
 )
 select exists(select 1 from reach where id=new.activity_id) into has_cycle;
 if has_cycle then raise exception 'La dependencia genera un ciclo'; end if;
 return new;
end $$;
create trigger activity_dependency_cycle_check before insert or update on public.activity_dependencies
for each row execute function public.prevent_activity_dependency_cycles();

create or replace function public.enforce_activity_completion()
returns trigger language plpgsql as $$
begin
 if new.status='completed' then new.progress=100; new.completed_at=coalesce(new.completed_at,now());
 elsif old.status='completed' and new.status<>'completed' then new.completed_at=null;
 end if;
 if new.due_date<new.start_date then raise exception 'La fecha de vencimiento no puede preceder al inicio'; end if;
 return new;
end $$;
create trigger activity_completion_guard before update or insert on public.activities
for each row execute function public.enforce_activity_completion();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create trigger projects_touch before update on public.projects for each row execute function public.touch_updated_at();
create trigger goals_touch before update on public.goals for each row execute function public.touch_updated_at();
create trigger activities_touch before update on public.activities for each row execute function public.touch_updated_at();

alter publication supabase_realtime add table public.activities;
alter publication supabase_realtime add table public.comments;
alter publication supabase_realtime add table public.notifications;
