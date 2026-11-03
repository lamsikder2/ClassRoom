"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2 } from "lucide-react";
import { updateSubjectAction } from "@/actions/subjects";
import { toast } from "sonner";

interface Level {
  id: string;
  name: string;
}

interface Subject {
  id: string;
  level_id: string;
  name: string;
  name_en?: string | null;
  slug: string;
  color_hex?: string | null;
  sort_order: number;
  is_published: boolean;
}

export function EditSubjectDialog({
  subject,
  levels,
}: {
  subject: any;
  levels: any[];
}) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateSubjectAction(subject.id, formData);
      if (res.success) {
        toast.success("বিষয় সফলভাবে আপডেট করা হয়েছে!");
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
        title="বিষয় সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit Subject</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="বিষয় সম্পাদনা করুন (Edit Subject)"
        description="বিষয়ের নাম, স্তর ও কালার থিম পরিবর্তন করুন"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              শিক্ষাস্তর (Level) *
            </label>
            <select
              name="levelId"
              defaultValue={subject.level_id}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              {levels.map((lvl) => (
                <option key={lvl.id} value={lvl.id}>
                  {lvl.name}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              বিষয়ের নাম (বাংলা) *
            </label>
            <input
              name="name"
              defaultValue={subject.name}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ইংরেজি নাম
            </label>
            <input
              name="nameEn"
              defaultValue={subject.name_en || ""}
              placeholder="e.g. Physics 1st Paper"
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ইউআরএল স্লাগ *
            </label>
            <input
              name="slug"
              defaultValue={subject.slug}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                ব্র্যান্ড কালার
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="color"
                  name="colorHex"
                  defaultValue={subject.color_hex || "#4F46E5"}
                  className="h-10 w-12 rounded border border-border cursor-pointer bg-transparent"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                ক্রম (Sort Order)
              </label>
              <input
                name="sortOrder"
                type="number"
                defaultValue={subject.sort_order}
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id={`edit-sub-published-${subject.id}`}
              name="isPublished"
              value="true"
              defaultChecked={subject.is_published}
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
            />
            <label
              htmlFor={`edit-sub-published-${subject.id}`}
              className="text-sm text-text-secondary cursor-pointer"
            >
              শিক্ষার্থীদের অ্যাপে প্রকাশ করুন
            </label>
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
