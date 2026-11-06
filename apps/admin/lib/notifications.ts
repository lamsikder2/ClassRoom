import { createAdminServiceClient } from "./supabase/server";

interface NotifyOptions {
  title: string;
  body: string;
  levelId?: string | null;
  deepLink?: string | null;
  lessonId?: string | null;
  materialId?: string | null;
  createAnnouncement?: boolean;
}

export async function broadcastNotification({
  title,
  body,
  levelId = null,
  deepLink = null,
  lessonId = null,
  materialId = null,
  createAnnouncement = true,
}: NotifyOptions) {
  try {
    const adminSupabase = createAdminServiceClient();

    // 1. Insert announcement if requested
    if (createAnnouncement) {
      await adminSupabase.from("announcements").insert({
        title,
        body,
        level_id: levelId,
        deep_link: deepLink,
        is_pinned: false,
        is_published: true,
        published_at: new Date().toISOString(),
      });
    }

    // 2. Fetch all profiles to populate personal notifications
    const { data: profiles } = await adminSupabase.from("profiles").select("id");
    if (profiles && profiles.length > 0) {
      const rows = profiles.map((p) => ({
        user_id: p.id,
        title,
        body,
        data: {
          deep_link: deepLink,
          lesson_id: lessonId,
          material_id: materialId,
        },
      }));
      await (adminSupabase as any).from("notifications").insert(rows);
    }

    // 3. Broadcast in Realtime via Supabase REST API
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (supabaseUrl && serviceRoleKey) {
      await fetch(`${supabaseUrl}/realtime/v1/api/broadcast`, {
        method: "POST",
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [
            {
              topic: "classroom_alerts",
              event: "new_alert",
              payload: {
                title,
                body,
                deep_link: deepLink,
                lesson_id: lessonId,
                material_id: materialId,
                timestamp: new Date().toISOString(),
              },
            },
          ],
        }),
      });
    }
  } catch (err) {
    console.error("Error broadcasting notification:", err);
  }
}
