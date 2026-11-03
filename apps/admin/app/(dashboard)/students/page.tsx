import { createAdminServiceClient } from "@/lib/supabase/server";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { Users, Ban, CheckCircle, ShieldCheck, UserCheck } from "lucide-react";
import { toggleBlockStudentAction } from "@/actions/students";

export const dynamic = "force-dynamic";

export default async function StudentsPage() {
  const supabase = createAdminServiceClient();

  // Fetch all profiles with their assigned academic level
  const { data: profiles, error } = await supabase
    .from("profiles")
    .select("*, levels(name)")
    .order("created_at", { ascending: false })
    .limit(200);

  // Fetch user roles so we know who is admin vs student
  const { data: roles } = await supabase
    .from("user_roles")
    .select("user_id, role");

  const roleMap = new Map<string, string>();
  if (roles) {
    for (const r of roles) {
      roleMap.set(r.user_id, r.role);
    }
  }

  const students = profiles || [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
        <div>
          <h2 className="text-xl font-bold text-text-primary">শিক্ষার্থী ও ইউজার তালিকা (Users & Students)</h2>
          <p className="text-sm text-text-secondary">
            প্ল্যাটফর্মের নিবন্ধিত সকল শিক্ষার্থী ও ব্যবহারকারীদের তথ্য এবং অ্যাক্সেস নিয়ন্ত্রণ করুন
          </p>
        </div>
        <div className="text-xs font-semibold px-3 py-1.5 rounded-full bg-primary-surface text-primary border border-primary/20">
          মোট ইউজার: {students.length} জন
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          {students.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-left min-w-[650px]">
                <thead className="bg-surface-variant text-text-secondary border-b border-border">
                  <tr>
                    <th className="p-3">শিক্ষার্থীর নাম</th>
                    <th className="p-3">ইউজার রোল</th>
                    <th className="p-3">ফোন নম্বর</th>
                    <th className="p-3">শিক্ষাপ্রতিষ্ঠান</th>
                    <th className="p-3">নির্বাচিত স্তর</th>
                    <th className="p-3">স্ট্যাটাস</th>
                    <th className="p-3 text-right">পদক্ষেপ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {students.map((student) => {
                    const role = roleMap.get(student.id) || "student";
                    const isSuperAdmin = role === "super_admin";
                    const isAdmin = role === "admin" || isSuperAdmin;

                    return (
                      <tr key={student.id} className="hover:bg-surface-variant/40 transition-colors">
                        <td className="p-3">
                          <div className="flex items-center gap-2.5">
                            {student.avatar_url ? (
                              <img
                                src={student.avatar_url}
                                alt={student.full_name || "User"}
                                className="w-7 h-7 rounded-full object-cover shrink-0 border border-border"
                              />
                            ) : (
                              <div className="w-7 h-7 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[11px] shrink-0">
                                {(student.full_name || "S")[0].toUpperCase()}
                              </div>
                            )}
                            <div>
                              <div className="font-semibold text-text-primary">
                                {student.full_name || "অজ্ঞাত শিক্ষার্থী"}
                              </div>
                              <div className="text-[10px] text-text-muted font-mono">
                                ID: {student.id.substring(0, 8)}...
                              </div>
                            </div>
                          </div>
                        </td>

                        <td className="p-3">
                          {isSuperAdmin ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-bold bg-purple-500/10 text-purple-600 border border-purple-500/20">
                              <ShieldCheck className="w-3 h-3" /> সুপার অ্যাডমিন
                            </span>
                          ) : isAdmin ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-bold bg-blue-500/10 text-blue-600 border border-blue-500/20">
                              <ShieldCheck className="w-3 h-3" /> অ্যাডমিন
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-500/10 text-emerald-600">
                              <UserCheck className="w-3 h-3" /> শিক্ষার্থী
                            </span>
                          )}
                        </td>

                        <td className="p-3 text-text-secondary">{student.phone || "—"}</td>
                        <td className="p-3 text-text-secondary">{student.institution || "—"}</td>
                        <td className="p-3">
                          <span className="px-2 py-0.5 rounded bg-surface-variant font-medium">
                            {(student.levels as unknown as { name: string })?.name || "স্তরহীন"}
                          </span>
                        </td>
                        <td className="p-3">
                          <Badge variant={student.is_blocked ? "destructive" : "success"}>
                            {student.is_blocked ? "নিষিদ্ধ (Blocked)" : "সক্রিয়"}
                          </Badge>
                        </td>
                        <td className="p-3 text-right">
                          {!isSuperAdmin && (
                            <form action={async () => { "use server"; await toggleBlockStudentAction(student.id, student.is_blocked); }}>
                              <Button
                                size="sm"
                                variant={student.is_blocked ? "outline" : "destructive"}
                                className="h-7 text-xs"
                              >
                                {student.is_blocked ? (
                                  <>
                                    <CheckCircle className="h-3 w-3 mr-1 text-emerald-600" />
                                    আনব্লক
                                  </>
                                ) : (
                                  <>
                                    <Ban className="h-3 w-3 mr-1" />
                                    ব্লক করুন
                                  </>
                                )}
                              </Button>
                            </form>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyState
              icon={<Users className="h-8 w-8" />}
              title="কোনো শিক্ষার্থী পাওয়া যায়নি"
              description="এখনো কোনো শিক্ষার্থী অ্যাপ্লিকেশনে রেজিস্ট্রেশন করেনি।"
            />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
