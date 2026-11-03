import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Users, BookOpen, GraduationCap, FileQuestion, ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";

interface DashboardStats {
  total_students?: number;
  new_students_7d?: number;
  active_students_7d?: number;
  total_lessons?: number;
  published_lessons?: number;
  total_exams?: number;
  total_questions?: number;
  top_lessons?: Array<{ id: string; title: string; viewers: number }>;
}

export default async function DashboardPage() {
  const supabase = await createClient();

  // RPC কল
  const { data: statsData } = await supabase.rpc("admin_dashboard_stats");
  const stats = (statsData as unknown as DashboardStats) || {};

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-surface p-6 rounded-lg border border-border">
        <div>
          <h2 className="text-xl font-bold text-text-primary">
            স্বাগতম, অ্যাডমিন ড্যাশবোর্ডে! 👋
          </h2>
          <p className="text-sm text-text-secondary mt-1">
            এখানে আপনার প্ল্যাটফর্মের শিক্ষার্থী, ক্লাস ও পরীক্ষার সার্বিক অবস্থা প্রদর্শিত হচ্ছে।
          </p>
        </div>
        <div className="flex gap-2">
          <Link href="/subjects">
            <Button size="sm" variant="outline">
              বিষয়সমূহ দেখুন
            </Button>
          </Link>
          <Link href="/exams/new">
            <Button size="sm" className="gap-1.5">
              নতুন পরীক্ষা তৈরি
              <ArrowUpRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              মোট শিক্ষার্থী
            </CardTitle>
            <Users className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats.total_students ?? 0}
            </div>
            <p className="text-xs text-text-muted mt-1">
              গত ৭ দিনে নতুন: {stats.new_students_7d ?? 0} জন
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              মোট ক্লাস / লেসন
            </CardTitle>
            <BookOpen className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats.total_lessons ?? 0}
            </div>
            <p className="text-xs text-text-muted mt-1">
              প্রকাশিত: {stats.published_lessons ?? 0}টি
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              মোট পরীক্ষাসমূহ
            </CardTitle>
            <GraduationCap className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats.total_exams ?? 0}
            </div>
            <p className="text-xs text-text-muted mt-1">
              সক্রিয় লাইভ ও প্র্যাকটিস পরীক্ষা
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              কোশ্চেন ব্যাংক পুল
            </CardTitle>
            <FileQuestion className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats.total_questions ?? 0}
            </div>
            <p className="text-xs text-text-muted mt-1">
              অধ্যায়ভিত্তিক প্রশ্ন সংখ্যা
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Content Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Lessons */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">জনপ্রিয় ক্লাসসমূহ</CardTitle>
            <CardDescription>
              শিক্ষার্থীদের সর্বাধিক পঠিত ও দেখা ক্লাস
            </CardDescription>
          </CardHeader>
          <CardContent>
            {stats.top_lessons && stats.top_lessons.length > 0 ? (
              <div className="space-y-3">
                {stats.top_lessons.map((item, index) => (
                  <div
                    key={item.id}
                    className="flex items-center justify-between p-3 rounded-md bg-surface-variant text-sm"
                  >
                    <div className="flex items-center gap-3">
                      <span className="font-bold text-text-muted">
                        {String(index + 1).padStart(2, "0")}
                      </span>
                      <span className="font-medium text-text-primary truncate max-w-[240px]">
                        {item.title}
                      </span>
                    </div>
                    <span className="text-xs font-semibold text-primary">
                      {item.viewers} জন দেখেছেন
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-8 text-center text-sm text-text-muted">
                এখনো কোনো ক্লাসের ওয়াচ হিস্টোরি তৈরি হয়নি।
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quick Actions Guide */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">দ্রুত শুরু করার নির্দেশিকা</CardTitle>
            <CardDescription>
              ধাপে ধাপে কনটেন্ট সাজিয়ে নিন
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 text-sm text-text-secondary">
            <div className="flex items-start gap-3">
              <div className="h-6 w-6 rounded-full bg-primary-surface text-primary flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                ১
              </div>
              <div>
                <strong className="text-text-primary">স্তর (Level) তৈরি করুন:</strong> প্রথমে &apos;স্তর&apos; মেনু থেকে HSC বা SSC এর মতো শ্রেণি তৈরি করুন।
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-6 w-6 rounded-full bg-primary-surface text-primary flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                ২
              </div>
              <div>
                <strong className="text-text-primary">বিষয় ও অধ্যায় যুক্ত করুন:</strong> পদার্থবিজ্ঞান, রসায়ন ইত্যাদি বিষয় এবং তাদের অধীনে অধ্যায় তৈরি করুন।
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-6 w-6 rounded-full bg-primary-surface text-primary flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                ৩
              </div>
              <div>
                <strong className="text-text-primary">ক্লাস ও ড্রাইভ শিট আপলোড:</strong> YouTube লিংক পেস্ট করে ক্লাস এবং Google Drive লিংক দিয়ে লেকচার শিট সংযুক্ত করুন।
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

