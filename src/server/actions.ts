"use server";
import { revalidatePath } from "next/cache";
import { requireWorkspaceRole } from "@/server/authz";
import { activitySchema, goalSchema, projectSchema } from "@/lib/domain/validation";

export async function createProject(workspaceId:string,form:unknown) {
 const parsed=projectSchema.safeParse(form); if(!parsed.success) return {error:parsed.error.issues[0]?.message??"Datos inválidos"};
 try { const {supabase,membership,user}=await requireWorkspaceRole(workspaceId,["admin","project_director"]);
 const {error}=await supabase.from("projects").insert({...parsed.data,workspace_id:workspaceId,organization_id:membership.organization_id,created_by:user.id});
 if(error) throw error; revalidatePath("/"); return {ok:true};
 } catch(e){return {error:e instanceof Error?e.message:"No fue posible crear el proyecto"};}
}
export async function createGoal(workspaceId:string,projectId:string,form:unknown) {
 const parsed=goalSchema.safeParse(form); if(!parsed.success) return {error:parsed.error.issues[0]?.message??"Datos inválidos"};
 try {const {supabase,membership,user}=await requireWorkspaceRole(workspaceId,["admin","project_director"]);
 const {error}=await supabase.from("goals").insert({...parsed.data,project_id:projectId,workspace_id:workspaceId,organization_id:membership.organization_id,created_by:user.id});
 if(error) throw error;revalidatePath("/");return {ok:true};}catch(e){return {error:e instanceof Error?e.message:"No fue posible crear el objetivo"};}
}
export async function createActivity(workspaceId:string,form:unknown) {
 const parsed=activitySchema.safeParse(form); if(!parsed.success) return {error:parsed.error.issues[0]?.message??"Datos inválidos"};
 try {const {supabase,membership,user}=await requireWorkspaceRole(workspaceId,["admin","project_director"]);
 const {goal_id,parent_activity_id,depends_on_id,...activityData}=parsed.data;
 const {data:created,error}=await supabase.from("activities").insert({...activityData,goal_id:goal_id||null,parent_activity_id:parent_activity_id||null,assignee_id:activityData.assignee_id||null,workspace_id:workspaceId,organization_id:membership.organization_id,created_by:user.id,progress:activityData.status==="completed"?100:activityData.progress}).select("id").single();
 if(error) throw error;
 if(depends_on_id){const {error:dependencyError}=await supabase.from("activity_dependencies").insert({activity_id:created.id,depends_on_id});if(dependencyError){await supabase.from("activities").delete().eq("id",created.id).eq("workspace_id",workspaceId);throw dependencyError;}}
 revalidatePath("/");return {ok:true};}catch(e){return {error:e instanceof Error?e.message:"No fue posible crear la actividad"};}
}
export async function updateActivity(workspaceId:string,id:string,expectedVersion:number,changes:{status?:string;progress?:number}) {
 try {const {supabase,user}=await requireWorkspaceRole(workspaceId,["admin","project_director","collaborator"]);
 const safe={...changes}; if(safe.progress!==undefined&&(!Number.isFinite(safe.progress)||safe.progress<0||safe.progress>100)) return {error:"El avance debe estar entre 0 y 100."};
 if(safe.status==="completed") safe.progress=100;
 const {data,error}=await supabase.from("activities").update({...safe,version:expectedVersion+1,updated_by:user.id,updated_at:new Date().toISOString()}).eq("id",id).eq("workspace_id",workspaceId).eq("version",expectedVersion).select("id,version").maybeSingle();
 if(error) throw error;if(!data)return {conflict:true,error:"Este registro fue modificado por otra persona. Actualiza la vista e inténtalo de nuevo."};
 await supabase.from("activity_events").insert({activity_id:id,workspace_id:workspaceId,actor_id:user.id,event_type:"updated",payload:safe});
 revalidatePath("/");return {ok:true,version:data.version};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible actualizar la actividad"};}
}

export async function updateGoal(workspaceId:string,id:string,currentValue:number) {
 try {
  if(!Number.isFinite(currentValue)) return {error:"El valor del indicador debe ser numérico."};
  const {supabase}=await requireWorkspaceRole(workspaceId,["admin","project_director"]);
  const {data,error}=await supabase.from("goals").update({current_value:currentValue,updated_at:new Date().toISOString()}).eq("id",id).eq("workspace_id",workspaceId).select("id").maybeSingle();
  if(error) throw error;if(!data)return {error:"No se encontró el objetivo."};revalidatePath("/");return {ok:true};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible actualizar el objetivo"};}
}

export async function createComment(workspaceId:string,activityId:string,body:string) {
 try {
  const clean=body.trim();if(!clean||clean.length>5000)return {error:"El comentario debe tener entre 1 y 5.000 caracteres."};
  const {supabase,user,membership}=await requireWorkspaceRole(workspaceId,["admin","project_director","collaborator"]);
  const {error}=await supabase.from("comments").insert({workspace_id:workspaceId,organization_id:membership.organization_id,activity_id:activityId,author_id:user.id,body:clean});
  if(error) throw error;revalidatePath("/");return {ok:true};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible guardar el comentario"};}
}


export async function markNotificationRead(workspaceId:string,id:string) {
 try {
  const {supabase,user}=await requireWorkspaceRole(workspaceId,["admin","project_director","collaborator","observer"]);
  const {error}=await supabase.from("notifications").update({read_at:new Date().toISOString()}).eq("id",id).eq("workspace_id",workspaceId).eq("user_id",user.id);
  if(error) throw error;revalidatePath("/");return {ok:true};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible actualizar la notificación"};}
}

export async function updateProjectStatus(workspaceId:string,id:string,status:string) {
 try {
  if(!["draft","active","on_hold","completed","cancelled"].includes(status))return {error:"Estado de proyecto no válido."};
  const {supabase,user}=await requireWorkspaceRole(workspaceId,["admin","project_director"]);
  const {error}=await supabase.from("projects").update({status,updated_by:user.id,updated_at:new Date().toISOString()}).eq("id",id).eq("workspace_id",workspaceId);
  if(error)throw error;revalidatePath("/");return {ok:true};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible actualizar el proyecto"};}
}
