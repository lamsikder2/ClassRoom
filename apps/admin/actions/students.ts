"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";

export async function toggleBlockStudentAction(userId: string, currentStatus: boolean) {
  const { supabase } = await requireAdmin();

  const { error } = await supabase
    .from("profiles")
    .update({ is_blocked: !currentStatus })
    .eq("id", userId);

  if (error) return { success: false, error: error.message };

  revalidatePath("/students");
  return { success: true };
}

