"use server";
import { requireWorkspaceRole } from "@/server/authz";
import { revalidatePath } from "next/cache";

const MAX_BYTES=8*1024*1024;
const ALLOWED=new Set(["application/pdf","image/png","image/jpeg","text/plain","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]);
export async function uploadEvidence(workspaceId:string,projectId:string,activityId:string|null,formData:FormData) {
 try {
  const {supabase,user,membership}=await requireWorkspaceRole(workspaceId,["admin","project_director","collaborator"]);
  const file=formData.get("file"); if(!(file instanceof File)) return {error:"Selecciona un archivo."};
  if(file.size<=0||file.size>MAX_BYTES) return {error:"El archivo debe pesar entre 1 byte y 8 MB."};
  if(!ALLOWED.has(file.type)) return {error:"Tipo de archivo no permitido."};
  const safeName=file.name.replace(/[^a-zA-Z0-9._-]/g,"_").slice(0,120);
  const objectPath=`${membership.organization_id}/${workspaceId}/${crypto.randomUUID()}-${safeName}`;
  const {error:uploadError}=await supabase.storage.from("project-files").upload(objectPath,file,{contentType:file.type,upsert:false});
  if(uploadError) throw uploadError;
  const {error}=await supabase.from("documents").insert({organization_id:membership.organization_id,workspace_id:workspaceId,project_id:projectId,activity_id:activityId,storage_path:objectPath,name:file.name,mime_type:file.type,size_bytes:file.size,uploaded_by:user.id,version:1});
  if(error){await supabase.storage.from("project-files").remove([objectPath]);throw error;}
  revalidatePath("/");return {ok:true};
 }catch(e){return {error:e instanceof Error?e.message:"No fue posible cargar el documento"};}
}
export async function signedDocumentUrl(documentId:string,workspaceId:string) {
 const {supabase}=await requireWorkspaceRole(workspaceId,["admin","project_director","collaborator","observer"]);
 const {data,error}=await supabase.from("documents").select("storage_path").eq("id",documentId).eq("workspace_id",workspaceId).is("deleted_at",null).single();
 if(error||!data) return {error:"Documento no encontrado o sin permisos."};
 const signed=await supabase.storage.from("project-files").createSignedUrl(data.storage_path,60);
 if(signed.error) return {error:"No fue posible generar el enlace."};
 return {url:signed.data.signedUrl};
}
