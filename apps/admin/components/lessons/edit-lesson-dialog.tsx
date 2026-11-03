"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/ui/dialog";
import { Pencil, Loader2 } from "lucide-react";
import { updateLessonAction } from "@/actions/lessons";
import { toast } from "sonner";

interface Chapter {
  id: string;
  title: string;
  subjects?: { name: string } | null;
}

interface Lesson {
  id: string;
  chapter_id: string;
  title: string;
  description?: string | null;
  video_provider: "youtube" | "bunny" | "none";
  video_ref?: string | null;
  thumbnail_url?: string | null;
  video_duration_sec?: number | null;
  instructor_name?: string | null;
  sort_order: number;
  is_published: boolean;
}

export function EditLessonDialog({
  lesson,
  chapters,
}: {
  lesson: any;
  chapters: any[];
}) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const durationMin = lesson.video_duration_sec
    ? Math.round(lesson.video_duration_sec / 60)
    : "";

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.currentTarget);
    try {
      const res = await updateLessonAction(lesson.id, formData);
      if (res.success) {
        toast.success("ক্লাস সফলভাবে আপডেট করা হয়েছে!");
        setOpen(false);
      } else {
        toast.error(res.error || "আপডেট ব্যর্থ হয়েছে");
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
        title="ক্লাস সম্পাদনা করুন"
      >
        <Pencil className="h-4 w-4" />
        <span className="sr-only">Edit Lesson</span>
      </Button>

      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="ক্লাস সম্পাদনা করুন (Edit Lesson)"
        description="ক্লাসের ভিডিও লিংক, বিবরণ ও সময় পরিবর্তন করুন"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              অধ্যায় নির্বাচন করুন *
            </label>
            <select
              name="chapterId"
              defaultValue={lesson.chapter_id}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              {chapters.map((ch) => (
                <option key={ch.id} value={ch.id}>
                  {ch.subjects ? `${ch.subjects.name} → ` : ""}
                  {ch.title}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ক্লাসের শিরোনাম *
            </label>
            <input
              name="title"
              defaultValue={lesson.title}
              required
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ভিডিও সোর্স (Provider) *
            </label>
            <select
              name="videoProvider"
              defaultValue={lesson.video_provider}
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="youtube">YouTube (Unlisted / Public)</option>
              <option value="none">ভিডিও ছাড়া (শুধুমাত্র লেকচার শিট)</option>
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              ভিডিও লিংক বা আইডি *
            </label>
            <input
              name="rawVideoUrl"
              defaultValue={
                lesson.video_ref
                  ? `https://www.youtube.com/watch?v=${lesson.video_ref}`
                  : ""
              }
              placeholder="e.g. https://www.youtube.com/watch?v=..."
              className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                সময়কাল (মিনিটে)
              </label>
              <input
                name="durationSec"
                type="number"
                defaultValue={durationMin}
                placeholder="e.g. 45"
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-text-primary">
                ইন্সট্রাক্টর / শিক্ষকের নাম
              </label>
              <input
                name="instructorName"
                defaultValue={lesson.instructor_name || ""}
                placeholder="e.g. ড. রফিকুল ইসলাম"
                className="flex h-10 w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-text-primary">
              বিবরণ (Description)
            </label>
            <textarea
              name="description"
              defaultValue={lesson.description || ""}
              rows={3}
              className="flex w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id={`edit-les-published-${lesson.id}`}
              name="isPublished"
              value="true"
              defaultChecked={lesson.is_published}
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
            />
            <label
              htmlFor={`edit-les-published-${lesson.id}`}
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
