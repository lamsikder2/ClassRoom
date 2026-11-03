import { createClient } from "@/lib/supabase/server";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { Video, Plus, Trash2, FileText, CheckCircle, Clock } from "lucide-react";
import Link from "next/link";
import Image from "next/image";
import { createLessonAction, deleteLessonAction } from "@/actions/lessons";
import { EditLessonDialog } from "@/components/lessons/edit-lesson-dialog";

interface Props {
  searchParams: Promise<{ chapterId?: string }>;
}

export default async function LessonsPage({ searchParams }: Props) {
  const { chapterId } = await searchParams;
  const supabase = await createClient();

  const [{ data: chapters }, { data: lessons }] = await Promise.all([
    supabase.from("chapters").select("id, title, subjects(name)").order("sort_order"),
    chapterId
      ? supabase
          .from("lessons")
          .select("*, chapters(title, subjects(name)), materials(count)")
          .eq("chapter_id", chapterId)
          .order("sort_order")
      : supabase
          .from("lessons")
          .select("*, chapters(title, subjects(name)), materials(count)")
          .order("created_at", { ascending: false })
          .limit(50),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-primary">ক্লাস ব্যবস্থাপনা (Lessons)</h2>
          <p className="text-sm text-text-secondary">
            ক্লাসের ভিডিও লিংক, বর্ণনা এবং সহায়ক উপাদান সংযুক্ত করুন
          </p>
        </div>

        {/* Filter by Chapter */}
        {chapters && chapters.length > 0 && (
          <form className="flex items-center gap-2">
            <select
              name="chapterId"
              defaultValue={chapterId || ""}
              className="h-9 rounded-md border border-border bg-surface px-3 text-xs text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="">সকল অধ্যায়ের ক্লাস</option>
              {chapters.map((ch) => (
                <option key={ch.id} value={ch.id}>
                  {(ch.subjects as unknown as { name: string })?.name} → {ch.title}
                </option>
              ))}
            </select>
            <Button size="sm" variant="outline" type="submit" className="text-xs">
              ফিল্টার
            </Button>
          </form>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Lessons List */}
        <div className="lg:col-span-2 space-y-4">
          {lessons && lessons.length > 0 ? (
            <div className="space-y-3">
              {lessons.map((lesson) => (
                <Card key={lesson.id} className="p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                  <div className="flex items-start gap-4">
                    {/* Thumbnail */}
                    <div className="h-16 w-28 bg-surface-variant rounded-md overflow-hidden shrink-0 relative flex items-center justify-center border border-border">
                      {lesson.thumbnail_url ? (
                        <Image
                          src={lesson.thumbnail_url}
                          alt={lesson.title}
                          fill
                          className="object-cover"
                        />
                      ) : (
                        <Video className="h-6 w-6 text-text-muted" />
                      )}
                    </div>

                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-text-primary text-sm line-clamp-1">
                          {lesson.title}
                        </span>
                        {lesson.is_published && (
                          <CheckCircle className="h-3.5 w-3.5 text-emerald-600 shrink-0" />
                        )}
                      </div>

                      <p className="text-xs text-text-muted mt-0.5">
                        অধ্যায়: {(lesson.chapters as unknown as { title: string })?.title || "অনির্দিষ্ট"}
                      </p>

                      <div className="flex items-center gap-3 mt-2 text-xs text-text-secondary">
                        {lesson.video_duration_sec && (
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {Math.round(lesson.video_duration_sec / 60)} মিনিট
                          </span>
                        )}
                        <span>
                          শিট ও নোট: {(lesson.materials as unknown as Array<{ count: number }>)?.[0]?.count ?? 0}টি
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 self-end sm:self-center">
                    <Link href={`/lessons/${lesson.id}/materials`}>
                      <Button size="sm" variant="outline" className="gap-1.5 text-xs">
                        <FileText className="h-3.5 w-3.5 text-primary" />
                        শিট ও নোট
                      </Button>
                    </Link>

                    <div className="flex items-center gap-1">
                      <EditLessonDialog lesson={lesson} chapters={chapters || []} />
                      <form action={async () => { "use server"; await deleteLessonAction(lesson.chapter_id, lesson.id); }}>
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
              icon={<Video className="h-8 w-8" />}
              title="কোনো ক্লাস যোগ করা হয়নি"
              description="এখনো কোনো ক্লাস যুক্ত করা হয়নি। ডানপাশের ফর্ম ব্যবহার করে ক্লাসের ভিডিও যুক্ত করুন।"
            />
          )}
        </div>

        {/* Add Lesson Form */}
        <div>
          <Card>
            <CardContent className="p-6">
              <h3 className="text-base font-semibold text-text-primary flex items-center gap-2 mb-1">
                <Plus className="h-4 w-4 text-primary" />
                নতুন ক্লাস যুক্ত করুন
              </h3>
              <p className="text-xs text-text-secondary mb-4">
                ভিডিও লিংক দিয়ে নতুন ক্লাস তৈরি করুন
              </p>

              {chapters && chapters.length > 0 ? (
                <form action={async (formData: FormData) => { "use server"; await createLessonAction(formData); }} className="space-y-4">
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
                      ক্লাসের শিরোনাম *
                    </label>
                    <input
                      name="title"
                      placeholder="যেমন: ক্লাস ০১: ভেক্টরের সামান্তরিক সূত্র"
                      required
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      শিক্ষকের নাম
                    </label>
                    <input
                      name="instructorName"
                      placeholder="যেমন: তানভীর স্যার"
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      ভিডিও প্রোভাইডার *
                    </label>
                    <select
                      name="videoProvider"
                      defaultValue="youtube"
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      <option value="youtube">YouTube (Unlisted)</option>
                      <option value="bunny">Bunny Stream (HLS)</option>
                      <option value="none">ভিডিও ছাড়া (শুধুমাত্র নোট)</option>
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      YouTube ভিডিও লিংক বা Bunny GUID *
                    </label>
                    <input
                      name="rawVideoUrl"
                      placeholder="https://youtu.be/..."
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                    <p className="text-[11px] text-text-muted">
                      YouTube লিংক দিলে স্বয়ংক্রিয়ভাবে ভিডিও আইডি ও থাম্বনেইল ক্যাশ হবে।
                    </p>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-text-primary">
                      ভিডিওর দৈর্ঘ্য (মিনিটে)
                    </label>
                    <input
                      name="durationSec"
                      type="number"
                      placeholder="যেমন: ৪৫"
                      className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <input
                      type="checkbox"
                      id="lessIsPublished"
                      name="isPublished"
                      value="true"
                      defaultChecked
                      className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                    />
                    <label htmlFor="lessIsPublished" className="text-sm font-medium text-text-primary">
                      তৎক্ষণাৎ প্রকাশ করুন
                    </label>
                  </div>

                  <Button type="submit" className="w-full mt-4">
                    সংরক্ষণ করুন
                  </Button>
                </form>
              ) : (
                <div className="text-sm text-amber-600 bg-amber-50 dark:bg-amber-950/50 p-3 rounded-md">
                  ক্লাস তৈরি করার পূর্বে অন্তত একটি অধ্যায় তৈরি করুন।
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
