"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2 } from "lucide-react";
import { updateLevelAction } from "@/actions/levels";
import { toast } from "sonner";

interface Level {
  id: string;
  name: string;
  name_en?: string | null;
  slug: string;
  description?: string | null;
  sort_order: number;
  is_published: boolean;
}

export function EditLevelDialog({ level }: { level: any }) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateLevelAction(level.id, formData);
      if (res.success) {
        toast.success("স্তর সফলভাবে আপডেট করা হয়েছে!");
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
        title="সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="স্তর সম্পাদনা করুন (Edit Level)"
        description="স্তরের তথ্য ও প্রদর্শনী ক্রম পরিবর্তন করুন"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              স্তরের নাম (বাংলা) *
            </label>
            <input
              name="name"
              defaultValue={level.name}
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
              defaultValue={level.name_en || ""}
              placeholder="e.g. HSC"
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ইউআরএল স্লাগ *
            </label>
            <input
              name="slug"
              defaultValue={level.slug}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ক্রম (Sort Order)
            </label>
            <input
              name="sortOrder"
              type="number"
              defaultValue={level.sort_order}
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id={`edit-published-${level.id}`}
              name="isPublished"
              value="true"
              defaultChecked={level.is_published}
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
            />
            <label
              htmlFor={`edit-published-${level.id}`}
              className="text-sm text-text-secondary cursor-pointer"
            >
              শিক্ষার্থীদের জন্য অবিলম্বে প্রকাশ করুন
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
