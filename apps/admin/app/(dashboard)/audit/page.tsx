import { createClient } from "@/lib/supabase/server";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { ShieldCheck } from "lucide-react";

export default async function AuditLogsPage() {
  const supabase = await createClient();

  const { data: logs } = await supabase
    .from("audit_logs")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-text-primary">অডিট লগস (Audit Logs)</h2>
        <p className="text-sm text-text-secondary">
          অ্যাডমিনদের সমস্ত ডেটা পরিবর্তনের অপরিবর্তনীয় হিস্টোরি ও সিকিউরিটি ট্রেইল
        </p>
      </div>

      <Card>
        <CardContent className="p-0">
          {logs && logs.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-left">
                <thead className="bg-surface-variant text-text-secondary border-b border-border">
                  <tr>
                    <th className="p-3">অ্যাকশন</th>
                    <th className="p-3">টেবিল</th>
                    <th className="p-3">রেকর্ড আইডি</th>
                    <th className="p-3">পরিবর্তন (JSON Diff)</th>
                    <th className="p-3 text-right">সময়</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {logs.map((log) => (
                    <tr key={log.id} className="hover:bg-surface-variant/40">
                      <td className="p-3">
                        <Badge
                          variant={
                            log.action === "INSERT"
                              ? "success"
                              : log.action === "DELETE"
                              ? "destructive"
                              : "warning"
                          }
                        >
                          {log.action}
                        </Badge>
                      </td>
                      <td className="p-3 font-semibold text-text-primary">
                        {log.table_name}
                      </td>
                      <td className="p-3 text-text-muted font-mono text-[11px]">
                        {log.record_id ? log.record_id.slice(0, 8) + "..." : "—"}
                      </td>
                      <td className="p-3 max-w-xs truncate text-[11px] font-mono text-text-secondary">
                        {log.new_data ? JSON.stringify(log.new_data) : JSON.stringify(log.old_data)}
                      </td>
                      <td className="p-3 text-right text-text-muted">
                        {new Date(log.created_at).toLocaleString("bn-BD")}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyState
              icon={<ShieldCheck className="h-8 w-8" />}
              title="কোনো অডিট লগ রেকর্ড নেই"
              description="এখনো কোনো কনটেন্ট তৈরি বা পরিবর্তন করা হয়নি।"
            />
          )}
        </CardContent>
      </Card>
    </div>
  );
}

