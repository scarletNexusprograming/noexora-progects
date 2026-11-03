import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Dashboard } from "@/components/dashboard";
export default async function Home() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: memberships } = await supabase.from("memberships").select("organization_id,workspace_id,role,workspaces(name)").eq("user_id", user.id).limit(1);
  const membership = memberships?.[0];
  if (!membership) return <main className="min-h-screen grid place-items-center p-6"><div className="panel max-w-lg p-8"><h1 className="text-2xl font-bold">Bienvenido a NEXORA</h1><p className="mt-2 text-muted">Tu espacio personal todavía no está inicializado. Cierra sesión y vuelve a entrar; si es una cuenta nueva, verifica que esté aplicada la migración de inicialización.</p><form action="/auth/signout" method="post" className="mt-5"><button className="btn-secondary">Cerrar sesión</button></form></div></main>;
  const wid=membership.workspace_id;
  const [projectsResult,activitiesResult,goalsResult,documentsResult,commentsResult,notificationsResult,dependenciesResult]=await Promise.all([
    supabase.from("projects").select("id,name,description,objective,status,priority,start_date,end_date,budget,cost_actual").eq("workspace_id",wid).is("deleted_at",null).order("created_at",{ascending:false}).limit(100),
    supabase.from("activities").select("id,project_id,goal_id,parent_activity_id,title,description,status,priority,progress,start_date,due_date,weight,estimated_hours,assignee_id,version").eq("workspace_id",wid).is("deleted_at",null).order("due_date",{ascending:true}).limit(500),
    supabase.from("goals").select("id,project_id,title,description,indicator,baseline,target,current_value,direction,unit,due_date,weight").eq("workspace_id",wid).is("deleted_at",null).order("created_at",{ascending:false}).limit(200),
    supabase.from("documents").select("id,project_id,activity_id,name,mime_type,size_bytes,created_at").eq("workspace_id",wid).is("deleted_at",null).order("created_at",{ascending:false}).limit(200),
    supabase.from("comments").select("id,activity_id,body,created_at").eq("workspace_id",wid).is("deleted_at",null).order("created_at",{ascending:false}).limit(100),
    supabase.from("notifications").select("id,title,body,read_at,created_at").eq("workspace_id",wid).eq("user_id",user.id).order("created_at",{ascending:false}).limit(100),
    supabase.from("activity_dependencies").select("activity_id,depends_on_id")
  ]);
  return <Dashboard projects={projectsResult.data??[]} activities={activitiesResult.data??[]} goals={goalsResult.data??[]} documents={documentsResult.data??[]} comments={commentsResult.data??[]} notifications={notificationsResult.data??[]} dependencies={dependenciesResult.data??[]} workspaceName={(membership.workspaces as any)?.name??"Mi espacio"} workspaceId={wid} role={membership.role} userEmail={user.email??""}/>;
}
