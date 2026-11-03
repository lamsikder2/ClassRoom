"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { FileSpreadsheet, Upload, Download, ArrowLeft, CheckCircle2, AlertCircle, Loader2 } from "lucide-react";
import Link from "next/link";
import * as XLSX from "xlsx";
import { toast } from "sonner";
import { bulkImportQuestionsAction, type BulkQuestionRow } from "@/actions/questions";

interface ParsedRow {
  chapterId: string;
  body: string;
  optionA: string;
  optionB: string;
  optionC: string;
  optionD: string;
  correctOption: string;
  explanation?: string;
  difficulty?: string;
  tags?: string;
  isValid: boolean;
  errors: string[];
}

export default function BulkQuestionImportPage() {
  const [rows, setRows] = useState<ParsedRow[]>([]);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleDownloadTemplate = () => {
    const templateData = [
      {
        chapter_id: "অধ্যায়ের UUID",
        question_body: "প্রশ্ন লিখুন (যেমন: ভেক্টর যোজনের সূত্র কোনটি?)",
        option_a: "অপশন ১",
        option_b: "অপশন ২",
        option_c: "অপশন ৩",
        option_d: "অপশন ৪",
        correct_option: "A",
        explanation: "সঠিক উত্তরের ব্যাখ্যা",
        difficulty: "medium",
        tags: "ভেক্টর, এইচএসসি",
      },
    ];

    const ws = XLSX.utils.json_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "QuestionsTemplate");
    XLSX.writeFile(wb, "ClassRoom_Question_Import_Template.xlsx");
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const bstr = evt.target?.result;
        const wb = XLSX.read(bstr, { type: "binary" });
        const wsname = wb.SheetNames[0];
        const ws = wb.Sheets[wsname];
        const rawData = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws);

        const parsed: ParsedRow[] = rawData.map((r) => {
          const chapterId = String(r.chapter_id || "").trim();
          const body = String(r.question_body || "").trim();
          const optionA = String(r.option_a || "").trim();
          const optionB = String(r.option_b || "").trim();
          const optionC = String(r.option_c || "").trim();
          const optionD = String(r.option_d || "").trim();
          const correctOption = String(r.correct_option || "").trim().toUpperCase();

          const errors: string[] = [];
          if (!chapterId) errors.push("অধ্যায় আইডি নেই");
          if (!body) errors.push("প্রশ্ন ফাঁকা");
          if (!optionA || !optionB || !optionC || !optionD) errors.push("৪টি অপশন পূর্ণ নয়");
          if (!["A", "B", "C", "D"].includes(correctOption)) errors.push("সঠিক উত্তর A, B, C বা D হতে হবে");

          return {
            chapterId,
            body,
            optionA,
            optionB,
            optionC,
            optionD,
            correctOption,
            explanation: String(r.explanation || "").trim(),
            difficulty: String(r.difficulty || "medium").trim().toLowerCase(),
            tags: String(r.tags || "").trim(),
            isValid: errors.length === 0,
            errors,
          };
        });

        setRows(parsed);
        toast.info(`মোট ${parsed.length}টি প্রশ্ন লোড করা হয়েছে`);
      } catch {
        toast.error("ফাইলটি পার্স করতে ব্যর্থ হয়েছে। সঠিক Excel ফাইল দিন।");
      }
    };
    reader.readAsBinaryString(file);
  };

  const handleImport = async () => {
    const validRows = rows.filter((r) => r.isValid) as unknown as BulkQuestionRow[];
    if (validRows.length === 0) {
      toast.error("ইমপোর্ট করার মতো কোনো নির্ভুল সারি নেই!");
      return;
    }

    setLoading(true);
    try {
      const res = await bulkImportQuestionsAction(validRows);
      if (res.success) {
        toast.success(`সফলভাবে ${res.count}টি প্রশ্ন ইমপোর্ট করা হয়েছে!`);
        router.push("/questions");
      } else {
        toast.error("ইমপোর্ট ব্যর্থ: " + res.error);
      }
    } catch {
      toast.error("একটি ত্রুটি ঘটেছে। আবার চেষ্টা করুন।");
    } finally {
      setLoading(false);
    }
  };

  const validCount = rows.filter((r) => r.isValid).length;
  const invalidCount = rows.length - validCount;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/questions">
          <Button variant="outline" size="icon" className="h-9 w-9">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h2 className="text-xl font-bold text-text-primary">
            এক্সেল বাল্ক প্রশ্ন ইমপোর্ট
          </h2>
          <p className="text-sm text-text-secondary">
            একসাথে বহুসংখ্যক প্রশ্ন Excel ফাইল থেকে আপলোড করুন
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Upload Card */}
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Upload className="h-4 w-4 text-primary" />
              ফাইল আপলোড করুন
            </CardTitle>
            <CardDescription>
              Excel (.xlsx, .xls) অথবা CSV ফাইল ড্রপ করুন
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Button
              variant="outline"
              onClick={handleDownloadTemplate}
              className="w-full gap-2 text-xs border-dashed"
            >
              <Download className="h-4 w-4 text-emerald-600" />
              স্ট্যান্ডার্ড টেমপ্লেট ডাউনলোড করুন
            </Button>

            <div className="border-2 border-dashed border-border rounded-lg p-6 text-center hover:bg-surface-variant transition-colors cursor-pointer relative">
              <input
                type="file"
                accept=".xlsx, .xls, .csv"
                onChange={handleFileUpload}
                className="absolute inset-0 opacity-0 cursor-pointer"
              />
              <FileSpreadsheet className="h-10 w-10 text-primary mx-auto mb-2" />
              <p className="text-xs font-semibold text-text-primary">
                ফাইল নির্বাচন করুন বা ড্রপ করুন
              </p>
              <p className="text-[11px] text-text-muted mt-1">XLSX, XLS বা CSV</p>
            </div>

            {rows.length > 0 && (
              <div className="p-3 rounded-md bg-surface-variant space-y-1.5 text-xs">
                <div className="flex justify-between">
                  <span className="text-text-secondary">মোট সারি:</span>
                  <span className="font-bold text-text-primary">{rows.length}টি</span>
                </div>
                <div className="flex justify-between text-emerald-600">
                  <span>নির্ভুল সারি:</span>
                  <span className="font-bold">{validCount}টি</span>
                </div>
                {invalidCount > 0 && (
                  <div className="flex justify-between text-destructive">
                    <span>ভুল সারি:</span>
                    <span className="font-bold">{invalidCount}টি</span>
                  </div>
                )}
              </div>
            )}

            <Button
              onClick={handleImport}
              disabled={validCount === 0 || loading}
              className="w-full"
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ইমপোর্ট হচ্ছে...
                </>
              ) : (
                `${validCount}টি প্রশ্ন ইমপোর্ট করুন`
              )}
            </Button>
          </CardContent>
        </Card>

        {/* Preview Table */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">প্রিভিউ ও ভ্যালিডেশন গ্রিড</CardTitle>
            <CardDescription>
              ইমপোর্ট করার পূর্বে সারির তথ্য ও নির্ভুলতা যাচাই করুন
            </CardDescription>
          </CardHeader>
          <CardContent>
            {rows.length > 0 ? (
              <div className="max-h-[500px] overflow-auto border border-border rounded-md">
                <table className="w-full text-xs text-left border-collapse">
                  <thead className="bg-surface-variant text-text-secondary sticky top-0 border-b border-border">
                    <tr>
                      <th className="p-2.5">স্ট্যাটাস</th>
                      <th className="p-2.5">প্রশ্ন</th>
                      <th className="p-2.5">সঠিক</th>
                      <th className="p-2.5">অপশনসমূহ</th>
                      <th className="p-2.5">ত্রুটি</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {rows.map((row, idx) => (
                      <tr
                        key={idx}
                        className={row.isValid ? "bg-surface" : "bg-red-50/60 dark:bg-red-950/30"}
                      >
                        <td className="p-2.5">
                          {row.isValid ? (
                            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                          ) : (
                            <AlertCircle className="h-4 w-4 text-destructive" />
                          )}
                        </td>
                        <td className="p-2.5 font-medium text-text-primary max-w-[200px] truncate">
                          {row.body || "—"}
                        </td>
                        <td className="p-2.5 font-bold text-primary">
                          ({row.correctOption || "—"})
                        </td>
                        <td className="p-2.5 text-text-secondary max-w-[150px] truncate">
                          A: {row.optionA} | B: {row.optionB}
                        </td>
                        <td className="p-2.5 text-destructive text-[11px]">
                          {row.errors.join(", ") || "—"}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="py-16 text-center text-sm text-text-muted">
                বামপাশের বক্স থেকে একটি Excel বা CSV ফাইল আপলোড করুন।
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

