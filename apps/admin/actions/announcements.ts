"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { broadcastNotification } from "@/lib/notifications";
import { z } from "zod";

const announcementSchema = z.object({
  title: z.string().min(1, "শিরোনাম আবশ্যক").max(200),
  body: z.string().min(1, "বিবরণ আবশ্যক"),
  levelId: z.string().uuid().optional().nullable(),
  isPinned: z.boolean().default(false),
  isPublished: z.boolean().default(true),
});

export async function createAnnouncementAction(formData: FormData) {
  const { supabase, user } = await requireAdmin();

  const raw = {
    title: formData.get("title"),
    body: formData.get("body"),
    levelId: formData.get("levelId") || null,
    isPinned: formData.get("isPinned") === "true",
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = announcementSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase.from("announcements").insert({
    title: parsed.data.title,
    body: parsed.data.body,
    level_id: parsed.data.levelId,
    is_pinned: parsed.data.isPinned,
    is_published: parsed.data.isPublished,
    published_at: new Date().toISOString(),
    created_by: user.id,
  });

  if (error) return { success: false, error: error.message };

  if (parsed.data.isPublished) {
    await broadcastNotification({
      title: parsed.data.title,
      body: parsed.data.body,
      levelId: parsed.data.levelId,
      createAnnouncement: false, // already inserted above
    });
  }

  revalidatePath("/announcements");
  return { success: true };
}

export async function updateAnnouncementAction(id: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    title: formData.get("title"),
    body: formData.get("body"),
    levelId: formData.get("levelId") || null,
    isPinned: formData.get("isPinned") === "true",
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = announcementSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase
    .from("announcements")
    .update({
      title: parsed.data.title,
      body: parsed.data.body,
      level_id: parsed.data.levelId,
      is_pinned: parsed.data.isPinned,
      is_published: parsed.data.isPublished,
    })
    .eq("id", id);

  if (error) return { success: false, error: error.message };

  if (parsed.data.isPublished) {
    await broadcastNotification({
      title: parsed.data.title,
      body: parsed.data.body,
      levelId: parsed.data.levelId,
      createAnnouncement: false, // already inserted above
    });
  }

  revalidatePath("/announcements");
  return { success: true };
}

export async function deleteAnnouncementAction(id: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("announcements").delete().eq("id", id);
  if (error) return { success: false, error: error.message };
  revalidatePath("/announcements");
  return { success: true };
}
