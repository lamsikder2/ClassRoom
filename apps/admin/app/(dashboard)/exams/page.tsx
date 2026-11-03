import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { GraduationCap, Plus, Trash2, BarChart3, Clock, Radio } from "lucide-react";
import Link from "next/link";
import { deleteExamAction } from "@/actions/exams";

export default async function ExamsPage() {
  const supabase = await createClient();

  const { data: exams } = await supabase
    .from("exams")
    .select("*, subjects(name), chapters(title), exam_attempts(count)")
    .order("created_at", { ascending: false });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-text-primary">পরীক্ষা ব্যবস্থাপনা (Exams)</h2>
          <p className="text-sm text-text-secondary">
            লাইভ ও প্র্যাকটিস পরীক্ষা তৈরি এবং শিক্ষার্থীদের ফলাফল পর্যালোচনা করুন
          </p>
        </div>

        <Link href="/exams/new">
          <Button size="sm" className="gap-1.5">
            <Plus className="h-4 w-4" />
            নতুন পরীক্ষা তৈরি করুন
          </Button>
        </Link>
      </div>

      {/* Exam List */}
      <div className="space-y-4">
        {exams && exams.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {exams.map((exam) => {
              const attemptCount = (exam.exam_attempts as unknown as Array<{ count: number }>)?.[0]?.count ?? 0;

              return (
                <Card key={exam.id} className="p-5 flex flex-col justify-between space-y-4">
                  <div>
                    <div className="flex items-center justify-between gap-2 mb-2">
                      <Badge variant={exam.mode === "live" ? "destructive" : "secondary"} className="gap-1">
                        {exam.mode === "live" ? <Radio className="h-3 w-3 animate-pulse" /> : null}
                        {exam.mode === "live" ? "লাইভ পরীক্ষা" : "প্র্যাকটিস"}
                      </Badge>

                      <span className="text-[11px] font-medium text-text-muted">
                        পরিধি: {exam.scope}
                      </span>
                    </div>

                    <h3 className="font-bold text-text-primary text-base line-clamp-2">
                      {exam.title}
                    </h3>

                    <p className="text-xs text-text-secondary mt-1">
                      বিষয়: {(exam.subjects as unknown as { name: string })?.name}
                      {exam.chapters && ` → ${(exam.chapters as unknown as { title: string })?.title}`}
                    </p>

                    <div className="flex items-center gap-3 mt-4 text-xs text-text-muted">
                      <span className="flex items-center gap-1">
                        <Clock className="h-3.5 w-3.5 text-primary" />
                        {Math.round(exam.duration_sec / 60)} মিনিট
                      </span>
                      <span>•</span>
                      <span>মার্ক: {exam.mark_per_question}</span>
                      <span>•</span>
                      <span className="text-destructive font-medium">নেগেটিভ: -{exam.negative_mark}</span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-4 border-t border-border">
                    <span className="text-xs font-semibold text-text-secondary">
                      অংশগ্রহণ: {attemptCount} জন
                    </span>

                    <div className="flex items-center gap-1">
                      <Link href={`/exams/${exam.id}/stats`}>
                        <Button size="sm" variant="outline" className="gap-1.5 text-xs h-8">
                          <BarChart3 className="h-3.5 w-3.5 text-primary" />
                          ফলাফল ও অ্যানালিটিক্স
                        </Button>
                      </Link>

                      <form action={async () => { "use server"; await deleteExamAction(exam.id); }}>
                        <Button
                          variant="ghost"
                          size="icon"
                          disabled={attemptCount > 0}
                          title={attemptCount > 0 ? "অংশগ্রহণকারী থাকায় মোছা যাবে না" : "মুছে ফেলুন"}
                          className="h-8 w-8 text-text-muted hover:text-destructive"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </form>
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>
        ) : (
          <EmptyState
            icon={<GraduationCap className="h-8 w-8" />}
            title="কোনো পরীক্ষা তৈরি করা হয়নি"
            description="এখনো কোনো পরীক্ষা তৈরি করা হয়নি। উপরের বাটন দিয়ে প্রথম পরীক্ষাটি সেটআপ করুন।"
            action={
              <Link href="/exams/new">
                <Button size="sm">প্রথম পরীক্ষা তৈরি করুন</Button>
              </Link>
            }
          />
        )}
      </div>
    </div>
  );
}
