import { describe,it,expect } from "vitest";
import { weightedProgress,completionRate,goalFulfillment } from "../src/lib/domain/metrics";
describe("métricas de seguimiento",()=>{
 it("calcula avance ponderado",()=>expect(weightedProgress([{progress:50,weight:1},{progress:100,weight:3}])).toBe(87.5));
 it("no inventa avance sin pesos válidos",()=>expect(weightedProgress([{progress:50,weight:0}])).toBeNull());
 it("calcula tasa de completitud separada",()=>expect(completionRate(2,4)).toBe(50));
 it("devuelve null si no hay actividades",()=>expect(completionRate(0,0)).toBeNull());
 it("calcula objetivo creciente",()=>expect(goalFulfillment(10,20,15,"increase")).toBe(50));
 it("calcula objetivo decreciente",()=>expect(goalFulfillment(100,50,75,"decrease")).toBe(50));
 it("admite meta cero con línea base distinta",()=>expect(goalFulfillment(10,0,5,"decrease")).toBe(50));
 it("rechaza denominador cero",()=>expect(goalFulfillment(5,5,8,"increase")).toBeNull());
});
