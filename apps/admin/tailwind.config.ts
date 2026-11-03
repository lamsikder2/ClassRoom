import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "var(--primary)",
          foreground: "var(--primary-foreground)",
          surface: "var(--primary-surface)",
        },
        background: "var(--background)",
        surface: "var(--surface)",
        "surface-variant": "var(--surface-variant)",
        border: "var(--border)",
        "text-primary": "var(--text-primary)",
        "text-secondary": "var(--text-secondary)",
        "text-muted": "var(--text-muted)",
        success: "#10B981",
        warning: "#F59E0B",
        destructive: "#EF4444",
      },
      borderRadius: {
        lg: "16px",
        md: "10px",
        sm: "6px",
      },
    },
  },
  plugins: [],
};

export default config;

