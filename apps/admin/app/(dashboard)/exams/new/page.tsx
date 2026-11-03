import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { ExamWizardForm } from "./wizard-form";

export default async function NewExamPage() {
  const supabase = await createClient();

  const [{ data: subjects }, { data: chapters }, { data: questions }] = await Promise.all([
    supabase.from("subjects").select("id, name").order("sort_order"),
    supabase.from("chapters").select("id, subject_id, title").order("sort_order"),
    supabase.from("questions").select("id, chapter_id, body, difficulty").order("created_at", { ascending: false }).limit(200),
  ]);

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/exams">
          <Button variant="outline" size="icon" className="h-9 w-9">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h2 className="text-xl font-bold text-text-primary">
            নতুন পরীক্ষা তৈরি উইজার্ড (Exam Wizard)
          </h2>
          <p className="text-sm text-text-secondary">
            ধাপে ধাপে পরীক্ষার সেটিংস নির্ধারণ এবং কোশ্চেন ব্যাংক থেকে প্রশ্ন বাছাই করুন
          </p>
        </div>
      </div>

      <ExamWizardForm
        subjects={subjects || []}
        chapters={chapters || []}
        questions={questions || []}
      />
    </div>
  );
}

