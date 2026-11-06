"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { extractYouTubeId } from "@/lib/parsers";
import { broadcastNotification } from "@/lib/notifications";
import { z } from "zod";

const lessonSchema = z.object({
  chapterId: z.string().uuid("সঠিক অধ্যায় নির্বাচন করুন"),
  title: z.string().min(1, "ক্লাসের নাম আবশ্যক").max(200),
  description: z.string().optional().nullable(),
  videoProvider: z.enum(["youtube", "bunny", "none"]),
  rawVideoUrl: z.string().optional().nullable(),
  videoRef: z.string().optional().nullable(),
  durationSec: z.coerce.number().optional().nullable(),
  instructorName: z.string().optional().nullable(),
  sortOrder: z.coerce.number().default(0),
  isPublished: z.boolean().default(false),
});

export async function createLessonAction(formData: FormData) {
  const { supabase, user } = await requireAdmin();

  const raw = {
    chapterId: formData.get("chapterId"),
    title: formData.get("title"),
    description: formData.get("description") || null,
    videoProvider: formData.get("videoProvider") || "youtube",
    rawVideoUrl: formData.get("rawVideoUrl") || null,
    videoRef: formData.get("videoRef") || null,
    durationSec: formData.get("durationSec") || null,
    instructorName: formData.get("instructorName") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = lessonSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  let finalVideoRef = parsed.data.videoRef;
  let finalThumbnail: string | null = null;

  if (parsed.data.videoProvider === "youtube" && parsed.data.rawVideoUrl) {
    const extractedId = extractYouTubeId(parsed.data.rawVideoUrl);
    if (!extractedId) {
      return { success: false, error: "অবৈধ YouTube লিংক! সঠিক ভিডিও লিংক দিন।" };
    }
    finalVideoRef = extractedId;
    finalThumbnail = `https://img.youtube.com/vi/${extractedId}/hqdefault.jpg`;
  }

  if (parsed.data.videoProvider !== "none" && !finalVideoRef) {
    return { success: false, error: "ভিডিও রেফারেন্স বা লিংক প্রদান করা আবশ্যক" };
  }

  const { data, error } = await supabase.from("lessons").insert({
    chapter_id: parsed.data.chapterId,
    title: parsed.data.title,
    description: parsed.data.description,
    video_provider: parsed.data.videoProvider,
    video_ref: finalVideoRef,
    thumbnail_url: finalThumbnail,
    video_duration_sec: parsed.data.durationSec ? parsed.data.durationSec * 60 : null,
    instructor_name: parsed.data.instructorName,
    sort_order: parsed.data.sortOrder,
    is_published: parsed.data.isPublished,
    created_by: user.id,
  }).select("id").single();

  if (error) return { success: false, error: error.message };

  // Broadcast notification to students
  if (parsed.data.isPublished) {
    await broadcastNotification({
      title: `নতুন ক্লাস: ${parsed.data.title}`,
      body: `একটি নতুন ক্লাস আপলোড করা হয়েছে। এখনই অ্যাপে দেখে নাও!`,
      deepLink: `/lessons/${data.id}`,
      lessonId: data.id,
      createAnnouncement: true,
    });
  }

  revalidatePath("/lessons");
  return { success: true, lessonId: data.id };
}

export async function deleteLessonAction(chapterId: string, lessonId: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("lessons").delete().eq("id", lessonId);
  if (error) return { success: false, error: error.message };
  revalidatePath(`/lessons?chapterId=${chapterId}`);
  return { success: true };
}

export async function updateLessonAction(id: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const raw = {
    chapterId: formData.get("chapterId"),
    title: formData.get("title"),
    description: formData.get("description") || null,
    videoProvider: formData.get("videoProvider") || "youtube",
    rawVideoUrl: formData.get("rawVideoUrl") || null,
    videoRef: formData.get("videoRef") || null,
    durationSec: formData.get("durationSec") || null,
    instructorName: formData.get("instructorName") || null,
    sortOrder: formData.get("sortOrder") || 0,
    isPublished: formData.get("isPublished") === "true",
  };

  const parsed = lessonSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  let finalVideoRef = parsed.data.videoRef;
  let finalThumbnail: string | null = null;

  if (parsed.data.videoProvider === "youtube" && parsed.data.rawVideoUrl) {
    const extractedId = extractYouTubeId(parsed.data.rawVideoUrl);
    if (!extractedId) {
      return { success: false, error: "অবৈধ YouTube লিংক! সঠিক ভিডিও লিংক দিন।" };
    }
    finalVideoRef = extractedId;
    finalThumbnail = `https://img.youtube.com/vi/${extractedId}/hqdefault.jpg`;
  }

  if (parsed.data.videoProvider !== "none" && !finalVideoRef) {
    return { success: false, error: "ভিডিও রেফারেন্স বা লিংক প্রদান করা আবশ্যক" };
  }

  const { error } = await supabase.from("lessons").update({
    chapter_id: parsed.data.chapterId,
    title: parsed.data.title,
    description: parsed.data.description,
    video_provider: parsed.data.videoProvider,
    video_ref: finalVideoRef,
    ...(finalThumbnail ? { thumbnail_url: finalThumbnail } : {}),
    video_duration_sec: parsed.data.durationSec ? parsed.data.durationSec * 60 : null,
    instructor_name: parsed.data.instructorName,
    sort_order: parsed.data.sortOrder,
    is_published: parsed.data.isPublished,
  }).eq("id", id);

  if (error) return { success: false, error: error.message };

  revalidatePath("/lessons");
  return { success: true };
}

