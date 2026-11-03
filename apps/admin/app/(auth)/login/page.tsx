"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ShieldCheck, Loader2 } from "lucide-react";
import { toast } from "sonner";

export default function LoginPage() {
  const [mounted, setMounted] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast.error("অনুগ্রহ করে ইমেইল ও পাসওয়ার্ড দিন");
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        toast.error("লগইন ব্যর্থ হয়েছে: " + error.message);
        return;
      }

      if (data.user) {
        // রোল যাচাই (app_metadata এবং RPC উভয় পদ্ধতিতেই চেক)
        const metaRole = (data.user.app_metadata?.role as string) || (data.user.user_metadata?.role as string);
        const isMetaAdmin = metaRole === "admin" || metaRole === "super_admin";

        let isAdmin = false;
        try {
          const { data: rpcAdmin } = await supabase.rpc("is_admin");
          isAdmin = !!rpcAdmin;
        } catch {
          // Fallback to app_metadata check
        }

        if (!isAdmin && !isMetaAdmin) {
          await supabase.auth.signOut();
          toast.error("প্রবেশাধিকার নেই: এই পোর্টালটি শুধুমাত্র অ্যাডমিনদের জন্য।");
          return;
        }

        toast.success("সফলভাবে লগইন হয়েছে!");
        router.push("/");
        router.refresh();
      }
    } catch {
      toast.error("একটি অপ্রত্যাশিত ত্রুটি ঘটেছে। আবার চেষ্টা করুন।");
    } finally {
      setLoading(false);
    }
  };

  if (!mounted) {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4" suppressHydrationWarning>
      <Card className="w-full max-w-md border-border shadow-md">
        <CardHeader className="text-center space-y-2">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-primary-surface text-primary mb-2">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <CardTitle className="text-2xl font-bold">ClassRoom Admin</CardTitle>
          <CardDescription>
            অ্যাডমিন প্যানেলে প্রবেশ করতে আপনার ক্রেডেনশিয়াল দিন
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                অ্যাডমিন ইমেইল
              </label>
              <Input
                type="email"
                placeholder="admin@yourdomain.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                পাসওয়ার্ড
              </label>
              <Input
                type="password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <Button
              type="submit"
              className="w-full mt-2"
              disabled={loading}
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  যাচাই করা হচ্ছে...
                </>
              ) : (
                "লগইন করুন"
              )}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

