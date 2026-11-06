"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { extractDriveFileId } from "@/lib/parsers";
import { broadcastNotification } from "@/lib/notifications";
import { z } from "zod";

const materialSchema = z.object({
  lessonId: z.string().uuid(),
  type: z.enum(["lecture_sheet", "class_note", "other"]),
  source: z.enum(["drive", "storage", "rich_text"]),
  title: z.string().min(1, "শিরোনাম আবশ্যক").max(200),
  rawDriveUrl: z.string().optional().nullable(),
  driveFileId: z.string().optional().nullable(),
  contentMd: z.string().optional().nullable(),
  allowDownload: z.boolean().default(true),
  sortOrder: z.coerce.number().default(0),
});

export async function createMaterialAction(formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    lessonId: formData.get("lessonId"),
    type: formData.get("type") || "lecture_sheet",
    source: formData.get("source") || "drive",
    title: formData.get("title"),
    rawDriveUrl: formData.get("rawDriveUrl") || null,
    driveFileId: formData.get("driveFileId") || null,
    contentMd: formData.get("contentMd") || null,
    allowDownload: formData.get("allowDownload") === "true",
    sortOrder: formData.get("sortOrder") || 0,
  };

  const parsed = materialSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  let finalDriveId = parsed.data.driveFileId;

  if (parsed.data.source === "drive" && parsed.data.rawDriveUrl) {
    const extractedId = extractDriveFileId(parsed.data.rawDriveUrl);
    if (!extractedId) {
      return { success: false, error: "অবৈধ Google Drive লিংক! সঠিক শেয়ার লিংক দিন।" };
    }
    finalDriveId = extractedId;
  }

  if (parsed.data.source === "drive" && !finalDriveId) {
    return { success: false, error: "গুগল ড্রাইভ ফাইল আইডি প্রদান করা আবশ্যক।" };
  }

  if (parsed.data.source === "rich_text" && !parsed.data.contentMd) {
    return { success: false, error: "ক্লাস নোটের বিবরণ লিখুন।" };
  }

  const { error } = await supabase.from("materials").insert({
    lesson_id: parsed.data.lessonId,
    type: parsed.data.type,
    source: parsed.data.source,
    title: parsed.data.title,
    drive_file_id: finalDriveId,
    content_md: parsed.data.contentMd,
    allow_download: parsed.data.allowDownload,
    sort_order: parsed.data.sortOrder,
    is_published: true,
  });

  if (error) return { success: false, error: error.message };

  // Broadcast notification to students
  const materialTypeLabel =
    parsed.data.type === "lecture_sheet"
      ? "লেকচার শিট"
      : parsed.data.type === "class_note"
      ? "ক্লাস নোট"
      : "স্টাডি মেটেরিয়াল";

  await broadcastNotification({
    title: `নতুন ${materialTypeLabel}: ${parsed.data.title}`,
    body: `একটি নতুন ${materialTypeLabel} আপলোড করা হয়েছে। দেখে নাও!`,
    deepLink: `/lessons/${parsed.data.lessonId}`,
    lessonId: parsed.data.lessonId,
    createAnnouncement: true,
  });

  revalidatePath(`/lessons/${parsed.data.lessonId}/materials`);
  return { success: true };
}

export async function deleteMaterialAction(lessonId: string, materialId: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("materials").delete().eq("id", materialId);
  if (error) return { success: false, error: error.message };
  revalidatePath(`/lessons/${lessonId}/materials`);
  return { success: true };
}

