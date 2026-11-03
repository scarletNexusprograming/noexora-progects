import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "NEXORA Projects", description: "Gestión inteligente de proyectos y objetivos" };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="es"><body>{children}</body></html>;
}
