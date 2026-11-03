import { createClient } from "@/lib/supabase/server";
export type Role="admin"|"project_director"|"collaborator"|"observer";
export async function requireWorkspaceRole(workspaceId:string,allowed:Role[]) {
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser();
 if(!user) throw new Error("No autenticado");
 const {data,error}=await supabase.from("memberships").select("role,organization_id").eq("workspace_id",workspaceId).eq("user_id",user.id).single();
 if(error||!data||!allowed.includes(data.role as Role)) throw new Error("No tienes permisos para esta operación");
 return {supabase,user,membership:data};
}
