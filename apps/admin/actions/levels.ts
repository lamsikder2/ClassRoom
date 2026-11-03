"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const levelSchema = z.object({
  name: z.string().min(1, "নাম আবশ্যক").max(80),
  nameEn: z.string().optional().nullable(),
  slug: z.string().regex(/^[a-z0-9-]+$/, "স্লাগ শুধুমাত্র ছোট হাতের অক্ষর, সংখ্যা ও হাইফেন হতে পারে"),
  description: z.string().optional().nullable(),
  sortOrder: z.coerce.number().default(0),
  isPublished: z.boolean().default(false),
});

export async function createLevelAction(formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    name: formData.get("name"),
    nameEn: formData.get("nameEn") || null,
    slug: formData.get("slug"),
    description: formData.get("description") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = levelSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase.from("levels").insert({
    name: parsed.data.name,
    name_en: parsed.data.nameEn,
    slug: parsed.data.slug,
    description: parsed.data.description,
    sort_order: parsed.data.sortOrder,
    is_published: parsed.data.isPublished,
  });

  if (error) return { success: false, error: error.message };

  revalidatePath("/levels");
  return { success: true };
}

export async function updateLevelAction(id: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    name: formData.get("name"),
    nameEn: formData.get("nameEn") || null,
    slug: formData.get("slug"),
    description: formData.get("description") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = levelSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const { error } = await supabase
    .from("levels")
    .update({
      name: parsed.data.name,
      name_en: parsed.data.nameEn,
      slug: parsed.data.slug,
      description: parsed.data.description,
      sort_order: parsed.data.sortOrder,
      is_published: parsed.data.isPublished,
    })
    .eq("id", id);

  if (error) return { success: false, error: error.message };

  revalidatePath("/levels");
  return { success: true };
}

export async function deleteLevelAction(id: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("levels").delete().eq("id", id);
  if (error) return { success: false, error: error.message };
  revalidatePath("/levels");
  return { success: true };
}
