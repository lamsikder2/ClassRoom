import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { Layers, Plus, Trash2, CheckCircle, XCircle } from "lucide-react";
import { createLevelAction, deleteLevelAction } from "@/actions/levels";
import { EditLevelDialog } from "@/components/levels/edit-level-dialog";

export default async function LevelsPage() {
  const supabase = await createClient();

  const { data: levels } = await supabase
    .from("levels")
    .select("*")
    .order("sort_order", { ascending: true });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-xl font-bold text-text-primary">স্তর ব্যবস্থাপনা (Levels)</h2>
          <p className="text-sm text-text-secondary">
            শিক্ষার্থীদের শ্রেণি বা স্তর পরিচালনা করুন (যেমন: এইচএসসি, এসএসসি)
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Level List */}
        <div className="lg:col-span-2 space-y-4">
          {levels && levels.length > 0 ? (
            <div className="grid gap-3">
              {levels.map((level) => (
                <Card key={level.id} className="p-4 flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-md bg-primary-surface text-primary flex items-center justify-center font-bold">
                      <Layers className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-text-primary">{level.name}</span>
                        {level.name_en && (
                          <span className="text-xs text-text-muted">({level.name_en})</span>
                        )}
                        {level.is_published ? (
                          <span className="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-medium">
                            <CheckCircle className="h-3 w-3" /> প্রকাশিত
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] text-amber-600 font-medium">
                            <XCircle className="h-3 w-3" /> অপ্রকাশিত
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-text-muted mt-0.5">
                        স্লাগ: <code className="bg-surface-variant px-1 rounded">{level.slug}</code> • ক্রম: {level.sort_order}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-1">
                    <EditLevelDialog level={level} />
                    <form action={async () => { "use server"; await deleteLevelAction(level.id); }}>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-text-muted hover:text-destructive">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </form>
                  </div>
                </Card>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={<Layers className="h-8 w-8" />}
              title="কোনো স্তর পাওয়া যায়নি"
              description="এখনো কোনো স্তর যোগ করা হয়নি। ডানপাশের ফর্ম ব্যবহার করে প্রথম স্তর তৈরি করুন।"
            />
          )}
        </div>

        {/* Add Level Form */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Plus className="h-4 w-4 text-primary" />
                নতুন স্তর যুক্ত করুন
              </CardTitle>
              <CardDescription>
                শিক্ষার্থীর শ্রেণি নির্ধারণের জন্য স্তর তৈরি করুন
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form action={async (formData: FormData) => { "use server"; await createLevelAction(formData); }} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    স্তরের নাম (বাংলা) *
                  </label>
                  <input
                    name="name"
                    placeholder="যেমন: এইচএসসি"
                    required
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    ইংরেজি নাম
                  </label>
                  <input
                    name="nameEn"
                    placeholder="যেমন: HSC"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    স্লাগ (Slug) *
                  </label>
                  <input
                    name="slug"
                    placeholder="hsc"
                    required
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
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
                    id="isPublished"
                    name="isPublished"
                    value="true"
                    defaultChecked
                    className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                  />
                  <label htmlFor="isPublished" className="text-sm font-medium text-text-primary">
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
