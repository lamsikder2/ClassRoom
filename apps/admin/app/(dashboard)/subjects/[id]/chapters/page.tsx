import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { BookOpen, Plus, Trash2, ArrowLeft, ArrowRight, Video } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createChapterAction, deleteChapterAction } from "@/actions/chapters";
import { EditChapterDialog } from "@/components/chapters/edit-chapter-dialog";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function SubjectChaptersPage({ params }: Props) {
  const { id: subjectId } = await params;
  const supabase = await createClient();

  const [{ data: subject }, { data: chapters }] = await Promise.all([
    supabase.from("subjects").select("id, name, color_hex").eq("id", subjectId).single(),
    supabase
      .from("chapters")
      .select("*, lessons(count)")
      .eq("subject_id", subjectId)
      .order("sort_order", { ascending: true }),
  ]);

  if (!subject) notFound();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/subjects">
          <Button variant="outline" size="icon" className="h-9 w-9">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h2 className="text-xl font-bold text-text-primary">
            {subject.name} — অধ্যায়সমূহ
          </h2>
          <p className="text-sm text-text-secondary">
            এই বিষয়ের অধীনে অধ্যায় এবং তাদের ক্লাসগুলো সাজিয়ে নিন
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chapter List */}
        <div className="lg:col-span-2 space-y-4">
          {chapters && chapters.length > 0 ? (
            <div className="space-y-3">
              {chapters.map((chapter) => (
                <Card key={chapter.id} className="p-4 flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-md bg-primary-surface text-primary flex items-center justify-center font-bold text-sm">
                      {chapter.chapter_no ? `অধ্যায় ${chapter.chapter_no}` : "—"}
                    </div>
                    <div>
                      <h3 className="font-semibold text-text-primary text-base">
                        {chapter.title}
                      </h3>
                      <p className="text-xs text-text-muted mt-0.5">
                        মোট ক্লাস: {(chapter.lessons as unknown as Array<{ count: number }>)?.[0]?.count ?? 0}টি
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Link href={`/lessons?chapterId=${chapter.id}`}>
                      <Button size="sm" variant="outline" className="gap-1.5 text-xs">
                        <Video className="h-3.5 w-3.5 text-primary" />
                        ক্লাস পরিচালনা
                        <ArrowRight className="h-3.5 w-3.5" />
                      </Button>
                    </Link>

                    <div className="flex items-center gap-1">
                      <EditChapterDialog chapter={chapter} />
                      <form action={async () => { "use server"; await deleteChapterAction(subjectId, chapter.id); }}>
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
              title="কোনো অধ্যায় যোগ করা হয়নি"
              description="এই বিষয়ের অধীনে এখনো কোনো অধ্যায় তৈরি করা হয়নি। ডানপাশের ফর্ম দিয়ে প্রথম অধ্যায়টি যুক্ত করুন।"
            />
          )}
        </div>

        {/* Add Chapter Form */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Plus className="h-4 w-4 text-primary" />
                নতুন অধ্যায় যুক্ত করুন
              </CardTitle>
              <CardDescription>
                {subject.name} এর জন্য একটি অধ্যায় তৈরি করুন
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form action={async (formData: FormData) => { "use server"; await createChapterAction(formData); }} className="space-y-4">
                <input type="hidden" name="subjectId" value={subjectId} />

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    অধ্যায় নম্বর (যেমন: 1, 2)
                  </label>
                  <input
                    name="chapterNo"
                    type="number"
                    placeholder="1"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    অধ্যায়ের শিরোনাম *
                  </label>
                  <input
                    name="title"
                    placeholder="যেমন: ভেক্টর"
                    required
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    সংক্ষিপ্ত বিবরণ
                  </label>
                  <textarea
                    name="description"
                    placeholder="অধ্যায়ের মূল বিষয়বস্তু..."
                    rows={3}
                    className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    ক্রমিক সংখ্যা (Sort Order)
                  </label>
                  <input
                    name="sortOrder"
                    type="number"
                    defaultValue={0}
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <input
                    type="checkbox"
                    id="chapIsPublished"
                    name="isPublished"
                    value="true"
                    defaultChecked
                    className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                  />
                  <label htmlFor="chapIsPublished" className="text-sm font-medium text-text-primary">
                    তৎক্ষণাৎ প্রকাশ করুন
                  </label>
                </div>

                <Button type="submit" className="w-full mt-4">
                  সংরক্ষণ করুন
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
