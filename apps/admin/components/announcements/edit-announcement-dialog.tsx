"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2 } from "lucide-react";
import { updateAnnouncementAction } from "@/actions/announcements";
import { toast } from "sonner";

interface Level {
  id: string;
  name: string;
}

interface Announcement {
  id: string;
  title: string;
  body: string;
  level_id?: string | null;
  is_pinned: boolean;
  is_published: boolean;
}

export function EditAnnouncementDialog({
  announcement,
  levels,
}: {
  announcement: any;
  levels: any[];
}) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateAnnouncementAction(announcement.id, formData);
      if (res.success) {
        toast.success("ঘোষণা সফলভাবে আপডেট করা হয়েছে!");
        setOpen(false);
      } else {
        toast.error(res.error || "আপডেট করতে ব্যর্থ হয়েছে");
      }
    } catch (err: any) {
      toast.error(err.message || "ত্রুটি ঘটেছে");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Button
        variant="ghost"
        size="icon"
        onClick={() => setOpen(true)}
        className="h-8 w-8 text-text-muted hover:text-primary"
        title="নোটিশ সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit Announcement</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="নোটিশ সম্পাদনা করুন (Edit Announcement)"
        description="নোটিশের শিরোনাম, বার্তা ও প্রদর্শন সেটিংস পরিবর্তন করুন"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              শিরোনাম (Title) *
            </label>
            <input
              name="title"
              defaultValue={announcement.title}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              টার্গেট স্তর (Target Level)
            </label>
            <select
              name="levelId"
              defaultValue={announcement.level_id || ""}
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="">সকল শিক্ষার্থী (All Students)</option>
              {levels.map((lvl) => (
                <option key={lvl.id} value={lvl.id}>
                  {lvl.name}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              বিস্তারিত বার্তা (Body) *
            </label>
            <textarea
              name="body"
              defaultValue={announcement.body}
              required
              rows={4}
              className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-2 pt-1">
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id={`edit-ann-pin-${announcement.id}`}
                name="isPinned"
                value="true"
                defaultChecked={announcement.is_pinned}
                className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
              />
              <label
                htmlFor={`edit-ann-pin-${announcement.id}`}
                className="text-sm text-text-secondary cursor-pointer"
              >
                হোম পেজের শীর্ষে পিন করে রাখুন
              </label>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id={`edit-ann-pub-${announcement.id}`}
                name="isPublished"
                value="true"
                defaultChecked={announcement.is_published}
                className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
              />
              <label
                htmlFor={`edit-ann-pub-${announcement.id}`}
                className="text-sm text-text-secondary cursor-pointer"
              >
                শিক্ষার্থীদের জন্য অবিলম্বে প্রকাশ করুন
              </label>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-border">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setOpen(false)}
            >
              বাতিল
            </Button>
            <Button type="submit" size="sm" disabled={loading}>
              {loading && <Loader2 className="mr-1.5 h-3.5 w-3.5 animate-spin" />}
              সংরক্ষণ করুন
            </Button>
          </div>
        </form>
      </Dialog>
    </>
  );
}
