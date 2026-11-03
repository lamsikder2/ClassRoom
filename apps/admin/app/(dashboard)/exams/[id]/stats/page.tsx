import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Users, CheckCircle2, TrendingUp, Award, Download } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

interface Props {
  params: Promise<{ id: string }>;
}

interface QuestionStat {
  id: string;
  body: string;
  answered: number;
  accuracy: number;
}

interface ExamStatsData {
  attempts?: number;
  unique_students?: number;
  avg_score?: number;
  pass_rate?: number;
  question_stats?: QuestionStat[];
}

export default async function ExamStatsPage({ params }: Props) {
  const { id: examId } = await params;
  const supabase = await createClient();

  const [{ data: exam }, { data: statsData }, { data: attempts }] = await Promise.all([
    supabase.from("exams").select("*, subjects(name)").eq("id", examId).single(),
    supabase.rpc("admin_exam_stats", { p_exam_id: examId }),
    supabase
      .from("exam_attempts")
      .select("*, profiles(full_name, phone, institution)")
      .eq("exam_id", examId)
      .neq("status", "in_progress")
      .order("score", { ascending: false })
      .limit(100),
  ]);

  if (!exam) notFound();

  const stats = (statsData as unknown as ExamStatsData) || {};

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-4">
          <Link href="/exams">
            <Button variant="outline" size="icon" className="h-9 w-9">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div>
            <h2 className="text-xl font-bold text-text-primary">
              {exam.title} — ফলাফল ও অ্যানালিটিক্স
            </h2>
            <p className="text-xs text-text-muted mt-0.5">
              বিষয়: {(exam.subjects as unknown as { name: string })?.name} • সময়: {Math.round(exam.duration_sec / 60)} মিনিট
            </p>
          </div>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold text-text-secondary">
              মোট অংশগ্রহণ
            </CardTitle>
            <Users className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.attempts ?? 0} বার</div>
            <p className="text-[11px] text-text-muted mt-1">
              স্বতন্ত্র শিক্ষার্থী: {stats.unique_students ?? 0} জন
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold text-text-secondary">
              গড় প্রাপ্ত নম্বর
            </CardTitle>
            <Award className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.avg_score ?? 0}</div>
            <p className="text-[11px] text-text-muted mt-1">
              মোট নম্বরের ওপর ভিত্তি করে
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold text-text-secondary">
              পাসের হার
            </CardTitle>
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-emerald-600">
              {stats.pass_rate ?? 0}%
            </div>
            <p className="text-[11px] text-text-muted mt-1">
              পাস ক্রাইটেরিয়া: {exam.pass_percentage}%
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold text-text-secondary">
              মোট প্রশ্ন
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats.question_stats?.length ?? 0}টি
            </div>
            <p className="text-[11px] text-text-muted mt-1">
              নেগেটিভ মার্কিং: -{exam.negative_mark}
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Student Results Table */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">মেধা তালিকা ও ফলাফল (Leaderboard)</CardTitle>
            <CardDescription>শিক্ষার্থীদের প্রাপ্ত নম্বর ও সময়কাল</CardDescription>
          </CardHeader>
          <CardContent>
            {attempts && attempts.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-surface-variant text-text-secondary border-b border-border">
                    <tr>
                      <th className="p-2.5">র‍্যাংক</th>
                      <th className="p-2.5">শিক্ষার্থীর নাম</th>
                      <th className="p-2.5">কলেজ / প্রতিষ্ঠান</th>
                      <th className="p-2.5 text-right">নম্বর</th>
                      <th className="p-2.5 text-right">শতকরা</th>
                      <th className="p-2.5 text-right">ফলাফল</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {attempts.map((att, idx) => (
                      <tr key={att.id} className="hover:bg-surface-variant/40">
                        <td className="p-2.5 font-bold text-text-muted">#{idx + 1}</td>
                        <td className="p-2.5 font-semibold text-text-primary">
                          {(att.profiles as unknown as { full_name: string })?.full_name || "অজ্ঞাত শিক্ষার্থী"}
                        </td>
                        <td className="p-2.5 text-text-secondary">
                          {(att.profiles as unknown as { institution: string })?.institution || "—"}
                        </td>
                        <td className="p-2.5 text-right font-bold text-primary">
                          {att.score}
                        </td>
                        <td className="p-2.5 text-right font-medium">
                          {att.percentage}%
                        </td>
                        <td className="p-2.5 text-right">
                          <Badge variant={att.is_passed ? "success" : "destructive"}>
                            {att.is_passed ? "উত্তীর্ণ" : "অনুত্তীর্ণ"}
                          </Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="py-12 text-center text-sm text-text-muted">
                এখনো কোনো শিক্ষার্থী এই পরীক্ষায় অংশগ্রহণ করেনি।
              </div>
            )}
          </CardContent>
        </Card>

        {/* Question Accuracy Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">প্রশ্নভিত্তিক নির্ভুলতা (Accuracy)</CardTitle>
            <CardDescription>
              শিক্ষার্থীরা কোন প্রশ্নে বেশি ভুল করেছে তা পর্যবেক্ষণ করুন
            </CardDescription>
          </CardHeader>
          <CardContent>
            {stats.question_stats && stats.question_stats.length > 0 ? (
              <div className="space-y-3">
                {stats.question_stats.map((q, idx) => {
                  const acc = q.accuracy ?? 0;
                  const isLow = acc < 40;

                  return (
                    <div key={q.id} className="p-2.5 rounded bg-surface-variant text-xs space-y-1.5">
                      <div className="flex justify-between items-start gap-2">
                        <span className="font-semibold text-text-primary line-clamp-1">
                          #{idx + 1}. {q.body}
                        </span>
                        <span className={`font-bold shrink-0 ${isLow ? "text-destructive" : "text-emerald-600"}`}>
                          {acc}%
                        </span>
                      </div>
                      <div className="h-1.5 w-full bg-border rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${isLow ? "bg-destructive" : "bg-emerald-600"}`}
                          style={{ width: `${acc}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="py-8 text-center text-xs text-text-muted">
                পরীক্ষা সম্পন্ন হলে প্রশ্নভিত্তিক নির্ভুলতা দৃশ্যমান হবে।
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

