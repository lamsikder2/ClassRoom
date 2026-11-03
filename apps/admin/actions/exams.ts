"use server";

import { requireAdmin } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const examSchema = z.object({
  title: z.string().min(1, "পরীক্ষার শিরোনাম আবশ্যক").max(200),
  description: z.string().optional().nullable(),
  scope: z.enum(["subject", "chapter", "lesson"]),
  subjectId: z.string().uuid("বিষয় নির্বাচন আবশ্যক"),
  chapterId: z.string().uuid().optional().nullable(),
  lessonId: z.string().uuid().optional().nullable(),
  mode: z.enum(["practice", "live"]).default("practice"),
  durationMinutes: z.coerce.number().min(1, "সময় অন্তত ১ মিনিট হতে হবে"),
  markPerQuestion: z.coerce.number().default(1),
  negativeMark: z.coerce.number().default(0.25),
  passPercentage: z.coerce.number().default(40),
  shuffleQuestions: z.boolean().default(true),
  shuffleOptions: z.boolean().default(true),
  maxAttempts: z.coerce.number().optional().nullable(),
  answerVisibility: z.enum(["immediately", "after_end", "never"]).default("immediately"),
  startsAt: z.string().optional().nullable(),
  endsAt: z.string().optional().nullable(),
  isPublished: z.boolean().default(false),
  questionIds: z.array(z.string().uuid()).min(1, "অন্তত একটি প্রশ্ন বাছাই করুন"),
});

export async function createExamAction(payload: z.infer<typeof examSchema>) {
  const { supabase, user } = await requireAdmin();

  const parsed = examSchema.safeParse(payload);
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message };
  }

  // ১. এক্সাম রেকর্ড তৈরি
  const { data: exam, error: examErr } = await supabase
    .from("exams")
    .insert({
      title: parsed.data.title,
      description: parsed.data.description,
      scope: parsed.data.scope,
      subject_id: parsed.data.subjectId,
      chapter_id: parsed.data.scope !== "subject" ? parsed.data.chapterId : null,
      lesson_id: parsed.data.scope === "lesson" ? parsed.data.lessonId : null,
      mode: parsed.data.mode,
      duration_sec: parsed.data.durationMinutes * 60,
      mark_per_question: parsed.data.markPerQuestion,
      negative_mark: parsed.data.negativeMark,
      pass_percentage: parsed.data.passPercentage,
      shuffle_questions: parsed.data.shuffleQuestions,
      shuffle_options: parsed.data.shuffleOptions,
      max_attempts: parsed.data.maxAttempts || null,
      answer_visibility: parsed.data.answerVisibility,
      starts_at: parsed.data.startsAt ? new Date(parsed.data.startsAt).toISOString() : null,
      ends_at: parsed.data.endsAt ? new Date(parsed.data.endsAt).toISOString() : null,
      is_published: parsed.data.isPublished,
      created_by: user.id,
    })
    .select("id")
    .single();

  if (examErr || !exam) {
    return { success: false, error: examErr?.message || "পরীক্ষা তৈরিতে ত্রুটি" };
  }

  // ২. বাছাইকৃত প্রশ্নগুলো exam_questions টেবিলে ম্যাপিং
  const mapping = parsed.data.questionIds.map((qId, idx) => ({
    exam_id: exam.id,
    question_id: qId,
    sort_order: idx,
  }));

  const { error: mapErr } = await supabase.from("exam_questions").insert(mapping);
  if (mapErr) return { success: false, error: mapErr.message };

  revalidatePath("/exams");
  return { success: true, examId: exam.id };
}

export async function deleteExamAction(id: string) {
  const { supabase } = await requireAdmin();

  // চেক: অলরেডি কোনো attempt আছে কিনা
  const { count } = await supabase
    .from("exam_attempts")
    .select("*", { count: "exact", head: true })
    .eq("exam_id", id);

  if (count && count > 0) {
    return { success: false, error: "এই পরীক্ষায় শিক্ষার্থীরা অংশগ্রহণ করেছে, তাই এটি মুছে ফেলা সম্ভব নয়।" };
  }

  const { error } = await supabase.from("exams").delete().eq("id", id);
  if (error) return { success: false, error: error.message };

  revalidatePath("/exams");
  return { success: true };
}

