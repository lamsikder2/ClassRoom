"use client";

import { useTheme } from "next-themes";
import { Moon, Sun, LogOut, Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

interface NavbarProps {
  onToggleSidebar?: () => void;
}

export function Navbar({ onToggleSidebar }: NavbarProps) {
  const { theme, setTheme } = useTheme();
  const router = useRouter();
  const supabase = createClient();

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <header className="h-16 border-b border-border bg-surface px-4 sm:px-6 flex items-center justify-between sticky top-0 z-30">
      <div className="flex items-center gap-2 sm:gap-3 min-w-0">
        {/* Mobile Hamburger Button */}
        <Button
          variant="ghost"
          size="icon"
          onClick={onToggleSidebar}
          className="md:hidden h-9 w-9 -ml-1 text-text-primary shrink-0"
          title="মেনু খুলুন"
        >
          <Menu className="h-5 w-5" />
          <span className="sr-only">Toggle Sidebar</span>
        </Button>

        <div className="min-w-0">
          <h1 className="text-sm sm:text-base font-semibold text-text-primary truncate">
            অ্যাডমিন পোর্টাল
          </h1>
          <p className="hidden sm:block text-xs text-text-secondary truncate">
            প্ল্যাটফর্মের কনটেন্ট ও ডেটা নিয়ন্ত্রণ করুন
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2 sm:gap-3 shrink-0">
        {/* Theme Toggle */}
        <Button
          variant="outline"
          size="icon"
          onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
          className="rounded-full h-8 w-8 sm:h-9 sm:w-9"
          title="থিম পরিবর্তন"
        >
          <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>

        {/* User / Sign Out */}
        <Button
          variant="ghost"
          size="sm"
          onClick={handleSignOut}
          className="text-text-secondary hover:text-destructive gap-1.5 text-xs px-2.5 sm:px-3 h-8 sm:h-9"
          title="লগআউট"
        >
          <LogOut className="h-4 w-4" />
          <span className="hidden sm:inline">সাইন-আউট</span>
        </Button>
      </div>
    </header>
  );
}
