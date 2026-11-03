"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Layers,
  BookOpen,
  HelpCircle,
  GraduationCap,
  Users,
  Bell,
  ShieldCheck,
  Settings,
  Sparkles,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

const navigationItems = [
  { name: "ড্যাশবোর্ড", href: "/", icon: LayoutDashboard },
  { name: "স্তর (Levels)", href: "/levels", icon: Layers },
  { name: "বিষয় ও অধ্যায়", href: "/subjects", icon: BookOpen },
  { name: "কোশ্চেন ব্যাংক", href: "/questions", icon: HelpCircle },
  { name: "পরীক্ষাসমূহ", href: "/exams", icon: GraduationCap },
  { name: "শিক্ষার্থী তালিকা", href: "/students", icon: Users },
  { name: "নোটিশ ও ঘোষণা", href: "/announcements", icon: Bell },
  { name: "অডিট লগস", href: "/audit", icon: ShieldCheck },
  { name: "সিস্টেম সেটিংস", href: "/settings", icon: Settings },
];

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export function Sidebar({ isOpen = false, onClose }: SidebarProps) {
  const pathname = usePathname();

  const handleLinkClick = () => {
    if (onClose) onClose();
  };

  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-xs md:hidden transition-opacity"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={cn(
          "w-64 border-r border-border bg-surface flex flex-col h-screen transition-transform duration-300 ease-in-out shrink-0",
          // Desktop styles: always visible, sticky
          "hidden md:flex md:sticky md:top-0 md:translate-x-0 z-30",
          // Mobile styles: off-canvas drawer
          isOpen
            ? "flex fixed inset-y-0 left-0 z-50 shadow-2xl translate-x-0 w-72 max-w-[85vw]"
            : "-translate-x-full"
        )}
      >
        {/* Brand Logo & Mobile Close Button */}
        <div className="h-16 flex items-center justify-between px-6 border-b border-border">
          <div className="flex items-center gap-2">
            <div className="h-9 w-9 rounded-md bg-primary flex items-center justify-center text-white font-bold text-lg shadow-sm">
              C
            </div>
            <div>
              <span className="font-bold text-lg tracking-tight text-text-primary">
                ClassRoom
              </span>
              <span className="text-[10px] uppercase font-bold tracking-widest text-primary ml-1.5 px-1.5 py-0.5 rounded bg-primary-surface">
                Admin
              </span>
            </div>
          </div>

          {/* Close Button on Mobile Drawer */}
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="md:hidden h-8 w-8 text-text-secondary hover:text-text-primary"
            title="মেনু বন্ধ করুন"
          >
            <X className="h-5 w-5" />
            <span className="sr-only">Close Menu</span>
          </Button>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
          {navigationItems.map((item) => {
            const isActive =
              item.href === "/"
                ? pathname === "/"
                : pathname.startsWith(item.href);

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={handleLinkClick}
                className={cn(
                  "flex items-center gap-3 px-3.5 py-2.5 rounded-md text-sm font-medium transition-colors",
                  isActive
                    ? "bg-primary-surface text-primary font-semibold"
                    : "text-text-secondary hover:bg-surface-variant hover:text-text-primary"
                )}
              >
                <item.icon className="h-4 w-4 shrink-0" />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* Footer Info */}
        <div className="p-4 border-t border-border text-xs text-text-muted flex items-center gap-2">
          <Sparkles className="h-3.5 w-3.5 text-primary" />
          <span>ClassRoom Admin v1.0</span>
        </div>
      </aside>
    </>
  );
}
