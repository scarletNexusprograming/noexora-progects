import { z } from "zod";
export const projectSchema=z.object({
 name:z.string().trim().min(3).max(120),description:z.string().max(4000).optional().default(""),
 objective:z.string().max(2000).optional().default(""),
 start_date:z.string().date(),end_date:z.string().date(),
 priority:z.enum(["low","medium","high","critical"]).default("medium"),
 budget:z.coerce.number().min(0).max(1_000_000_000_000).default(0)
}).refine(v=>v.end_date>=v.start_date,{message:"La fecha de cierre debe ser igual o posterior al inicio.",path:["end_date"]});
export const goalSchema=z.object({
 title:z.string().trim().min(3).max(180),description:z.string().max(3000).optional().default(""),
 indicator:z.string().min(1).max(120),unit:z.string().min(1).max(40),
 baseline:z.coerce.number(),target:z.coerce.number(),current_value:z.coerce.number(),
 direction:z.enum(["increase","decrease"]),due_date:z.string().date(),weight:z.coerce.number().min(0.01).max(100)
}).refine(v=>v.direction==="increase"?v.target>v.baseline:v.target<v.baseline,{message:"La meta debe ser mayor que la línea base si el indicador aumenta, o menor si disminuye.",path:["target"]});
export const activitySchema=z.object({
 title:z.string().trim().min(3).max(180),description:z.string().max(3000).optional().default(""),
 project_id:z.string().uuid(),goal_id:z.string().uuid().optional().or(z.literal("")),parent_activity_id:z.string().uuid().optional().or(z.literal("")),depends_on_id:z.string().uuid().optional().or(z.literal("")),
 assignee_id:z.string().uuid().optional().or(z.literal("")),
 start_date:z.string().date(),due_date:z.string().date(),
 status:z.enum(["pending","in_progress","in_review","completed","blocked"]).default("pending"),
 priority:z.enum(["low","medium","high","critical"]).default("medium"),
 progress:z.coerce.number().min(0).max(100).default(0),
 estimated_hours:z.coerce.number().min(0).max(100000).default(0),
 weight:z.coerce.number().min(0.01).max(100).default(1)
}).refine(v=>v.due_date>=v.start_date,{message:"El vencimiento no puede ser anterior al inicio.",path:["due_date"]});
