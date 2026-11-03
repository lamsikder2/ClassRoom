"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const chapterSchema = z.object({
  subjectId: z.string().uuid(),
  chapterNo: z.coerce.number().optional().nullable(),
  title: z.string().min(1, "অধ্যায়ের শিরোনাম আবশ্যক").max(150),
  description: z.string().optional().nullable(),
  sortOrder: z.coerce.number().default(0),
  isPublished: z.boolean().default(false),
});

export async function createChapterAction(formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    subjectId: formData.get("subjectId"),
    chapterNo: formData.get("chapterNo") || null,
    title: formData.get("title"),
    description: formData.get("description") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = chapterSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase.from("chapters").insert({
    subject_id: parsed.data.subjectId,
    chapter_no: parsed.data.chapterNo,
    title: parsed.data.title,
    description: parsed.data.description,
    sort_order: parsed.data.sortOrder,
    is_published: parsed.data.isPublished,
  });

  if (error) return { success: false, error: error.message };

  revalidatePath(`/subjects/${parsed.data.subjectId}/chapters`);
  return { success: true };
}

export async function updateChapterAction(subjectId: string, chapterId: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    subjectId,
    chapterNo: formData.get("chapterNo") || null,
    title: formData.get("title"),
    description: formData.get("description") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = chapterSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase
    .from("chapters")
    .update({
      chapter_no: parsed.data.chapterNo,
      title: parsed.data.title,
      description: parsed.data.description,
      sort_order: parsed.data.sortOrder,
      is_published: parsed.data.isPublished,
    })
    .eq("id", chapterId);

  if (error) return { success: false, error: error.message };

  revalidatePath(`/subjects/${subjectId}/chapters`);
  return { success: true };
}

export async function deleteChapterAction(subjectId: string, chapterId: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("chapters").delete().eq("id", chapterId);
  if (error) return { success: false, error: error.message };
  revalidatePath(`/subjects/${subjectId}/chapters`);
  return { success: true };
}
