import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: { extend: {
    colors: { ink: "#17233C", muted: "#718096", brand: { DEFAULT: "#635BFF", dark: "#5148E5", soft: "#F0EFFF" }, canvas: "#F6F7FB", line: "#E8EAF1" },
    boxShadow: { panel: "0 8px 30px rgba(23,35,60,.06)" }
  }},
  plugins: []
};
export default config;
