import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Settings as SettingsIcon, ShieldAlert, Smartphone } from "lucide-react";
import { updateSettingAction } from "@/actions/settings";

export default async function SettingsPage() {
  const supabase = await createClient();

  const { data: settings } = await supabase.from("app_settings").select("*");

  const settingsMap = new Map((settings || []).map((s) => [s.key, s.value]));

  const minVersion = (settingsMap.get("min_app_version") as string) || "1.0.0";
  const maintenance = Boolean(settingsMap.get("maintenance_mode"));

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-xl font-bold text-text-primary">সিস্টেম কনফিগারেশন ও সেটিংস</h2>
        <p className="text-sm text-text-secondary">
          অ্যাপ ভার্সন কন্ট্রোল এবং মেইনটেন্যান্স মোড পরিচালনা করুন
        </p>
      </div>

      <div className="space-y-6">
        {/* App Version Control */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Smartphone className="h-4 w-4 text-primary" />
              অ্যাপ ভার্সন কন্ট্রোল (Force Update)
            </CardTitle>
            <CardDescription>
              শিক্ষার্থীদের সর্বনিম্ন অ্যাপ ভার্সন নির্ধারণ করুন
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action={async (formData: FormData) => {
                "use server";
                const ver = formData.get("minVersion") as string;
                await updateSettingAction("min_app_version", ver, true);
              }}
              className="flex items-center gap-3"
            >
              <input
                name="minVersion"
                defaultValue={minVersion}
                placeholder="1.0.0"
                required
                className="flex h-10 w-48 rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary"
              />
              <Button type="submit" size="sm">
                ভার্সন সংরক্ষণ করুন
              </Button>
            </form>
            <p className="text-xs text-text-muted mt-2">
              এর চেয়ে পুরনো ভার্সনের অ্যাপ চালু করলে শিক্ষার্থীকে বাধ্যতামূলক প্লে-স্টোর আপডেটের বার্তা দেখাবে।
            </p>
          </CardContent>
        </Card>

        {/* Maintenance Mode */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <ShieldAlert className="h-4 w-4 text-amber-600" />
              সার্ভার মেইনটেন্যান্স মোড
            </CardTitle>
            <CardDescription>
              জরুরি সংস্কার বা ডেটাবেস আপডেটের সময় অ্যাপের কার্যক্রম সাময়িক স্থগিত রাখুন
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action={async (formData: FormData) => {
                "use server";
                const enabled = formData.get("maintenance") === "true";
                await updateSettingAction("maintenance_mode", enabled, true);
              }}
              className="flex items-center justify-between"
            >
              <div className="space-y-0.5">
                <span className="text-sm font-semibold text-text-primary">
                  মেইনটেন্যান্স স্ট্যাটাস:{" "}
                  <span className={maintenance ? "text-destructive" : "text-emerald-600"}>
                    {maintenance ? "চালু (সক্রিয়)" : "বন্ধ (স্বাভাবিক)"}
                  </span>
                </span>
                <p className="text-xs text-text-muted">
                  চালু করলে সকল শিক্ষার্থী অ্যাপ খুললে সাময়িক বার্তা দেখতে পাবে।
                </p>
              </div>

              <input type="hidden" name="maintenance" value={maintenance ? "false" : "true"} />
              <Button
                type="submit"
                variant={maintenance ? "outline" : "destructive"}
                size="sm"
              >
                {maintenance ? "মেইনটেন্যান্স বন্ধ করুন" : "মেইনটেন্যান্স চালু করুন"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

