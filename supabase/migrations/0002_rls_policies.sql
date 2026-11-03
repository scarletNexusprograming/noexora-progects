alter table public.organizations enable row level security;
alter table public.workspaces enable row level security;
alter table public.memberships enable row level security;
alter table public.projects enable row level security;
alter table public.phases enable row level security;
alter table public.goals enable row level security;
alter table public.activities enable row level security;
alter table public.activity_collaborators enable row level security;
alter table public.activity_dependencies enable row level security;
alter table public.documents enable row level security;
alter table public.comments enable row level security;
alter table public.activity_events enable row level security;
alter table public.notifications enable row level security;

create or replace function public.is_workspace_member(wid uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.memberships m where m.workspace_id=wid and m.user_id=auth.uid())
$$;
create or replace function public.has_workspace_role(wid uuid, roles public.member_role[])
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.memberships m where m.workspace_id=wid and m.user_id=auth.uid() and m.role=any(roles))
$$;
revoke all on function public.is_workspace_member(uuid) from public;
revoke all on function public.has_workspace_role(uuid,public.member_role[]) from public;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.has_workspace_role(uuid,public.member_role[]) to authenticated;

create policy "organizations_read_member" on public.organizations for select to authenticated
using (exists(select 1 from public.memberships m where m.organization_id=id and m.user_id=auth.uid()));
create policy "organizations_admin_update" on public.organizations for update to authenticated
using (exists(select 1 from public.memberships m where m.organization_id=id and m.user_id=auth.uid() and m.role='admin'));
create policy "workspaces_member_read" on public.workspaces for select to authenticated using (public.is_workspace_member(id));
create policy "workspaces_admin_write" on public.workspaces for all to authenticated
using (public.has_workspace_role(id,array['admin']::public.member_role[]))
with check (public.has_workspace_role(id,array['admin']::public.member_role[]));
create policy "memberships_member_read" on public.memberships for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "memberships_admin_manage" on public.memberships for all to authenticated
using (public.has_workspace_role(workspace_id,array['admin']::public.member_role[]))
with check (public.has_workspace_role(workspace_id,array['admin']::public.member_role[]));

create policy "projects_member_read" on public.projects for select to authenticated using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy "projects_lead_write" on public.projects for all to authenticated
using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]))
with check (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "phases_member_read" on public.phases for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "phases_lead_write" on public.phases for all to authenticated using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[])) with check (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "goals_member_read" on public.goals for select to authenticated using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy "goals_lead_write" on public.goals for all to authenticated using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[])) with check (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "activities_member_read" on public.activities for select to authenticated using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy "activities_lead_write" on public.activities for insert to authenticated with check (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "activities_lead_update" on public.activities for update to authenticated using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[])) with check (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "activities_collaborator_update" on public.activities for update to authenticated
using (public.has_workspace_role(workspace_id,array['collaborator']::public.member_role[]) and (assignee_id=auth.uid() or exists(select 1 from public.activity_collaborators c where c.activity_id=id and c.user_id=auth.uid())))
with check (public.has_workspace_role(workspace_id,array['collaborator']::public.member_role[]) and (assignee_id=auth.uid() or exists(select 1 from public.activity_collaborators c where c.activity_id=id and c.user_id=auth.uid())));
create policy "collaborators_member_read" on public.activity_collaborators for select to authenticated using (exists(select 1 from public.activities a where a.id=activity_id and public.is_workspace_member(a.workspace_id)));
create policy "collaborators_lead_manage" on public.activity_collaborators for all to authenticated using (exists(select 1 from public.activities a where a.id=activity_id and public.has_workspace_role(a.workspace_id,array['admin','project_director']::public.member_role[]))) with check (exists(select 1 from public.activities a where a.id=activity_id and public.has_workspace_role(a.workspace_id,array['admin','project_director']::public.member_role[])));
create policy "dependencies_member_read" on public.activity_dependencies for select to authenticated using (exists(select 1 from public.activities a where a.id=activity_id and public.is_workspace_member(a.workspace_id)));
create policy "dependencies_lead_manage" on public.activity_dependencies for all to authenticated using (exists(select 1 from public.activities a where a.id=activity_id and public.has_workspace_role(a.workspace_id,array['admin','project_director']::public.member_role[]))) with check (exists(select 1 from public.activities a where a.id=activity_id and public.has_workspace_role(a.workspace_id,array['admin','project_director']::public.member_role[])));
create policy "documents_member_read" on public.documents for select to authenticated using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy "documents_allowed_upload" on public.documents for insert to authenticated with check (public.has_workspace_role(workspace_id,array['admin','project_director','collaborator']::public.member_role[]) and uploaded_by=auth.uid());
create policy "documents_lead_delete" on public.documents for update to authenticated using (public.has_workspace_role(workspace_id,array['admin','project_director']::public.member_role[]));
create policy "comments_member_read" on public.comments for select to authenticated using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy "comments_member_create" on public.comments for insert to authenticated with check (public.is_workspace_member(workspace_id) and author_id=auth.uid());
create policy "events_member_read" on public.activity_events for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "events_member_create" on public.activity_events for insert to authenticated with check (public.is_workspace_member(workspace_id) and actor_id=auth.uid());
create policy "notifications_owner" on public.notifications for all to authenticated using (public.is_workspace_member(workspace_id) and user_id=auth.uid()) with check (public.is_workspace_member(workspace_id) and user_id=auth.uid());

-- Las asignaciones no se usan como criterio de membresía. Un responsable externo no puede leer el workspace.


-- Storage: bucket privado `project-files`. La ruta es org_uuid/workspace_uuid/object.
-- La autorización valida membresía del workspace, no la asignación de actividad.
create policy "project_files_member_read" on storage.objects for select to authenticated
using (
 bucket_id='project-files'
 and public.is_workspace_member(((storage.foldername(name))[2])::uuid)
);
create policy "project_files_member_upload" on storage.objects for insert to authenticated
with check (
 bucket_id='project-files'
 and public.has_workspace_role(((storage.foldername(name))[2])::uuid,
   array['admin','project_director','collaborator']::public.member_role[])
);
create policy "project_files_lead_delete" on storage.objects for delete to authenticated
using (
 bucket_id='project-files'
 and public.has_workspace_role(((storage.foldername(name))[2])::uuid,
   array['admin','project_director']::public.member_role[])
);
