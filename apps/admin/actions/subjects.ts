"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const subjectSchema = z.object({
  levelId: z.string().uuid("সঠিক স্তর নির্বাচন করুন"),
  name: z.string().min(1, "নাম আবশ্যক").max(80),
  nameEn: z.string().optional().nullable(),
  slug: z.string().regex(/^[a-z0-9-]+$/, "স্লাগ শুধুমাত্র ছোট হাতের অক্ষর, সংখ্যা ও হাইফেন হতে পারে"),
  colorHex: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "সঠিক হেক্স কালার দিন").optional().nullable(),
  sortOrder: z.coerce.number().default(0),
  isPublished: z.boolean().default(false),
});

export async function createSubjectAction(formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    levelId: formData.get("levelId"),
    name: formData.get("name"),
    nameEn: formData.get("nameEn") || null,
    slug: formData.get("slug"),
    colorHex: formData.get("colorHex") || "#4F46E5",
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = subjectSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase.from("subjects").insert({
    level_id: parsed.data.levelId,
    name: parsed.data.name,
    name_en: parsed.data.nameEn,
    slug: parsed.data.slug,
    color_hex: parsed.data.colorHex,
    sort_order: parsed.data.sortOrder,
    is_published: parsed.data.isPublished,
  });

  if (error) return { success: false, error: error.message };

  revalidatePath("/subjects");
  return { success: true };
}

export async function updateSubjectAction(id: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    levelId: formData.get("levelId"),
    name: formData.get("name"),
    nameEn: formData.get("nameEn") || null,
    slug: formData.get("slug"),
    colorHex: formData.get("colorHex") || "#4F46E5",
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = subjectSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase
    .from("subjects")
    .update({
      level_id: parsed.data.levelId,
      name: parsed.data.name,
      name_en: parsed.data.nameEn,
      slug: parsed.data.slug,
      color_hex: parsed.data.colorHex,
      sort_order: parsed.data.sortOrder,
      is_published: parsed.data.isPublished,
    })
    .eq("id", id);

  if (error) return { success: false, error: error.message };

  revalidatePath("/subjects");
  return { success: true };
}

export async function deleteSubjectAction(id: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("subjects").delete().eq("id", id);
  if (error) return { success: false, error: error.message };
  revalidatePath("/subjects");
  return { success: true };
}
