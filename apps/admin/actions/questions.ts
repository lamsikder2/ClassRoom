"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const questionSchema = z.object({
  chapterId: z.string().uuid("অধ্যায় নির্বাচন করুন"),
  body: z.string().min(1, "প্রশ্ন আবশ্যক").max(5000),
  imageUrl: z.string().optional().nullable(),
  difficulty: z.enum(["easy", "medium", "hard"]).default("medium"),
  tags: z.string().optional().nullable(),
  explanation: z.string().optional().nullable(),
  explanationImageUrl: z.string().optional().nullable(),
  optionA: z.string().min(1, "অপশন (A) আবশ্যক"),
  optionAImageUrl: z.string().optional().nullable(),
  optionB: z.string().min(1, "অপশন (B) আবশ্যক"),
  optionBImageUrl: z.string().optional().nullable(),
  optionC: z.string().min(1, "অপশন (C) আবশ্যক"),
  optionCImageUrl: z.string().optional().nullable(),
  optionD: z.string().min(1, "অপশন (D) আবশ্যক"),
  optionDImageUrl: z.string().optional().nullable(),
  correctOption: z.enum(["A", "B", "C", "D"], {
    errorMap: () => ({ message: "একটি সঠিক উত্তর নির্বাচন করা আবশ্যক" }),
  }),
});

async function resolveImageUrl(supabase: any, file: unknown, urlInput: unknown, folder: string): Promise<string | null> {
  // If file upload exists
  if (file && typeof file === "object" && "size" in file && (file as File).size > 0) {
    const f = file as File;
    const ext = f.name.split(".").pop() || "png";
    const path = `questions/${folder}/${crypto.randomUUID()}.${ext}`;
    const buffer = Buffer.from(await f.arrayBuffer());
    const { error } = await supabase.storage
      .from("public-assets")
      .upload(path, buffer, { contentType: f.type || "image/png", upsert: true });

    if (!error) {
      const { data } = supabase.storage.from("public-assets").getPublicUrl(path);
      return data.publicUrl;
    }
  }

  // Otherwise check url input
  if (typeof urlInput === "string" && urlInput.trim().length > 0) {
    return urlInput.trim();
  }

  return null;
}

export async function createQuestionAction(formData: FormData) {
  const { supabase, user } = await requireAdmin();

  const qImageUrl = await resolveImageUrl(
    supabase,
    formData.get("questionImage"),
    formData.get("imageUrl"),
    "headers"
  );
  const optAImg = await resolveImageUrl(
    supabase,
    formData.get("optionAImage"),
    formData.get("optionAImageUrl"),
    "options"
  );
  const optBImg = await resolveImageUrl(
    supabase,
    formData.get("optionBImage"),
    formData.get("optionBImageUrl"),
    "options"
  );
  const optCImg = await resolveImageUrl(
    supabase,
    formData.get("optionCImage"),
    formData.get("optionCImageUrl"),
    "options"
  );
  const optDImg = await resolveImageUrl(
    supabase,
    formData.get("optionDImage"),
    formData.get("optionDImageUrl"),
    "options"
  );
  const explImg = await resolveImageUrl(
    supabase,
    formData.get("explanationImage"),
    formData.get("explanationImageUrl"),
    "explanations"
  );

  const raw = {
    chapterId: formData.get("chapterId"),
    body: formData.get("body"),
    imageUrl: qImageUrl,
    difficulty: formData.get("difficulty") || "medium",
    tags: formData.get("tags") || null,
    explanation: formData.get("explanation") || null,
    explanationImageUrl: explImg,
    optionA: formData.get("optionA"),
    optionAImageUrl: optAImg,
    optionB: formData.get("optionB"),
    optionBImageUrl: optBImg,
    optionC: formData.get("optionC"),
    optionCImageUrl: optCImg,
    optionD: formData.get("optionD"),
    optionDImageUrl: optDImg,
    correctOption: formData.get("correctOption"),
  };

  const parsed = questionSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const tagsArray = parsed.data.tags
    ? parsed.data.tags.split(",").map((t) => t.trim()).filter(Boolean)
    : [];

  // ১. প্রশ্ন তৈরি
  const { data: q, error: qError } = await supabase
    .from("questions")
    .insert({
      chapter_id: parsed.data.chapterId,
      body: parsed.data.body,
      image_url: parsed.data.imageUrl || null,
      difficulty: parsed.data.difficulty,
      tags: tagsArray,
      explanation: parsed.data.explanation,
      explanation_image_url: parsed.data.explanationImageUrl || null,
      created_by: user.id,
    })
    .select("id")
    .single();

  if (qError || !q) return { success: false, error: qError?.message || "প্রশ্ন তৈরিতে ত্রুটি" };

  // ২. ৪টি অপশন তৈরি (সঠিক উত্তর ও ইমেজ সহ)
  const options = [
    { question_id: q.id, body: parsed.data.optionA, image_url: parsed.data.optionAImageUrl || null, is_correct: parsed.data.correctOption === "A", sort_order: 0 },
    { question_id: q.id, body: parsed.data.optionB, image_url: parsed.data.optionBImageUrl || null, is_correct: parsed.data.correctOption === "B", sort_order: 1 },
    { question_id: q.id, body: parsed.data.optionC, image_url: parsed.data.optionCImageUrl || null, is_correct: parsed.data.correctOption === "C", sort_order: 2 },
    { question_id: q.id, body: parsed.data.optionD, image_url: parsed.data.optionDImageUrl || null, is_correct: parsed.data.correctOption === "D", sort_order: 3 },
  ];

  const { error: optError } = await supabase.from("question_options").insert(options);
  if (optError) return { success: false, error: optError.message };

  revalidatePath("/questions");
  return { success: true };
}

export interface BulkQuestionRow {
  chapterId: string;
  body: string;
  imageUrl?: string;
  optionA: string;
  optionAImageUrl?: string;
  optionB: string;
  optionBImageUrl?: string;
  optionC: string;
  optionCImageUrl?: string;
  optionD: string;
  optionDImageUrl?: string;
  correctOption: "A" | "B" | "C" | "D";
  explanation?: string;
  explanationImageUrl?: string;
  difficulty?: "easy" | "medium" | "hard";
  tags?: string;
}

export async function bulkImportQuestionsAction(rows: BulkQuestionRow[]) {
  const { supabase, user } = await requireAdmin();

  if (!rows || rows.length === 0) {
    return { success: false, error: "কোনো প্রশ্ন প্রদান করা হয়নি।" };
  }

  let importedCount = 0;

  for (const row of rows) {
    const tagsArray = row.tags
      ? row.tags.split(",").map((t) => t.trim()).filter(Boolean)
      : [];

    const { data: q, error: qErr } = await supabase
      .from("questions")
      .insert({
        chapter_id: row.chapterId,
        body: row.body,
        image_url: row.imageUrl || null,
        difficulty: row.difficulty || "medium",
        tags: tagsArray,
        explanation: row.explanation || null,
        explanation_image_url: row.explanationImageUrl || null,
        created_by: user.id,
      })
      .select("id")
      .single();

    if (qErr || !q) continue;

    const options = [
      { question_id: q.id, body: row.optionA, image_url: row.optionAImageUrl || null, is_correct: row.correctOption === "A", sort_order: 0 },
      { question_id: q.id, body: row.optionB, image_url: row.optionBImageUrl || null, is_correct: row.correctOption === "B", sort_order: 1 },
      { question_id: q.id, body: row.optionC, image_url: row.optionCImageUrl || null, is_correct: row.correctOption === "C", sort_order: 2 },
      { question_id: q.id, body: row.optionD, image_url: row.optionDImageUrl || null, is_correct: row.correctOption === "D", sort_order: 3 },
    ];

    await supabase.from("question_options").insert(options);
    importedCount++;
  }

  revalidatePath("/questions");
  return { success: true, count: importedCount };
}

export async function deleteQuestionAction(id: string) {
  const { supabase } = await requireAdmin();
  const { error } = await supabase.from("questions").delete().eq("id", id);
  if (error) return { success: false, error: error.message };
  revalidatePath("/questions");
  return { success: true };
}

export async function updateQuestionAction(questionId: string, formData: FormData) {
  const { supabase } = await requireAdmin();

  const qImageUrl = await resolveImageUrl(
    supabase,
    formData.get("questionImage"),
    formData.get("imageUrl"),
    "headers"
  );
  const optAImg = await resolveImageUrl(
    supabase,
    formData.get("optionAImage"),
    formData.get("optionAImageUrl"),
    "options"
  );
  const optBImg = await resolveImageUrl(
    supabase,
    formData.get("optionBImage"),
    formData.get("optionBImageUrl"),
    "options"
  );
  const optCImg = await resolveImageUrl(
    supabase,
    formData.get("optionCImage"),
    formData.get("optionCImageUrl"),
    "options"
  );
  const optDImg = await resolveImageUrl(
    supabase,
    formData.get("optionDImage"),
    formData.get("optionDImageUrl"),
    "options"
  );
  const explImg = await resolveImageUrl(
    supabase,
    formData.get("explanationImage"),
    formData.get("explanationImageUrl"),
    "explanations"
  );

  const raw = {
    chapterId: formData.get("chapterId"),
    body: formData.get("body"),
    imageUrl: qImageUrl,
    difficulty: formData.get("difficulty") || "medium",
    tags: formData.get("tags") || null,
    explanation: formData.get("explanation") || null,
    explanationImageUrl: explImg,
    optionA: formData.get("optionA"),
    optionAImageUrl: optAImg,
    optionB: formData.get("optionB"),
    optionBImageUrl: optBImg,
    optionC: formData.get("optionC"),
    optionCImageUrl: optCImg,
    optionD: formData.get("optionD"),
    optionDImageUrl: optDImg,
    correctOption: formData.get("correctOption"),
  };

  const parsed = questionSchema.safeParse(raw);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  const tagsArray = parsed.data.tags
    ? parsed.data.tags.split(",").map((t) => t.trim()).filter(Boolean)
    : [];

  const { error: qError } = await supabase
    .from("questions")
    .update({
      chapter_id: parsed.data.chapterId,
      body: parsed.data.body,
      image_url: parsed.data.imageUrl || null,
      difficulty: parsed.data.difficulty,
      tags: tagsArray,
      explanation: parsed.data.explanation,
      explanation_image_url: parsed.data.explanationImageUrl || null,
    })
    .eq("id", questionId);

  if (qError) return { success: false, error: qError.message };

  await supabase.from("question_options").delete().eq("question_id", questionId);

  const options = [
    { question_id: questionId, body: parsed.data.optionA, image_url: parsed.data.optionAImageUrl || null, is_correct: parsed.data.correctOption === "A", sort_order: 0 },
    { question_id: questionId, body: parsed.data.optionB, image_url: parsed.data.optionBImageUrl || null, is_correct: parsed.data.correctOption === "B", sort_order: 1 },
    { question_id: questionId, body: parsed.data.optionC, image_url: parsed.data.optionCImageUrl || null, is_correct: parsed.data.correctOption === "C", sort_order: 2 },
    { question_id: questionId, body: parsed.data.optionD, image_url: parsed.data.optionDImageUrl || null, is_correct: parsed.data.correctOption === "D", sort_order: 3 },
  ];

  await supabase.from("question_options").insert(options);

  revalidatePath("/questions");
  return { success: true };
}

