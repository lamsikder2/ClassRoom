import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { Bell, Plus, Trash2, Pin } from "lucide-react";
import { createAnnouncementAction, deleteAnnouncementAction } from "@/actions/announcements";
import { EditAnnouncementDialog } from "@/components/announcements/edit-announcement-dialog";

export default async function AnnouncementsPage() {
  const supabase = await createClient();

  const [{ data: announcements }, { data: levels }] = await Promise.all([
    supabase
      .from("announcements")
      .select("*, levels(name)")
      .order("created_at", { ascending: false }),
    supabase.from("levels").select("id, name").order("sort_order"),
  ]);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-text-primary">নোটিশ ও ঘোষণা (Announcements)</h2>
        <p className="text-sm text-text-secondary">
          অ্যাপের হোম স্ক্রিনে ক্যারোসেল আকারে নোটিশ প্রচার করুন
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Notice List */}
        <div className="lg:col-span-2 space-y-4">
          {announcements && announcements.length > 0 ? (
            <div className="space-y-3">
              {announcements.map((item) => (
                <Card key={item.id} className="p-4 flex items-start justify-between gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      {item.is_pinned && (
                        <span className="flex items-center gap-1 text-[11px] font-bold text-primary">
                          <Pin className="h-3 w-3" /> পিন করা
                        </span>
                      )}
                      <h3 className="font-semibold text-text-primary text-base">
                        {item.title}
                      </h3>
                    </div>
                    <p className="text-xs text-text-secondary whitespace-pre-line">
                      {item.body}
                    </p>
                    <p className="text-[11px] text-text-muted mt-2">
                      টার্গেট স্তর: {(item.levels as unknown as { name: string })?.name || "সকল শিক্ষার্থী"}
                    </p>
                  </div>

                  <div className="flex items-center gap-1">
                    <EditAnnouncementDialog announcement={item} levels={levels || []} />
                    <form action={async () => { "use server"; await deleteAnnouncementAction(item.id); }}>
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
              icon={<Bell className="h-8 w-8" />}
              title="কোনো নোটিশ প্রচার করা হয়নি"
              description="ডানপাশের ফর্ম ব্যবহার করে শিক্ষার্থীদের জন্য প্রথম ঘোষণা বা নোটিশ প্রচার করুন।"
            />
          )}
        </div>

        {/* Add Announcement Form */}
        <div>
          <Card>
            <div className="p-6">
              <h3 className="text-base font-semibold text-text-primary flex items-center gap-2 mb-1">
                <Plus className="h-4 w-4 text-primary" />
                নতুন নোটিশ প্রকাশ করুন
              </h3>
              <p className="text-xs text-text-secondary mb-4">
                শিক্ষার্থীদের জন্য জরুরি ঘোষণা দিন
              </p>

              <form action={async (formData: FormData) => { "use server"; await createAnnouncementAction(formData); }} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    নোটিশ শিরোনাম *
                  </label>
                  <input
                    name="title"
                    placeholder="যেমন: বিশেষ লাইভ এক্সাম সংক্রান্ত নোটিশ"
                    required
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    লক্ষ্য স্তর (Target Level)
                  </label>
                  <select
                    name="levelId"
                    className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  >
                    <option value="">সবার জন্য (সকল স্তর)</option>
                    {levels?.map((lvl) => (
                      <option key={lvl.id} value={lvl.id}>
                        {lvl.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-text-primary">
                    বিস্তারিত বিবরণ *
                  </label>
                  <textarea
                    name="body"
                    placeholder="নোটিশের বিস্তারিত টেক্সট..."
                    required
                    rows={4}
                    className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div className="space-y-2 pt-2">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="isPinned"
                      value="true"
                      className="h-4 w-4 text-primary rounded"
                    />
                    <span className="text-sm text-text-primary font-medium">
                      উপরে পিন করে রাখুন
                    </span>
                  </label>
                  <input type="hidden" name="isPublished" value="true" />
                </div>

                <Button type="submit" className="w-full mt-4">
                  নোটিশ প্রকাশ করুন
                </Button>
              </form>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
