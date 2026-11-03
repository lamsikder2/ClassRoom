# 09 — AI Build Prompts (ধাপে ধাপে কোড তৈরির প্রম্পট গাইড)

> আপনি যদি কোনো AI কোডিং অ্যাসিস্ট্যান্ট (Cursor, Claude, Copilot, ChatGPT ইত্যাদি) ব্যবহার করে কোড জেনারেট করতে চান, তবে নিচের প্রম্পটগুলো ধারাবাহিকভাবে ব্যবহার করুন। প্রতিটি প্রম্পট স্বয়ংসম্পূর্ণ এবং সিস্টেমের সুনির্দিষ্ট নিয়মাবলী অনুসরণ করে তৈরি।

---

## প্রম্পট ব্যবহারের নিয়মাবলী

1. **কোনো ডেমো ডেটা নয়:** প্রতিটি প্রম্পটে স্পষ্ট নির্দেশ দেওয়া আছে যে কোনো হার্ডকোডেড বা ডামি ডেটা তৈরি করা যাবে না।
2. **ডাটাবেস ও ফাইলের রেফারেন্স:** প্রম্পট রান করার সময় সংশ্লিষ্ট ডকুমেন্ট ফাইলটি (যেমন `docs/sql/schema.sql`, `docs/05-DESIGN-SYSTEM.md`) AI-কে রেফারেন্স হিসেবে দিন।

---

## অংশ ১: Next.js অ্যাডমিন প্যানেল তৈরির প্রম্পটসমূহ

### প্রম্পট ১: প্রজেক্ট সেটআপ, Auth ও Middleware
```markdown
You are a senior Next.js 15 and TypeScript engineer.
We are building the Admin Panel for an educational platform called "ClassRoom".
Tech stack: Next.js 15 (App Router), React 19, TypeScript (strict), Tailwind CSS v4, shadcn/ui, and @supabase/ssr.

Refer to the database schema in `docs/sql/schema.sql` and admin specs in `docs/07-ADMIN-PANEL.md`.

STRICT RULES:
1. NO DEMO/MOCK/SEED DATA. Always fetch from Supabase. Handle empty states gracefully.
2. Protect all routes using `middleware.ts`. Check session and ensure JWT claim `user_role` is 'admin' or 'super_admin'. If student, sign out and redirect to `/login?error=unauthorized`.
3. Create server-side Supabase client in `lib/supabase/server.ts` and client-side in `lib/supabase/client.ts`.
4. Create an authentication guard helper `requireAdmin()` in `lib/auth.ts` which uses `import 'server-only'`.

Please generate:
1. `middleware.ts` with token refresh and role check.
2. `lib/supabase/server.ts`, `lib/supabase/client.ts`, and `lib/auth.ts`.
3. `app/(auth)/login/page.tsx` with email/password login and error message in Bengali.
4. `app/(dashboard)/layout.tsx` with a collapsible sidebar (Dashboard, Levels, Subjects, Lessons, Question Bank, Exams, Students, Audit Logs, Settings) and top navbar with user profile dropdown and theme toggle.
```

---

### প্রম্পট ২: কনটেন্ট হায়ারার্কি CRUD (Levels, Subjects, Chapters, Lessons, Materials)
```markdown
We are building the Content Management module for the ClassRoom Next.js 15 Admin Panel.
Refer to `docs/sql/schema.sql` tables: `levels`, `subjects`, `chapters`, `lessons`, `materials`.

REQUIREMENTS:
1. Levels CRUD: Create, read, update, delete with slug auto-generation.
2. Subjects CRUD: Filter by level, HEX color picker (`color_hex`), icon image upload to Supabase storage bucket `public-assets/subjects/`, drag-and-drop sort order.
3. Chapters CRUD: Per-subject chapter list with chapter number and sort order.
4. Lessons CRUD:
   - Video provider selection: 'youtube', 'bunny', or 'none'.
   - YouTube URL input with regex that automatically extracts the 11-character video ID and auto-fills thumbnail URL (`https://img.youtube.com/vi/${id}/hqdefault.jpg`).
   - Bunny Stream input (video GUID).
   - Rich Markdown description with KaTeX preview.
   - Publish toggle (`is_published`).
5. Materials Manager:
   - Add Lecture Sheet, Class Note, or Other.
   - Google Drive link input: regex to extract Drive file ID `/(?:\/d\/|[?&]id=)([A-Za-z0-9_-]{10,})/` and show an iframe preview (`https://drive.google.com/file/d/${id}/preview`).
   - Direct PDF upload to Supabase storage bucket `materials` (private).
   - `allow_download` boolean toggle.
6. NO DEMO DATA: If no records exist, show an empty state in Bengali with an action button.

Please generate the Server Actions in `actions/content.ts` with Zod validation, and the page components with TanStack Table.
```

---

### প্রম্পট ৩: কোশ্চেন ব্যাংক ও বাল্ক এক্সেল ইমপোর্ট
```markdown
We are building the Question Bank and Bulk Import feature for ClassRoom Next.js 15 Admin Panel.
Refer to `docs/sql/schema.sql` tables: `questions`, `question_options`, and specs in `docs/07-ADMIN-PANEL.md`.

REQUIREMENTS:
1. Question Bank List: Filter by Subject, Chapter, Difficulty (easy, medium, hard), and Tags. Search by question body.
2. Single Question Creator:
   - Body input (Markdown + LaTeX).
   - Image upload (optional).
   - 4 options (A, B, C, D) with radio button to mark exactly ONE option as correct (enforce database constraint).
   - Explanation field with optional solution image.
3. Bulk Excel / CSV Import:
   - Download sample template button (`chapter_id, question_body, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty, tags`).
   - Drag-and-drop file upload using SheetJS (`xlsx`).
   - Client-side validation table preview: highlight invalid rows in red (e.g., missing correct option or empty body) and show error messages.
   - Atomic Server Action to import valid rows in a single batch.

Please generate the components and Server Actions.
```

---

### প্রম্পট ৪: এক্সাম উইজার্ড ও রেজাল্ট অ্যানালাইসিস
```markdown
We are building the Exam Creation Wizard and Analytics module for ClassRoom Next.js 15 Admin Panel.
Refer to `docs/sql/schema.sql` tables: `exams`, `exam_questions`, `exam_attempts` and RPC `admin_exam_stats(p_exam_id)`.

REQUIREMENTS:
1. Exam Wizard (`/admin/exams/new`):
   - Step 1: Title, Scope (lesson, chapter, subject cascading selects), Mode (practice vs live), Start/End window for live.
   - Step 2: Duration (minutes), Mark per question, Negative mark (default 0.25), Pass percentage, Max attempts, Answer visibility ('immediately', 'after_end', 'never').
   - Step 3: Question selection from Question Bank (manual checkbox selection or random pick N questions).
   - Step 4: Summary & Publish toggle.
2. Exam Stats Page (`/admin/exams/[id]/stats`):
   - Call RPC `admin_exam_stats`.
   - Cards: Total attempts, Unique students, Average score, Pass percentage.
   - Question Accuracy breakdown list: Show which questions students failed the most.
   - Student attempts list with score, time taken, and export to CSV button.
3. Guard: Prevent editing questions of an exam if it already has completed attempts.

Please generate the complete wizard and stats page components.
```

---

## অংশ ২: Flutter স্টুডেন্ট অ্যাপ তৈরির প্রম্পটসমূহ

### প্রম্পট ৫: Flutter প্রজেক্ট সেটআপ, থিম ও রাউটিং
```markdown
You are a senior Flutter and Dart engineer.
We are building the student-facing mobile application for "ClassRoom".
Stack: Flutter 3.24+, flutter_riverpod 2.6+, riverpod_annotation, go_router 14.6+, flutter_secure_storage, google_fonts.

Refer to:
- Color tokens & typography in `docs/05-DESIGN-SYSTEM.md` (Primary Indigo #4F46E5, Hind Siliguri font for Bengali, Inter for English).
- Architecture specs in `docs/06-FLUTTER-APP.md`.

REQUIREMENTS:
1. Setup `AppTheme` (light & dark mode) matching the tokens in `docs/05-DESIGN-SYSTEM.md`. Configure Google Fonts for `Hind Siliguri` with proper line heights.
2. Initialize Supabase with custom `SecureLocalStorage` using `flutter_secure_storage`.
3. Configure `go_router` with `StatefulShellRoute.indexedStack` for 4 bottom navigation tabs:
   - Tab 1: Dashboard (`/dashboard`)
   - Tab 2: Subjects (`/subjects`)
   - Tab 3: Exam (`/exams`)
   - Tab 4: Profile (`/profile`)
4. Auth redirect guard: If unauthenticated, redirect to `/login`. If authenticated but `profiles.onboarded` is false, redirect to `/onboarding`.
5. STRICT RULE: NO DEMO DATA. All data must come from Supabase. Create reusable `EmptyStateWidget` and `ShimmerSkeleton`.

Please generate the project architecture, theme, storage adapter, and router.
```

---

### প্রম্পট ৬: বিষয়, অধ্যায় ও ক্লাসের তালিকা (Box Card Grid)
```markdown
We are implementing the Course Navigation flow in the ClassRoom Flutter student app.
Refer to `docs/05-DESIGN-SYSTEM.md` (§10.4, 10.5, 10.6) and `docs/06-FLUTTER-APP.md`.
Tables: `levels`, `subjects`, `chapters`, `lessons`, `lesson_progress`.

REQUIREMENTS:
1. `SubjectsScreen`:
   - Fetch published subjects for student's selected level ordered by `sort_order`.
   - Grid layout with `SubjectCard` showing subject icon, title, progress bar, and accent color from `color_hex`.
2. `ChaptersScreen`:
   - Fetch chapters for selected subject.
   - List layout with `ChapterTile` showing chapter number badge, title, count of lessons and exams.
3. `LessonsScreen`:
   - Fetch lessons for selected chapter.
   - Display as BOX CARDS (`LessonCard`): 16:9 thumbnail, video duration badge, title, instructor name, and "✓ সম্পন্ন" badge if watched.
4. All screens must handle:
   - Loading state with Shimmer.
   - Empty state with Bengali message ("এখনো কোনো ক্লাস যোগ করা হয়নি। খুব শীঘ্রই আসছে!").
   - Error state with retry button.

Please generate the Freezed models, Riverpod providers, and presentation screens.
```

---

### প্রম্পট ৭: ক্লাস ডিটেইল স্ক্রিন ও ভিডিও প্লেয়ার ইন্টিগ্রেশন
```markdown
We are implementing the Lesson Detail screen with video playback and material cards in ClassRoom Flutter app.
Refer to `docs/05-DESIGN-SYSTEM.md` (§10.7) and `docs/06-FLUTTER-APP.md` (§7).
Tables: `lessons`, `materials`, `lesson_progress`.

REQUIREMENTS:
1. Video Player Container:
   - If `video_provider == 'youtube'`, use `youtube_player_iframe` (unlisted video player, hide branding/related videos).
   - If `video_provider == 'bunny'`, request signed HLS URL from Supabase Edge Function `bunny-signed-url` and play via `media_kit`.
2. Progress Tracking:
   - While playing, call Supabase RPC `update_lesson_progress(p_lesson_id, p_position_sec, p_delta_watched_sec)` every 10 seconds.
   - Update on pause and on screen dispose.
   - Resume playback automatically from `last_position_sec`.
3. Lesson Info: Title, instructor, and Markdown description with KaTeX math rendering (`flutter_math_fork`).
4. Material Cards Row (below video):
   - Card 1: "Lecture Sheet" (opens PDF screen).
   - Card 2: "Exam" (opens lesson-specific exam intro).
   - Card 3: "Class Note" (opens rich text note).
   - If a material type has no items, display as disabled or hide.
5. Security: Enable `screen_protector` to prevent screenshots/recording on this screen.

Please generate the unified video controller, progress manager, and `LessonDetailScreen`.
```

---

### প্রম্পট ৮: লেকচার শিট (ড্রাইভ প্রিভিউ ও অফলাইন ডাউনলোড) এবং ক্লাস নোট
```markdown
We are building the Material Consumption screens in the ClassRoom Flutter student app.
Refer to `docs/06-FLUTTER-APP.md` (§8).
Tables: `materials`.

REQUIREMENTS:
1. `PdfViewerScreen`:
   - For `source == 'drive'`: Download PDF from `https://drive.usercontent.google.com/download?id=${fileId}&export=download&confirm=t` to app cache and render natively using `pdfrx`.
   - Fallback to WebView with `https://drive.google.com/file/d/${fileId}/preview` if direct download fails.
   - If `allow_download == true`, show prominent "ডাউনলোড" button in AppBar.
   - Download Manager: Download file via Dio to `getApplicationDocumentsDirectory()/downloads/` with progress notification. Save metadata to local Hive/Drift index so student can read offline in Profile -> Downloads.
   - Disable screenshot and screen recording via `screen_protector`.
2. `ClassNoteScreen`:
   - For `source == 'rich_text'`: Render `content_md` using `flutter_markdown` and `flutter_math_fork` for LaTeX equations (`$...$` and `$$...$$`).
   - Clean, reading-optimized typography with dark mode support.

Please generate the download service, PDF viewer screen, and class note screen.
```

---

### প্রম্পট ৯: সম্পূর্ণ এক্সাম ইঞ্জিন (Server-Authoritative Exam Flow)
```markdown
We are building the complete Exam Engine for the ClassRoom Flutter student app.
Refer to:
- Database RPCs in `docs/sql/schema.sql` (`start_exam`, `save_answer`, `submit_exam`, `get_attempt_result`, `get_exam_leaderboard`).
- Exam State Machine & Timer in `docs/06-FLUTTER-APP.md` (§9).
- Wireframes in `docs/05-DESIGN-SYSTEM.md` (§10.9, 10.10).

CRITICAL REQUIREMENTS:
1. `ExamInstructionScreen`: Display exam duration, total marks, negative marking rules, max attempts, and remaining attempts. Show "পরীক্ষা শুরু করুন" button.
2. `ExamTakingScreen`:
   - Call `start_exam(p_exam_id)` RPC. Receive `attempt_id`, `deadline_at`, `server_now`, and questions array (without correct answers).
   - Server-Synced Timer: Calculate offset `server_now - DateTime.now()`. Display sticky countdown timer. When remaining time reaches 0, trigger automatic submission.
   - Auto-Save: Whenever student taps an option, call `save_answer(attempt_id, question_id, option_id)` immediately. If network fails, queue locally and retry.
   - Question Palette: Bottom drawer/grid showing answered, unanswered, and "পরে দেখব" (marked for review) questions.
   - Math & Images: Render LaTeX math in questions/options and support question images.
3. `ExamResultScreen`:
   - Call `submit_exam(attempt_id)` or fetch `get_attempt_result(attempt_id)`.
   - Show Score, Percentage, Pass/Fail badge, Correct/Wrong/Skipped counters, Rank, and Time taken.
   - Review section (if answers revealed): Green highlight for correct answers, Red for student's wrong answer, with explanation text.
4. `LeaderboardScreen`: Call `get_exam_leaderboard(p_exam_id, 50)` and show top students with highlight on current user's rank.
5. Error Handling: Map all database error codes (`TIME_UP`, `MAX_ATTEMPTS_REACHED`, etc.) to clear Bengali messages.

Please generate the complete state notifier, timer logic, and screens.
```

---

### প্রম্পট ১০: ড্যাশবোর্ড, স্ট্রিক ও এনগেজমেন্ট
```markdown
We are building the Student Dashboard (Home Tab) for the ClassRoom Flutter app.
Refer to `docs/sql/schema.sql` RPC `get_my_dashboard()` and `docs/05-DESIGN-SYSTEM.md` (§10.3).

REQUIREMENTS:
1. Header: Student greeting with name, avatar, and level switcher dropdown.
2. Streak & Stats Card:
   - Days streak (🔥), total study hours, completed lessons count, exams taken count with average %.
3. Announcements Carousel:
   - Fetch active published announcements from `announcements` table.
   - Tap to open deep link or dialog.
4. Continue Watching Horizontal List:
   - Display in-progress lessons with thumbnail, chapter title, and progress bar percentage. Tap to resume playback.
5. Upcoming Live Exams:
   - Display published live exams with countdown timer ("শুরু হতে বাকি: ০১ ঘণ্টা ২০ মিনিট"). Tap to open exam instructions.
6. Weak Chapters Card:
   - Call RPC `get_my_weak_chapters` to suggest chapters where accuracy is below 60%.
7. Pull-to-refresh to reload all dashboard data.

Please generate the dashboard controller and UI widgets.
```

