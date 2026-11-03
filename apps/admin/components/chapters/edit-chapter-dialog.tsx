"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2 } from "lucide-react";
import { updateChapterAction } from "@/actions/chapters";
import { toast } from "sonner";

interface Chapter {
  id: string;
  subject_id: string;
  chapter_no?: number | null;
  title: string;
  description?: string | null;
  sort_order: number;
  is_published: boolean;
}

export function EditChapterDialog({ chapter }: { chapter: any }) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateChapterAction(
        chapter.subject_id,
        chapter.id,
        formData
      );
      if (res.success) {
        toast.success("অধ্যায় সফলভাবে আপডেট করা হয়েছে!");
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
        title="অধ্যায় সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit Chapter</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="অধ্যায় সম্পাদনা করুন (Edit Chapter)"
        description="অধ্যায়ের নম্বর, শিরোনাম ও প্রকাশনা স্ট্যাটাস পরিবর্তন করুন"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              অধ্যায় নম্বর (ঐচ্ছিক)
            </label>
            <input
              name="chapterNo"
              type="number"
              defaultValue={chapter.chapter_no ?? ""}
              placeholder="যেমন: ১"
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              অধ্যায়ের নাম / শিরোনাম *
            </label>
            <input
              name="title"
              defaultValue={chapter.title}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              বিবরণ (Description)
            </label>
            <textarea
              name="description"
              defaultValue={chapter.description || ""}
              rows={3}
              className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ক্রম (Sort Order)
            </label>
            <input
              name="sortOrder"
              type="number"
              defaultValue={chapter.sort_order}
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id={`edit-chap-published-${chapter.id}`}
              name="isPublished"
              value="true"
              defaultChecked={chapter.is_published}
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
            />
            <label
              htmlFor={`edit-chap-published-${chapter.id}`}
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
