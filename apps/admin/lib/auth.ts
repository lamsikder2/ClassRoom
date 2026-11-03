import "server-only";
import { createClient } from "@/lib/supabase/server";

export async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    throw new Error("UNAUTHENTICATED");
  }

  const metaRole = (user.app_metadata?.role as string) || (user.user_metadata?.role as string);
  const isMetaAdmin = metaRole === "admin" || metaRole === "super_admin";

  const { data: isAdmin } = await supabase.rpc("is_admin");

  if (!isAdmin && !isMetaAdmin) {
    throw new Error("UNAUTHORIZED: Admin privilege required");
  }

  return { user, supabase };
}

export async function requireSuperAdmin() {
  const { user, supabase } = await requireAdmin();

  const metaRole = (user.app_metadata?.role as string) || (user.user_metadata?.role as string);
  const isMetaSuper = metaRole === "super_admin";

  const { data: isSuper } = await supabase.rpc("is_super_admin");

  if (!isSuper && !isMetaSuper) {
    throw new Error("FORBIDDEN: Super Admin privilege required");
  }

  return { user, supabase };
}

