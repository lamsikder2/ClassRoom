"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { CheckCircle2, ChevronRight, ChevronLeft, Loader2, HelpCircle } from "lucide-react";
import { toast } from "sonner";
import { createExamAction } from "@/actions/exams";

interface Props {
  subjects: Array<{ id: string; name: string }>;
  chapters: Array<{ id: string; subject_id: string; title: string }>;
  questions: Array<{ id: string; chapter_id: string; body: string; difficulty: string }>;
}

export function ExamWizardForm({ subjects, chapters, questions }: Props) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // Form State
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [scope, setScope] = useState<"subject" | "chapter" | "lesson">("chapter");
  const [subjectId, setSubjectId] = useState(subjects[0]?.id || "");
  const [chapterId, setChapterId] = useState("");
  const [mode, setMode] = useState<"practice" | "live">("practice");
  const [durationMinutes, setDurationMinutes] = useState(30);
  const [markPerQuestion, setMarkPerQuestion] = useState(1);
  const [negativeMark, setNegativeMark] = useState(0.25);
  const [passPercentage, setPassPercentage] = useState(40);
  const [shuffleQuestions, setShuffleQuestions] = useState(true);
  const [shuffleOptions, setShuffleOptions] = useState(true);
  const [maxAttempts, setMaxAttempts] = useState<number | undefined>(undefined);
  const [answerVisibility, setAnswerVisibility] = useState<"immediately" | "after_end" | "never">("immediately");
  const [startsAt, setStartsAt] = useState("");
  const [endsAt, setEndsAt] = useState("");
  const [isPublished, setIsPublished] = useState(true);
  const [selectedQuestions, setSelectedQuestions] = useState<string[]>([]);

  const filteredChapters = chapters.filter((c) => c.subject_id === subjectId);
  const filteredQuestions = chapterId
    ? questions.filter((q) => q.chapter_id === chapterId)
    : questions;

  const toggleQuestion = (qId: string) => {
    setSelectedQuestions((prev) =>
      prev.includes(qId) ? prev.filter((id) => id !== qId) : [...prev, qId]
    );
  };

  const selectAllFiltered = () => {
    const ids = filteredQuestions.map((q) => q.id);
    setSelectedQuestions((prev) => Array.from(new Set([...prev, ...ids])));
  };

  const handleSubmit = async () => {
    if (!title) {
      toast.error("পরীক্ষার শিরোনাম দিন");
      return;
    }
    if (selectedQuestions.length === 0) {
      toast.error("অন্তত একটি প্রশ্ন বাছাই করুন");
      return;
    }

    setLoading(true);
    try {
      const res = await createExamAction({
        title,
        description,
        scope,
        subjectId,
        chapterId: scope !== "subject" ? chapterId || null : null,
        mode,
        durationMinutes,
        markPerQuestion,
        negativeMark,
        passPercentage,
        shuffleQuestions,
        shuffleOptions,
        maxAttempts: maxAttempts || null,
        answerVisibility,
        startsAt: mode === "live" ? startsAt : null,
        endsAt: mode === "live" ? endsAt : null,
        isPublished,
        questionIds: selectedQuestions,
      });

      if (res.success) {
        toast.success("পরীক্ষাটি সফলভাবে তৈরি হয়েছে!");
        router.push("/exams");
      } else {
        toast.error("পরীক্ষা তৈরিতে ব্যর্থ: " + res.error);
      }
    } catch {
      toast.error("একটি ত্রুটি ঘটেছে। আবার চেষ্টা করুন।");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Wizard Step Indicator */}
      <div className="flex items-center justify-between bg-surface p-4 rounded-lg border border-border">
        {[
          { num: 1, label: "মৌলিক তথ্য" },
          { num: 2, label: "নিয়মাবলী ও সময়" },
          { num: 3, label: "প্রশ্ন বাছাই" },
          { num: 4, label: "পর্যালোচনা ও প্রকাশ" },
        ].map((s) => (
          <div
            key={s.num}
            className={`flex items-center gap-2 text-xs font-semibold ${
              step >= s.num ? "text-primary" : "text-text-muted"
            }`}
          >
            <div
              className={`h-7 w-7 rounded-full flex items-center justify-center font-bold text-xs ${
                step >= s.num
                  ? "bg-primary text-white"
                  : "bg-surface-variant text-text-muted border border-border"
              }`}
            >
              {s.num}
            </div>
            <span className="hidden sm:inline">{s.label}</span>
          </div>
        ))}
      </div>

      {/* Step 1: Basic Info */}
      {step === 1 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">ধাপ ১: মৌলিক তথ্য</CardTitle>
            <CardDescription>পরীক্ষার নাম, পরিধি ও বিষয় নির্ধারণ করুন</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">পরীক্ষার শিরোনাম *</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="যেমন: ভেক্টর অধ্যায় কুইজ - ০১"
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">পরীক্ষার পরিধি (Scope) *</label>
                <select
                  value={scope}
                  onChange={(e) => setScope(e.target.value as unknown as "subject" | "chapter" | "lesson")}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="chapter">অধ্যায়ভিত্তিক (Chapter-scoped)</option>
                  <option value="subject">বিষয়ভিত্তিক / পূর্ণাঙ্গ মডেল টেস্ট</option>
                  <option value="lesson">ক্লাসভিত্তিক কুইজ</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">পরীক্ষার মোড *</label>
                <select
                  value={mode}
                  onChange={(e) => setMode(e.target.value as "practice" | "live")}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="practice">প্র্যাকটিস (যেকোনো সময় দেওয়া যাবে)</option>
                  <option value="live">লাইভ এক্সাম (নির্দিষ্ট সময়সূচি)</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">বিষয় নির্বাচন *</label>
                <select
                  value={subjectId}
                  onChange={(e) => {
                    setSubjectId(e.target.value);
                    setChapterId("");
                  }}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  {subjects.map((sub) => (
                    <option key={sub.id} value={sub.id}>
                      {sub.name}
                    </option>
                  ))}
                </select>
              </div>

              {scope !== "subject" && (
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">অধ্যায় নির্বাচন *</label>
                  <select
                    value={chapterId}
                    onChange={(e) => setChapterId(e.target.value)}
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  >
                    <option value="">অধ্যায় বেছে নিন</option>
                    {filteredChapters.map((ch) => (
                      <option key={ch.id} value={ch.id}>
                        {ch.title}
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {mode === "live" && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-4 rounded-md bg-surface-variant">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-text-primary">পরীক্ষা শুরু (Starts At)</label>
                  <input
                    type="datetime-local"
                    value={startsAt}
                    onChange={(e) => setStartsAt(e.target.value)}
                    className="flex h-9 w-full rounded-md border border-border bg-surface px-2.5 text-xs text-text-primary"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-text-primary">পরীক্ষা সমাপ্তি (Ends At)</label>
                  <input
                    type="datetime-local"
                    value={endsAt}
                    onChange={(e) => setEndsAt(e.target.value)}
                    className="flex h-9 w-full rounded-md border border-border bg-surface px-2.5 text-xs text-text-primary"
                  />
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Step 2: Rules & Timing */}
      {step === 2 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">ধাপ ২: নিয়মাবলী ও সময় নির্ধারণ</CardTitle>
            <CardDescription>সময়কাল, নম্বর বণ্টন ও নেগেটিভ মার্কিং সেটিংস</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">সময়সীমা (মিনিটে) *</label>
                <input
                  type="number"
                  value={durationMinutes}
                  onChange={(e) => setDurationMinutes(Number(e.target.value))}
                  min={1}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">প্রতি প্রশ্নে নম্বর *</label>
                <input
                  type="number"
                  step="0.5"
                  value={markPerQuestion}
                  onChange={(e) => setMarkPerQuestion(Number(e.target.value))}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">ভুল উত্তরের পেনাল্টি (নেগেটিভ)</label>
                <input
                  type="number"
                  step="0.05"
                  value={negativeMark}
                  onChange={(e) => setNegativeMark(Number(e.target.value))}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">উত্তর প্রকাশের নিয়ম (Visibility)</label>
                <select
                  value={answerVisibility}
                  onChange={(e) => setAnswerVisibility(e.target.value as "immediately" | "after_end" | "never")}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
                >
                  <option value="immediately">পরীক্ষা শেষেই সাথে সাথে (Immediately)</option>
                  <option value="after_end">লাইভ পরীক্ষার সময়সীমা পার হওয়ার পর</option>
                  <option value="never">কখনোই সঠিক উত্তর প্রকাশ করা হবে না</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-text-primary">পাস শতকরা হার (%)</label>
                <input
                  type="number"
                  value={passPercentage}
                  onChange={(e) => setPassPercentage(Number(e.target.value))}
                  className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
                />
              </div>
            </div>

            <div className="space-y-2 pt-3 border-t border-border">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={shuffleQuestions}
                  onChange={(e) => setShuffleQuestions(e.target.checked)}
                  className="h-4 w-4 text-primary rounded"
                />
                <span className="text-sm text-text-primary font-medium">
                  প্রতিটি শিক্ষার্থীর জন্য প্রশ্নসমূহ এলোমেলো (Shuffle) করুন
                </span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={shuffleOptions}
                  onChange={(e) => setShuffleOptions(e.target.checked)}
                  className="h-4 w-4 text-primary rounded"
                />
                <span className="text-sm text-text-primary font-medium">
                  অপশনসমূহ (A, B, C, D) এলোমেলো (Shuffle) করুন
                </span>
              </label>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Step 3: Question Picker */}
      {step === 3 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle className="text-base">ধাপ ৩: প্রশ্ন বাছাই</CardTitle>
              <CardDescription>
                মোট {filteredQuestions.length}টি প্রশ্ন উপলব্ধ • নির্বাচিত: {selectedQuestions.length}টি
              </CardDescription>
            </div>
            <Button size="sm" variant="outline" onClick={selectAllFiltered} className="text-xs">
              এই অধ্যায়ের সব নির্বাচন করুন
            </Button>
          </CardHeader>
          <CardContent>
            {filteredQuestions.length > 0 ? (
              <div className="max-h-96 overflow-y-auto space-y-2.5 pr-2">
                {filteredQuestions.map((q) => {
                  const isSelected = selectedQuestions.includes(q.id);

                  return (
                    <div
                      key={q.id}
                      onClick={() => toggleQuestion(q.id)}
                      className={`p-3 rounded-md border text-xs cursor-pointer flex items-start gap-3 transition-colors ${
                        isSelected
                          ? "bg-primary-surface border-primary"
                          : "bg-surface border-border hover:bg-surface-variant"
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => {}}
                        className="h-4 w-4 text-primary rounded mt-0.5 shrink-0"
                      />
                      <div className="flex-1">
                        <p className="font-medium text-text-primary line-clamp-2">
                          {q.body}
                        </p>
                        <Badge variant="outline" className="mt-1 text-[10px]">
                          {q.difficulty}
                        </Badge>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="py-12 text-center text-sm text-text-muted">
                এই বিষয়ের বা অধ্যায়ের কোনো প্রশ্ন পাওয়া যায়নি। কোশ্চেন ব্যাংকে আগে প্রশ্ন যোগ করুন।
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Step 4: Summary */}
      {step === 4 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">ধাপ ৪: পর্যালোচনা ও প্রকাশ</CardTitle>
            <CardDescription>পরীক্ষার তথ্য যাচাই করে প্রকাশ সম্পন্ন করুন</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-3 p-4 bg-surface-variant rounded-md">
              <div>
                <span className="text-text-muted text-xs">শিরোনাম:</span>
                <p className="font-bold text-text-primary">{title}</p>
              </div>
              <div>
                <span className="text-text-muted text-xs">মোড ও পরিধি:</span>
                <p className="font-bold text-text-primary capitalize">{mode} ({scope})</p>
              </div>
              <div>
                <span className="text-text-muted text-xs">মোট প্রশ্ন:</span>
                <p className="font-bold text-primary">{selectedQuestions.length}টি</p>
              </div>
              <div>
                <span className="text-text-muted text-xs">মোট নম্বর:</span>
                <p className="font-bold text-text-primary">
                  {selectedQuestions.length * markPerQuestion} (সময়: {durationMinutes} মি.)
                </p>
              </div>
            </div>

            <label className="flex items-center gap-2 cursor-pointer pt-2">
              <input
                type="checkbox"
                checked={isPublished}
                onChange={(e) => setIsPublished(e.target.checked)}
                className="h-4 w-4 text-primary rounded"
              />
              <span className="font-semibold text-text-primary">
                তৎক্ষণাৎ প্রকাশ করুন (শিক্ষার্থীরা তাদের অ্যাপে দেখতে পাবে)
              </span>
            </label>
          </CardContent>
        </Card>
      )}

      {/* Footer Navigation Buttons */}
      <div className="flex justify-between items-center pt-2">
        {step > 1 ? (
          <Button variant="outline" onClick={() => setStep((s) => s - 1)}>
            <ChevronLeft className="h-4 w-4 mr-1" />
            পূর্ববর্তী ধাপ
          </Button>
        ) : (
          <div />
        )}

        {step < 4 ? (
          <Button onClick={() => setStep((s) => s + 1)} className="gap-1">
            পরবর্তী ধাপ
            <ChevronRight className="h-4 w-4" />
          </Button>
        ) : (
          <Button onClick={handleSubmit} disabled={loading} className="gap-1.5">
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                সংরক্ষণ হচ্ছে...
              </>
            ) : (
              <>
                <CheckCircle2 className="h-4 w-4" />
                পরীক্ষা প্রকাশ করুন
              </>
            )}
          </Button>
        )}
      </div>
    </div>
  );
}

