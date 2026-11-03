-- Inicialización automática del espacio personal al crear una cuenta.
create or replace function public.handle_new_user_personal_workspace()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  org_id uuid;
  workspace_id uuid;
  display_name text;
begin
  display_name := coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), split_part(coalesce(new.email, 'Usuario'), '@', 1));
  insert into public.organizations(name, slug)
  values (left(display_name || ' · Personal', 160), 'personal-' || replace(new.id::text, '-', ''))
  returning id into org_id;
  insert into public.workspaces(organization_id, name, timezone, currency)
  values (org_id, 'Mi espacio de trabajo', 'America/Bogota', 'COP')
  returning id into workspace_id;
  insert into public.memberships(organization_id, workspace_id, user_id, role)
  values (org_id, workspace_id, new.id, 'admin');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_personal_workspace on auth.users;
create trigger on_auth_user_created_personal_workspace
after insert on auth.users
for each row execute procedure public.handle_new_user_personal_workspace();

-- Subactividades: una actividad puede depender jerárquicamente de otra.
alter table public.activities
  add column if not exists parent_activity_id uuid references public.activities(id) on delete set null;
create index if not exists activities_parent_idx on public.activities(parent_activity_id) where parent_activity_id is not null;

-- Impide dependencias entre espacios distintos y conserva el grafo acíclico.
create or replace function public.validate_activity_dependency_workspace()
returns trigger language plpgsql as $$
declare
  a_workspace uuid;
  b_workspace uuid;
begin
  select workspace_id into a_workspace from public.activities where id = new.activity_id;
  select workspace_id into b_workspace from public.activities where id = new.depends_on_id;
  if a_workspace is null or b_workspace is null or a_workspace <> b_workspace then
    raise exception 'Las actividades relacionadas deben pertenecer al mismo espacio de trabajo';
  end if;
  return new;
end;
$$;
drop trigger if exists activity_dependency_workspace_check on public.activity_dependencies;
create trigger activity_dependency_workspace_check
before insert or update on public.activity_dependencies
for each row execute function public.validate_activity_dependency_workspace();

-- Bucket privado de evidencias y documentos.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('project-files', 'project-files', false, 8388608,
  array['application/pdf','image/png','image/jpeg','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do update set public = false, file_size_limit = 8388608, allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.validate_project_child_scope()
returns trigger language plpgsql as $$
declare
  p_workspace uuid;
  p_org uuid;
  p_project uuid;
  g_workspace uuid;
  g_project uuid;
  parent_workspace uuid;
  parent_project uuid;
begin
  if tg_table_name = 'goals' then
    select workspace_id, organization_id into p_workspace, p_org from public.projects where id = new.project_id;
    if p_workspace is null or p_workspace <> new.workspace_id or p_org <> new.organization_id then
      raise exception 'El objetivo y su proyecto deben pertenecer al mismo espacio';
    end if;
    return new;
  elsif tg_table_name = 'activities' then
    select workspace_id, organization_id into p_workspace, p_org from public.projects where id = new.project_id;
    if p_workspace is null or p_workspace <> new.workspace_id or p_org <> new.organization_id then
      raise exception 'La actividad y su proyecto deben pertenecer al mismo espacio';
    end if;
    if new.goal_id is not null then
      select workspace_id, project_id into g_workspace, g_project from public.goals where id = new.goal_id;
      if g_workspace is distinct from new.workspace_id or g_project is distinct from new.project_id then
        raise exception 'El objetivo asociado debe pertenecer al mismo proyecto';
      end if;
    end if;
    if new.parent_activity_id is not null then
      select workspace_id, project_id into parent_workspace, parent_project from public.activities where id = new.parent_activity_id;
      if parent_workspace is distinct from new.workspace_id or parent_project is distinct from new.project_id then
        raise exception 'La actividad principal debe pertenecer al mismo proyecto';
      end if;
    end if;
    return new;
  end if;
  return new;
end;
$$;
drop trigger if exists goals_scope_guard on public.goals;
create trigger goals_scope_guard before insert or update on public.goals for each row execute function public.validate_project_child_scope();
drop trigger if exists activities_scope_guard on public.activities;
create trigger activities_scope_guard before insert or update on public.activities for each row execute function public.validate_project_child_scope();

create or replace function public.validate_document_scope()
returns trigger language plpgsql as $$
declare
  p_workspace uuid;
  p_org uuid;
  a_workspace uuid;
  a_project uuid;
begin
  select workspace_id, organization_id into p_workspace, p_org from public.projects where id = new.project_id;
  if p_workspace is distinct from new.workspace_id or p_org is distinct from new.organization_id then
    raise exception 'El documento y su proyecto deben pertenecer al mismo espacio';
  end if;
  if new.activity_id is not null then
    select workspace_id, project_id into a_workspace, a_project from public.activities where id = new.activity_id;
    if a_workspace is distinct from new.workspace_id or a_project is distinct from new.project_id then
      raise exception 'La actividad relacionada debe pertenecer al mismo proyecto';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists documents_scope_guard on public.documents;
create trigger documents_scope_guard before insert or update on public.documents for each row execute function public.validate_document_scope();

-- Avisos dentro de la aplicación para asignaciones y nuevos comentarios.
create or replace function public.notify_activity_assignment()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.assignee_id is not null and new.assignee_id is distinct from new.created_by then
    if tg_op = 'INSERT' then
      insert into public.notifications(workspace_id,user_id,title,body)
      values (new.workspace_id,new.assignee_id,'Nueva actividad asignada',new.title);
    elsif new.assignee_id is distinct from old.assignee_id then
      insert into public.notifications(workspace_id,user_id,title,body)
      values (new.workspace_id,new.assignee_id,'Nueva actividad asignada',new.title);
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists activity_assignment_notification on public.activities;
create trigger activity_assignment_notification after insert or update of assignee_id on public.activities
for each row execute function public.notify_activity_assignment();

create or replace function public.notify_activity_comment()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  activity_row record;
begin
  select id, workspace_id, title, assignee_id, created_by into activity_row
  from public.activities where id = new.activity_id;
  insert into public.notifications(workspace_id,user_id,title,body)
  select new.workspace_id, recipient_id, 'Nuevo comentario en actividad', left(activity_row.title || ': ' || new.body, 220)
  from (select activity_row.assignee_id as recipient_id union select activity_row.created_by) recipients
  where recipient_id is not null and recipient_id <> new.author_id;
  return new;
end;
$$;
drop trigger if exists comment_notification on public.comments;
create trigger comment_notification after insert on public.comments
for each row execute function public.notify_activity_comment();

create policy "activities_lead_delete" on public.activities for delete to authenticated
using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'activities_parent_not_self') then
    alter table public.activities add constraint activities_parent_not_self
      check (parent_activity_id is null or parent_activity_id <> id);
  end if;
end;
$$;

create or replace function public.prevent_activity_parent_cycles()
returns trigger language plpgsql as $$
declare
  has_cycle boolean;
begin
  if new.parent_activity_id is null then return new; end if;
  with recursive ancestors(id) as (
    select new.parent_activity_id
    union
    select a.parent_activity_id from public.activities a
    join ancestors x on a.id = x.id
    where a.parent_activity_id is not null
  )
  select exists(select 1 from ancestors where id = new.id) into has_cycle;
  if has_cycle then raise exception 'La jerarquía de subactividades genera un ciclo'; end if;
  return new;
end;
$$;
drop trigger if exists activity_parent_cycle_check on public.activities;
create trigger activity_parent_cycle_check before insert or update of parent_activity_id on public.activities
for each row execute function public.prevent_activity_parent_cycles();
