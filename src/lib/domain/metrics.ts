export type Direction = "increase" | "decrease";
export type WeightedItem = { progress: number; weight: number };
export function weightedProgress(items: WeightedItem[]): number | null {
  if (!items.length) return null;
  const valid = items.filter(x => Number.isFinite(x.progress) && x.progress >= 0 && x.progress <= 100 && Number.isFinite(x.weight) && x.weight > 0);
  const totalWeight = valid.reduce((s, x) => s + x.weight, 0);
  if (!valid.length || totalWeight <= 0) return null;
  return valid.reduce((s, x) => s + x.progress * x.weight, 0) / totalWeight;
}
export function completionRate(completed: number, total: number): number | null {
  if (!Number.isFinite(completed) || !Number.isFinite(total) || total <= 0 || completed < 0 || completed > total) return null;
  return completed / total * 100;
}
export function goalFulfillment(baseline: number, target: number, current: number, direction: Direction): number | null {
  if (![baseline,target,current].every(Number.isFinite)) return null;
  const denominator = target - baseline;
  if (denominator === 0) return null;
  const numerator = direction === "increase" ? current - baseline : baseline - current;
  const divisor = direction === "increase" ? denominator : baseline - target;
  if (divisor === 0) return null;
  return Math.max(0, Math.min(100, numerator / divisor * 100));
}
export function formatCop(value: number) {
 return new Intl.NumberFormat("es-CO",{style:"currency",currency:"COP",maximumFractionDigits:0}).format(value);
}
