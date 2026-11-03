"use server";

import { requireSuperAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";

export async function updateSettingAction(key: string, value: unknown, isPublic = true) {
  const { supabase, user } = await requireSuperAdmin();

  const { error } = await supabase.from("app_settings").upsert({
    key,
    value: value as any,
    is_public: isPublic,
    updated_by: user.id,
    updated_at: new Date().toISOString(),
  });

  if (error) return { success: false, error: error.message };

  revalidatePath("/settings");
  return { success: true };
}

