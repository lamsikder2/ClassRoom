import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { FileText, Plus, Trash2, ArrowLeft, ExternalLink, Download, FileCode } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createMaterialAction, deleteMaterialAction } from "@/actions/materials";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function LessonMaterialsPage({ params }: Props) {
  const { id: lessonId } = await params;
  const supabase = await createClient();

  const [{ data: lesson }, { data: materials }] = await Promise.all([
    supabase
      .from("lessons")
      .select("id, title, chapter_id, chapters(title, subjects(name))")
      .eq("id", lessonId)
      .single(),
    supabase
      .from("materials")
      .select("*")
      .eq("lesson_id", lessonId)
      .order("sort_order"),
  ]);

  if (!lesson) notFound();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href={`/lessons?chapterId=${lesson.chapter_id}`}>
          <Button variant="outline" size="icon" className="h-9 w-9">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <div className="text-xs text-text-muted">
            {(lesson.chapters as unknown as { subjects: { name: string } })?.subjects?.name} → {(lesson.chapters as unknown as { title: string })?.title}
          </div>
          <h2 className="text-xl font-bold text-text-primary">
            {lesson.title} — শিট ও ক্লাস নোট
          </h2>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Materials List */}
        <div className="lg:col-span-2 space-y-4">
          {materials && materials.length > 0 ? (
            <div className="space-y-4">
              {materials.map((mat) => (
                <Card key={mat.id} className="p-4">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-3">
                      <div className="h-10 w-10 rounded-md bg-primary-surface text-primary flex items-center justify-center shrink-0">
                        {mat.type === "lecture_sheet" ? (
                          <FileText className="h-5 w-5" />
                        ) : (
                          <FileCode className="h-5 w-5" />
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-text-primary text-base">
                            {mat.title}
                          </span>
                          <span className="text-[11px] px-2 py-0.5 rounded bg-surface-variant font-medium text-text-secondary capitalize">
                            {mat.type === "lecture_sheet" ? "লেকচার শিট" : "ক্লাস নোট"}
                          </span>
                        </div>

                        {mat.source === "drive" && mat.drive_file_id && (
                          <div className="mt-2 text-xs text-text-secondary flex items-center gap-3">
                            <a
                              href={`https://drive.google.com/file/d/${mat.drive_file_id}/view`}
                              target="_blank"
                              rel="noreferrer"
                              className="text-primary hover:underline flex items-center gap-1 font-medium"
                            >
                              ড্রাইভে দেখুন
                              <ExternalLink className="h-3 w-3" />
                            </a>
                            <span className="text-text-muted">•</span>
                            <span className="flex items-center gap-1 text-text-muted">
                              <Download className="h-3 w-3" />
                              {mat.allow_download ? "ডাউনলোড অনুমোদিত" : "ডাউনলোড বন্ধ"}
                            </span>
                          </div>
                        )}
                      </div>
                    </div>

                    <form action={async () => { "use server"; await deleteMaterialAction(lessonId, mat.id); }}>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-text-muted hover:text-destructive">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </form>
                  </div>

                  {/* Drive Preview iframe */}
                  {mat.source === "drive" && mat.drive_file_id && (
                    <div className="mt-4 rounded-md border border-border overflow-hidden bg-surface-variant">
                      <div className="px-3 py-1.5 bg-surface border-b border-border text-[11px] font-medium text-text-muted">
                        লাইভ প্রিভিউ (Google Drive Iframe)
                      </div>
                      <iframe
                        src={`https://drive.google.com/file/d/${mat.drive_file_id}/preview`}
                        className="w-full h-48 border-0"
                        title={mat.title}
                      />
                    </div>
                  )}

                  {/* Rich Text Preview */}
                  {mat.source === "rich_text" && mat.content_md && (
                    <div className="mt-3 p-3 rounded-md bg-surface-variant text-xs text-text-secondary font-mono line-clamp-3">
                      {mat.content_md}
                    </div>
                  )}
                </Card>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={<FileText className="h-8 w-8" />}
              title="কোনো শিট বা নোট যোগ করা হয়নি"
              description="এই ক্লাসের জন্য এখনো কোনো লেকচার শিট বা ক্লাস নোট সংযুক্ত করা হয়নি। ডানপাশের ফর্ম ব্যবহার করে ড্রাইভ লিংক দিন।"
            />
          )}
        </div>

        {/* Add Material Form */}
        <div>
          <Card>
            <div className="p-6">
              <h3 className="text-base font-semibold text-text-primary flex items-center gap-2 mb-1">
                <Plus className="h-4 w-4 text-primary" />
                শিট বা নোট সংযুক্ত করুন
              </h3>
              <p className="text-xs text-text-secondary mb-4">
                Google Drive লিংক দিয়ে লেকচার শিট দিন
              </p>

              <form action={async (formData: FormData) => { "use server"; await createMaterialAction(formData); }} className="space-y-4">
                <input type="hidden" name="lessonId" value={lessonId} />

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    ম্যাটেরিয়াল টাইপ *
                  </label>
                  <select
                    name="type"
                    defaultValue="lecture_sheet"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  >
                    <option value="lecture_sheet">লেকচার শিট (PDF)</option>
                    <option value="class_note">ক্লাস নোট (Rich Text / Markdown)</option>
                    <option value="other">অন্যান্য সহায়ক ফাইল</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    শিরোনাম *
                  </label>
                  <input
                    name="title"
                    placeholder="যেমন: সামান্তরিক সূত্রের লেকচার শিট"
                    required
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    সোর্স নির্বাচন *
                  </label>
                  <select
                    name="source"
                    defaultValue="drive"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  >
                    <option value="drive">Google Drive Link</option>
                    <option value="rich_text">Markdown / KaTeX নোট</option>
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    Google Drive শেয়ার লিংক
                  </label>
                  <input
                    name="rawDriveUrl"
                    placeholder="https://drive.google.com/file/d/.../view"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                  <p className="text-[11px] text-amber-600 dark:text-amber-400">
                    ⚠️ ড্রাইভে ফাইলটি &apos;Anyone with the link - Viewer&apos; মুডে শেয়ার থাকতে হবে।
                  </p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    ক্লাস নোট (যদি Markdown/LaTeX হয়)
                  </label>
                  <textarea
                    name="contentMd"
                    placeholder="# মূল সূত্রাবলী..."
                    rows={4}
                    className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary font-mono"
                  />
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <input
                    type="checkbox"
                    id="allowDownload"
                    name="allowDownload"
                    value="true"
                    defaultChecked
                    className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                  />
                  <label htmlFor="allowDownload" className="text-sm font-medium text-text-primary">
                    শিক্ষার্থীদের ডাউনলোডের অনুমতি দিন
                  </label>
                </div>

                <Button type="submit" className="w-full mt-4">
                  সংরক্ষণ করুন
                </Button>
              </form>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
