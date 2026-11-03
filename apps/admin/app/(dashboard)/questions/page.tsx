import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { HelpCircle, Plus, Trash2, FileSpreadsheet, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { createQuestionAction, deleteQuestionAction } from "@/actions/questions";
import { EditQuestionDialog } from "@/components/questions/edit-question-dialog";

interface Props {
  searchParams: Promise<{ chapterId?: string }>;
}

export default async function QuestionBankPage({ searchParams }: Props) {
  const { chapterId } = await searchParams;
  const supabase = await createClient();

  const [{ data: chapters }, { data: questions }] = await Promise.all([
    supabase.from("chapters").select("id, title, subjects(name)").order("sort_order"),
    chapterId
      ? supabase
          .from("questions")
          .select("*, chapters(title), question_options(*)")
          .eq("chapter_id", chapterId)
          .order("created_at", { ascending: false })
      : supabase
          .from("questions")
          .select("*, chapters(title), question_options(*)")
          .order("created_at", { ascending: false })
          .limit(50),
  ]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-primary">কোশ্চেন ব্যাংক (Question Bank)</h2>
          <p className="text-sm text-text-secondary">
            অধ্যায়ভিত্তিক এমসিকিউ প্রশ্ন ও সমাধান সংরক্ষণ করুন
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Link href="/questions/import">
            <Button variant="outline" size="sm" className="gap-1.5 text-xs">
              <FileSpreadsheet className="h-4 w-4 text-emerald-600" />
              এক্সেল বাল্ক ইমপোর্ট
            </Button>
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Questions List */}
        <div className="lg:col-span-2 space-y-4">
          {questions && questions.length > 0 ? (
            <div className="space-y-4">
              {questions.map((q, idx) => (
                <Card key={q.id} className="p-4 space-y-3">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-3">
                      <span className="font-bold text-xs px-2 py-1 rounded bg-surface-variant text-text-muted mt-0.5">
                        #{idx + 1}
                      </span>
                      <div>
                        <p className="text-sm font-medium text-text-primary whitespace-pre-line">
                          {q.body}
                        </p>
                        {q.image_url && (
                          <div className="mt-2.5">
                            <img
                              src={q.image_url}
                              alt="Question Diagram"
                              className="max-h-48 rounded-lg border border-border object-contain bg-surface-variant p-1 shadow-sm"
                            />
                          </div>
                        )}
                        <div className="flex items-center gap-2 mt-2">
                          <span className="text-[11px] text-text-muted">
                            অধ্যায়: {(q.chapters as unknown as { title: string })?.title}
                          </span>
                          <span className="text-text-muted">•</span>
                          <Badge variant={q.difficulty === "easy" ? "success" : q.difficulty === "hard" ? "destructive" : "secondary"}>
                            {q.difficulty}
                          </Badge>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-1">
                      <EditQuestionDialog question={q} chapters={chapters || []} />
                      <form action={async () => { "use server"; await deleteQuestionAction(q.id); }}>
                        <Button variant="ghost" size="icon" className="h-8 w-8 text-text-muted hover:text-destructive">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </form>
                    </div>
                  </div>

                  {/* Options List */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2 border-t border-border">
                    {(q.question_options as unknown as Array<{ id: string; body: string; image_url?: string; is_correct: boolean }>)?.map((opt) => (
                      <div
                        key={opt.id}
                        className={`p-2.5 rounded text-xs flex flex-col gap-1.5 border ${
                          opt.is_correct
                            ? "bg-emerald-50 dark:bg-emerald-950/40 border-emerald-500 text-emerald-900 dark:text-emerald-200 font-semibold"
                            : "bg-surface border-border text-text-secondary"
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="truncate">{opt.body}</span>
                          {opt.is_correct && <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600 shrink-0" />}
                        </div>
                        {opt.image_url && (
                          <img
                            src={opt.image_url}
                            alt="Option"
                            className="max-h-20 rounded object-contain border border-border bg-white"
                          />
                        )}
                      </div>
                    ))}
                  </div>

                  {(q.explanation || q.explanation_image_url) && (
                    <div className="text-xs text-text-muted bg-surface-variant p-2.5 rounded space-y-2">
                      {q.explanation && (
                        <div>
                          <strong className="text-text-secondary">💡 সমাধান/ব্যাখ্যা:</strong> {q.explanation}
                        </div>
                      )}
                      {q.explanation_image_url && (
                        <img
                          src={q.explanation_image_url}
                          alt="Explanation diagram"
                          className="max-h-36 rounded border border-border object-contain"
                        />
                      )}
                    </div>
                  )}
                </Card>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={<HelpCircle className="h-8 w-8" />}
              title="কোশ্চেন ব্যাংক ফাঁকা"
              description="এখনো কোনো প্রশ্ন যোগ করা হয়নি। ডানপাশের ফর্ম দিয়ে সরাসরি প্রশ্ন যোগ করুন অথবা এক্সেল ফাইল ইমপোর্ট করুন।"
            />
          )}
        </div>

        {/* Add Question Form */}
        <div>
          <Card>
            <div className="p-6">
              <h3 className="text-base font-semibold text-text-primary flex items-center gap-2 mb-1">
                <Plus className="h-4 w-4 text-primary" />
                একক প্রশ্ন যুক্ত করুন
              </h3>
              <p className="text-xs text-text-secondary mb-4">
                প্রশ্ন ও ৪টি অপশন লিখে সঠিক উত্তর মার্ক করুন
              </p>

              {chapters && chapters.length > 0 ? (
                <form action={async (formData: FormData) => { "use server"; await createQuestionAction(formData); }} className="space-y-4">
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      অধ্যায় নির্বাচন করুন *
                    </label>
                    <select
                      name="chapterId"
                      defaultValue={chapterId || chapters[0].id}
                      required
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      {chapters.map((ch) => (
                        <option key={ch.id} value={ch.id}>
                          {(ch.subjects as unknown as { name: string })?.name} → {ch.title}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      প্রশ্ন (Markdown / LaTeX সমীকরণ $...$) *
                    </label>
                    <textarea
                      name="body"
                      placeholder="যেমন: দুটি ভেক্টরের লব্ধির মান $R=\sqrt{P^2+Q^2}$ হলে..."
                      required
                      rows={3}
                      className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  {/* Question Image (URL or file) */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-text-primary flex items-center justify-between">
                      <span>প্রশ্নের চিত্র/ডায়াগ্রাম (ঐচ্ছিক)</span>
                      <span className="text-[11px] text-text-muted font-normal">URL বা ছবি আপলোড</span>
                    </label>
                    <div className="space-y-1.5">
                      <input
                        type="url"
                        name="imageUrl"
                        placeholder="চিত্রের সরাসরি URL (যেমন: https://...)"
                        className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-1 focus:ring-primary"
                      />
                      <input
                        type="file"
                        name="questionImage"
                        accept="image/png,image/jpeg,image/webp,image/svg+xml"
                        className="flex h-8 w-full rounded-md border border-border bg-surface px-2 py-1 text-xs text-text-secondary file:mr-2 file:py-0.5 file:px-2 file:rounded file:border-0 file:text-[11px] file:bg-primary/10 file:text-primary cursor-pointer"
                      />
                    </div>
                  </div>

                  {/* 4 Options with Correct Answer Selector and Optional Image */}
                  <div className="space-y-3 pt-2">
                    <label className="text-xs font-bold text-text-primary uppercase tracking-wider">
                      ৪টি অপশন ও সঠিক উত্তর নির্ধারণ *
                    </label>

                    {(["A", "B", "C", "D"] as const).map((letter) => (
                      <div key={letter} className="p-2.5 rounded-lg border border-border bg-surface-variant/30 space-y-1.5">
                        <div className="flex items-center gap-2">
                          <input
                            type="radio"
                            name="correctOption"
                            value={letter}
                            required
                            id={`opt-${letter}`}
                            className="h-4 w-4 text-primary focus:ring-primary cursor-pointer"
                          />
                          <label htmlFor={`opt-${letter}`} className="text-xs font-bold w-4 text-text-primary cursor-pointer">
                            {letter}
                          </label>
                          <input
                            name={`option${letter}`}
                            placeholder={`অপশন (${letter}) টেক্সট বা LaTeX যেমন $90^\\circ$`}
                            required
                            className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-1 focus:ring-primary"
                          />
                        </div>
                        <div className="pl-6">
                          <input
                            type="url"
                            name={`option${letter}ImageUrl`}
                            placeholder={`অপশন (${letter}) চিত্র URL (ঐচ্ছিক)`}
                            className="flex h-7 w-full rounded-md border border-border/80 bg-surface px-2.5 text-[11px] text-text-primary placeholder:text-text-muted/70 focus:outline-none focus:ring-1 focus:ring-primary"
                          />
                        </div>
                      </div>
                    ))}
                    <p className="text-[11px] text-text-muted">
                      সঠিক উত্তরের পাশের রেডিও বাটনে ক্লিক করুন।
                    </p>
                  </div>

                  <div className="space-y-1.5 pt-2">
                    <label className="text-sm font-medium text-text-primary">
                      ব্যাখ্যা / সমাধান (ঐচ্ছিক)
                    </label>
                    <textarea
                      name="explanation"
                      placeholder="সঠিক উত্তরের যুক্তি..."
                      rows={2}
                      className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                    <input
                      type="url"
                      name="explanationImageUrl"
                      placeholder="ব্যাখ্যার চিত্র URL (ঐচ্ছিক)"
                      className="flex h-8 w-full rounded-md border border-border bg-surface px-2.5 text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-1 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      কঠিনতার স্তর (Difficulty)
                    </label>
                    <select
                      name="difficulty"
                      defaultValue="medium"
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      <option value="easy">সহজ (Easy)</option>
                      <option value="medium">মাঝারি (Medium)</option>
                      <option value="hard">কঠিন (Hard)</option>
                    </select>
                  </div>

                  <Button type="submit" className="w-full mt-4">
                    প্রশ্ন সংরক্ষণ করুন
                  </Button>
                </form>
              ) : (
                <div className="text-sm text-amber-600 bg-amber-50 dark:bg-amber-950/50 p-3 rounded-md">
                  প্রশ্ন তৈরি করার পূর্বে অন্তত একটি অধ্যায় তৈরি করুন।
                </div>
              )}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
