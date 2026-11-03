import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { BookOpen, Plus, Trash2, ArrowRight } from "lucide-react";
import Link from "next/link";
import { createSubjectAction, deleteSubjectAction } from "@/actions/subjects";
import { EditSubjectDialog } from "@/components/subjects/edit-subject-dialog";

export default async function SubjectsPage() {
  const supabase = await createClient();

  const [{ data: subjects }, { data: levels }] = await Promise.all([
    supabase
      .from("subjects")
      .select("*, levels(name)")
      .order("sort_order", { ascending: true }),
    supabase.from("levels").select("id, name").order("sort_order"),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-text-primary">বিষয় ব্যবস্থাপনা (Subjects)</h2>
          <p className="text-sm text-text-secondary">
            পাঠ্য বিষয়সমূহ এবং তাদের অধীনস্থ অধ্যায়গুলো পরিচালনা করুন
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Subject Cards */}
        <div className="lg:col-span-2 space-y-4">
          {subjects && subjects.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {subjects.map((subject) => (
                <Card key={subject.id} className="p-4 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <div
                        className="h-10 w-10 rounded-md flex items-center justify-center font-bold text-white shadow-sm"
                        style={{ backgroundColor: subject.color_hex || "#4F46E5" }}
                      >
                        <BookOpen className="h-5 w-5" />
                      </div>
                      <span className="text-xs px-2 py-0.5 rounded-full bg-surface-variant font-medium text-text-secondary">
                        {(subject.levels as unknown as { name: string })?.name || "স্তরহীন"}
                      </span>
                    </div>

                    <h3 className="font-semibold text-text-primary text-base">
                      {subject.name}
                    </h3>
                    {subject.name_en && (
                      <p className="text-xs text-text-muted">{subject.name_en}</p>
                    )}
                  </div>

                  <div className="flex items-center justify-between pt-4 mt-4 border-t border-border">
                    <Link href={`/subjects/${subject.id}/chapters`}>
                      <Button size="sm" variant="outline" className="gap-1.5 text-xs">
                        অধ্যায়সমূহ
                        <ArrowRight className="h-3.5 w-3.5" />
                      </Button>
                    </Link>

                    <div className="flex items-center gap-1">
                      <EditSubjectDialog subject={subject} levels={levels || []} />
                      <form action={async () => { "use server"; await deleteSubjectAction(subject.id); }}>
                        <Button variant="ghost" size="icon" className="h-8 w-8 text-text-muted hover:text-destructive">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </form>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={<BookOpen className="h-8 w-8" />}
              title="কোনো বিষয় যোগ করা হয়নি"
              description="এখনো কোনো বিষয় তৈরি হয়নি। ডানপাশের ফর্ম ব্যবহার করে প্রথম বিষয়টি যুক্ত করুন।"
            />
          )}
        </div>

        {/* Add Subject Form */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Plus className="h-4 w-4 text-primary" />
                নতুন বিষয় যুক্ত করুন
              </CardTitle>
              <CardDescription>
                লেভেলের অধীনে নতুন বিষয় যুক্ত করুন
              </CardDescription>
            </CardHeader>
            <CardContent>
              {levels && levels.length > 0 ? (
                <form action={async (formData: FormData) => { "use server"; await createSubjectAction(formData); }} className="space-y-4">
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      স্তর নির্বাচন করুন *
                    </label>
                    <select
                      name="levelId"
                      required
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      {levels.map((lvl) => (
                        <option key={lvl.id} value={lvl.id}>
                          {lvl.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      বিষয়ের নাম (বাংলা) *
                    </label>
                    <input
                      name="name"
                      placeholder="যেমন: পদার্থবিজ্ঞান ১ম পত্র"
                      required
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      ইংরেজি নাম
                    </label>
                    <input
                      name="nameEn"
                      placeholder="Physics 1st Paper"
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      স্লাগ (Slug) *
                    </label>
                    <input
                      name="slug"
                      placeholder="physics-1st"
                      required
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      থিম কালার (HEX Code)
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        name="colorHex"
                        defaultValue="#0284C7"
                        className="h-10 w-12 rounded border border-border cursor-pointer bg-surface"
                      />
                      <span className="text-xs text-text-muted">
                        অ্যাপে কার্ডের ব্যাকগ্রাউন্ড হিসেবে ব্যবহৃত হবে
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <input
                      type="checkbox"
                      id="subIsPublished"
                      name="isPublished"
                      value="true"
                      defaultChecked
                      className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                    />
                    <label htmlFor="subIsPublished" className="text-sm font-medium text-text-primary">
                      তৎক্ষণাৎ প্রকাশ করুন
                    </label>
                  </div>

                  <Button type="submit" className="w-full mt-4">
                    সংরক্ষণ করুন
                  </Button>
                </form>
              ) : (
                <div className="text-sm text-amber-600 bg-amber-50 dark:bg-amber-950/50 p-3 rounded-md">
                  বিষয় তৈরি করার পূর্বে অন্তত একটি স্তর (Level) তৈরি করে নিন।
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
