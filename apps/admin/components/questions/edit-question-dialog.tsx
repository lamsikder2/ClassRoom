"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2, HelpCircle } from "lucide-react";
import { updateQuestionAction } from "@/actions/questions";
import { toast } from "sonner";

interface Chapter {
  id: string;
  title: string;
  subjects?: { name: string } | null;
}

interface QuestionOption {
  id: string;
  body: string;
  image_url?: string | null;
  is_correct: boolean;
  sort_order: number;
}

interface Question {
  id: string;
  chapter_id: string;
  body: string;
  image_url?: string | null;
  difficulty: string;
  tags?: string[] | null;
  explanation?: string | null;
  explanation_image_url?: string | null;
  question_options?: QuestionOption[] | null;
}

export function EditQuestionDialog({
  question,
  chapters,
}: {
  question: any;
  chapters: any[];
}) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  // Sort options by sort_order
  const sortedOptions = [...(question.question_options || [])].sort(
    (a, b) => a.sort_order - b.sort_order
  );
  const optA = sortedOptions[0] || { body: "", is_correct: false };
  const optB = sortedOptions[1] || { body: "", is_correct: false };
  const optC = sortedOptions[2] || { body: "", is_correct: false };
  const optD = sortedOptions[3] || { body: "", is_correct: false };

  let defaultCorrect = "A";
  if (optB.is_correct) defaultCorrect = "B";
  else if (optC.is_correct) defaultCorrect = "C";
  else if (optD.is_correct) defaultCorrect = "D";

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateQuestionAction(question.id, formData);
      if (res.success) {
        toast.success("প্রশ্ন সফলভাবে আপডেট করা হয়েছে!");
        setOpen(false);
      } else {
        toast.error(res.error || "আপডেট ব্যর্থ হয়েছে");
      }
    } catch (err: any) {
      toast.error(err.message || "ত্রুটি ঘটেছে");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Button
        variant="ghost"
        size="icon"
        onClick={() => setOpen(true)}
        className="h-8 w-8 text-text-muted hover:text-primary"
        title="প্রশ্ন সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit Question</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="প্রশ্ন সম্পাদনা করুন (Edit Question)"
        description="প্রশ্ন, ছবি, অপশন এবং সঠিক উত্তর পরিবর্তন করুন"
        className="max-w-2xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              অধ্যায় নির্বাচন করুন *
            </label>
            <select
              name="chapterId"
              defaultValue={question.chapter_id}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              {chapters.map((ch) => (
                <option key={ch.id} value={ch.id}>
                  {ch.subjects ? `${ch.subjects.name} — ` : ""}
                  {ch.title}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              প্রশ্নের বিবরণ (Text / LaTeX Math $...$) *
            </label>
            <textarea
              name="body"
              defaultValue={question.body}
              required
              rows={3}
              className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary font-mono"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              প্রশ্নের ছবির URL (ঐচ্ছিক)
            </label>
            <input
              name="imageUrl"
              defaultValue={question.image_url || ""}
              placeholder="https://... বা ড্রাইভ লিংক"
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                কঠিনতার স্তর (Difficulty)
              </label>
              <select
                name="difficulty"
                defaultValue={question.difficulty}
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
              >
                <option value="easy">সহজ (Easy)</option>
                <option value="medium">মাঝারি (Medium)</option>
                <option value="hard">কঠিন (Hard)</option>
              </select>
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                সঠিক উত্তর *
              </label>
              <select
                name="correctOption"
                defaultValue={defaultCorrect}
                required
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary font-bold text-emerald-600"
              >
                <option value="A">অপশন (ক / A)</option>
                <option value="B">অপশন (খ / B)</option>
                <option value="C">অপশন (গ / C)</option>
                <option value="D">অপশন (ঘ / D)</option>
              </select>
            </div>
          </div>

          {/* Options A, B, C, D */}
          <div className="space-y-3 pt-2 border-t border-border">
            <span className="text-xs font-bold text-text-secondary uppercase tracking-wider">
              অপশনসমূহ (Options)
            </span>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="text-xs font-semibold text-text-primary">
                  অপশন ক (A) *
                </label>
                <input
                  name="optionA"
                  defaultValue={optA.body}
                  required
                  className="flex h-9 w-full rounded-md border border-border bg-surface px-3 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <input
                  name="optionAImageUrl"
                  defaultValue={optA.image_url || ""}
                  placeholder="অপশন A ছবির URL (যদি থাকে)"
                  className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 py-1 text-[11px] text-text-muted focus:outline-none"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-text-primary">
                  অপশন খ (B) *
                </label>
                <input
                  name="optionB"
                  defaultValue={optB.body}
                  required
                  className="flex h-9 w-full rounded-md border border-border bg-surface px-3 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <input
                  name="optionBImageUrl"
                  defaultValue={optB.image_url || ""}
                  placeholder="অপশন B ছবির URL (যদি থাকে)"
                  className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 py-1 text-[11px] text-text-muted focus:outline-none"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-text-primary">
                  অপশন গ (C) *
                </label>
                <input
                  name="optionC"
                  defaultValue={optC.body}
                  required
                  className="flex h-9 w-full rounded-md border border-border bg-surface px-3 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <input
                  name="optionCImageUrl"
                  defaultValue={optC.image_url || ""}
                  placeholder="অপশন C ছবির URL (যদি থাকে)"
                  className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 py-1 text-[11px] text-text-muted focus:outline-none"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-text-primary">
                  অপশন ঘ (D) *
                </label>
                <input
                  name="optionD"
                  defaultValue={optD.body}
                  required
                  className="flex h-9 w-full rounded-md border border-border bg-surface px-3 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <input
                  name="optionDImageUrl"
                  defaultValue={optD.image_url || ""}
                  placeholder="অপশন D ছবির URL (যদি থাকে)"
                  className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 py-1 text-[11px] text-text-muted focus:outline-none"
                />
              </div>
            </div>
          </div>

          {/* Explanation */}
          <div className="space-y-1.5 pt-2 border-t border-border">
            <label className="text-xs font-semibold text-text-primary">
              ব্যাখ্যা ও সমাধান (Explanation)
            </label>
            <textarea
              name="explanation"
              defaultValue={question.explanation || ""}
              rows={2}
              placeholder="সঠিক উত্তরের ব্যাখ্যা..."
              className="flex w-full rounded-md border border-border bg-surface px-3 py-1.5 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
            <input
              name="explanationImageUrl"
              defaultValue={question.explanation_image_url || ""}
              placeholder="ব্যাখ্যার ছবির লিংক (যদি থাকে)"
              className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 py-1 text-[11px] text-text-muted focus:outline-none"
            />
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-border">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setOpen(false)}
            >
              বাতিল
            </Button>
            <Button type="submit" size="sm" disabled={loading}>
              {loading && <Loader2 className="mr-1.5 h-3.5 w-3.5 animate-spin" />}
              সংরক্ষণ করুন
            </Button>
          </div>
        </form>
      </Dialog>
    </>
  );
}
