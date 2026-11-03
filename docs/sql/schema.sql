-- =====================================================================
--  ClassRoom — Supabase Database Schema (v1.0)
--  Source of truth for: Flutter Student App + Next.js Admin Panel
--
--  ⚠️  NO DEMO / SEED DATA. এই ফাইলে কোনো INSERT করা fake data নেই।
--      সব কনটেন্ট Admin Panel থেকে আসবে।
--
--  চালানোর নিয়ম:
--    supabase/migrations/<timestamp>_init.sql হিসেবে রাখুন এবং
--    `supabase db push` চালান, অথবা Supabase Dashboard → SQL Editor এ রান করুন।
--  রান করার পর: Dashboard → Authentication → Hooks → "Custom Access Token"
--    এ  public.custom_access_token_hook  সিলেক্ট করুন।
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. EXTENSIONS
-- ---------------------------------------------------------------------
create extension if not exists pgcrypto;      -- gen_random_uuid()
create extension if not exists pg_trgm;       -- fuzzy search
create extension if not exists pg_cron;       -- scheduled jobs (enable from Dashboard → Database → Extensions if needed)

-- ---------------------------------------------------------------------
-- 1. ENUM TYPES
-- ---------------------------------------------------------------------
create type public.app_role          as enum ('student', 'admin', 'super_admin');
create type public.video_provider    as enum ('youtube', 'bunny', 'none');
create type public.material_type     as enum ('lecture_sheet', 'class_note', 'other');
create type public.material_source   as enum ('drive', 'storage', 'rich_text');
create type public.exam_scope        as enum ('lesson', 'chapter', 'subject');
create type public.exam_mode         as enum ('practice', 'live');
create type public.answer_visibility as enum ('immediately', 'after_end', 'never');
create type public.attempt_status    as enum ('in_progress', 'submitted', 'expired');
create type public.difficulty_level  as enum ('easy', 'medium', 'hard');
create type public.bookmark_type     as enum ('lesson', 'material', 'question');
create type public.subscription_status as enum ('pending', 'active', 'expired', 'cancelled');

-- ---------------------------------------------------------------------
-- 2. GENERIC HELPERS
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- 3. USERS, ROLES, PROFILES
-- ---------------------------------------------------------------------
create table public.levels (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (char_length(name) between 1 and 80),   -- e.g. "এইচএসসি"
  name_en      text,                                                        -- e.g. "HSC"
  slug         text not null unique check (slug ~ '^[a-z0-9-]+$'),
  description  text,
  icon_url     text,
  sort_order   int  not null default 0,
  is_published boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text check (char_length(full_name) <= 100),
  avatar_url    text,
  phone         text check (phone is null or phone ~ '^\+?[0-9]{10,15}$'),
  institution   text check (char_length(institution) <= 150),
  level_id      uuid references public.levels(id) on delete set null,
  locale        text not null default 'bn' check (locale in ('bn', 'en')),
  is_blocked    boolean not null default false,
  onboarded     boolean not null default false,
  last_seen_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.user_roles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       public.app_role not null default 'student',
  granted_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- Role helpers (SECURITY DEFINER → RLS bypass করে শুধু নিজের role পড়ে; JWT stale হলেও সাথে সাথে revoke কাজ করে)
create or replace function public.current_role_name()
returns public.app_role
language sql stable security definer set search_path = public as $$
  select coalesce((select role from public.user_roles where user_id = auth.uid()), 'student'::public.app_role);
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role in ('admin', 'super_admin')
  ) or (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') in ('admin', 'super_admin')
  ) or (
    coalesce(auth.jwt() ->> 'role', '') = 'service_role'
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = 'super_admin'
  ) or (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'super_admin'
  ) or (
    coalesce(auth.jwt() ->> 'role', '') = 'service_role'
  );
$$;

create or replace function public.is_active_student()
returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and not coalesce((select is_blocked from public.profiles where id = auth.uid()), false);
$$;

-- New user → profile + student role
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  );
  insert into public.user_roles (user_id, role) values (new.id, 'student');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Student যেন নিজের is_blocked / onboarded ছাড়া sensitive column বদলাতে না পারে
create or replace function public.protect_profile_columns()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() and coalesce(auth.role(), '') <> 'service_role' then
    new.is_blocked := old.is_blocked;
    new.id         := old.id;
    new.created_at := old.created_at;
  end if;
  return new;
end $$;

create trigger trg_profiles_protect before update on public.profiles
  for each row execute function public.protect_profile_columns();
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger trg_levels_updated before update on public.levels
  for each row execute function public.set_updated_at();

-- Custom Access Token Hook → JWT এ `user_role` claim যোগ করে (Next.js middleware দ্রুত routing এর জন্য)
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb;
  v_role public.app_role;
begin
  select role into v_role from public.user_roles where user_id = (event->>'user_id')::uuid;
  claims := event->'claims';
  claims := jsonb_set(claims, '{user_role}', to_jsonb(coalesce(v_role, 'student'::public.app_role)));
  return jsonb_set(event, '{claims}', claims);
end $$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook from authenticated, anon, public;
grant select on table public.user_roles to supabase_auth_admin;
-- (RLS enable হওয়ার পর hook যেন user_roles পড়তে পারে — policy section 11 এ "auth_admin_read_roles")

-- ---------------------------------------------------------------------
-- 4. CONTENT HIERARCHY: levels → subjects → chapters → lessons → materials
-- ---------------------------------------------------------------------
create table public.subjects (
  id           uuid primary key default gen_random_uuid(),
  level_id     uuid not null references public.levels(id) on delete cascade,
  name         text not null check (char_length(name) between 1 and 80),
  name_en      text,
  slug         text not null check (slug ~ '^[a-z0-9-]+$'),
  description  text,
  icon_url     text,
  color_hex    text check (color_hex is null or color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  sort_order   int not null default 0,
  is_published boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (level_id, slug)
);

create table public.chapters (
  id           uuid primary key default gen_random_uuid(),
  subject_id   uuid not null references public.subjects(id) on delete cascade,
  chapter_no   int  check (chapter_no is null or chapter_no > 0),
  title        text not null check (char_length(title) between 1 and 150),
  description  text,
  sort_order   int not null default 0,
  is_published boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.lessons (
  id                 uuid primary key default gen_random_uuid(),
  chapter_id         uuid not null references public.chapters(id) on delete cascade,
  title              text not null check (char_length(title) between 1 and 200),
  description        text,                               -- Markdown
  video_provider     public.video_provider not null default 'none',
  video_ref          text,                               -- YouTube video ID অথবা Bunny video GUID
  video_duration_sec int check (video_duration_sec is null or video_duration_sec >= 0),
  thumbnail_url      text,
  instructor_name    text,
  sort_order         int not null default 0,
  is_premium         boolean not null default false,     -- payment-ready (MVP তে সব false)
  is_published       boolean not null default false,
  published_at       timestamptz,
  search_vector      tsvector generated always as (
                       to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, ''))
                     ) stored,
  created_by         uuid references auth.users(id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint lessons_video_ref_required
    check (video_provider = 'none' or (video_ref is not null and char_length(video_ref) > 0))
);

create table public.materials (
  id             uuid primary key default gen_random_uuid(),
  lesson_id      uuid not null references public.lessons(id) on delete cascade,
  type           public.material_type   not null,
  source         public.material_source not null,
  title          text not null check (char_length(title) between 1 and 200),
  drive_file_id  text check (drive_file_id is null or drive_file_id ~ '^[A-Za-z0-9_-]{10,}$'),
  storage_path   text,                                   -- bucket 'materials' এর ভিতরের path
  content_md     text,                                   -- rich_text class note (Markdown + LaTeX)
  file_size_bytes bigint,
  page_count     int,
  allow_download boolean not null default true,
  sort_order     int not null default 0,
  is_published   boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint materials_source_payload check (
       (source = 'drive'     and drive_file_id is not null)
    or (source = 'storage'   and storage_path  is not null)
    or (source = 'rich_text' and content_md    is not null)
  )
);

create trigger trg_subjects_updated  before update on public.subjects  for each row execute function public.set_updated_at();
create trigger trg_chapters_updated  before update on public.chapters  for each row execute function public.set_updated_at();
create trigger trg_lessons_updated   before update on public.lessons   for each row execute function public.set_updated_at();
create trigger trg_materials_updated before update on public.materials for each row execute function public.set_updated_at();

-- Lesson publish হলে published_at সেট
create or replace function public.set_published_at()
returns trigger language plpgsql as $$
begin
  if new.is_published and new.published_at is null
     and (tg_op = 'INSERT' or not old.is_published) then
    new.published_at := now();
  end if;
  return new;
end $$;
create trigger trg_lessons_published before insert or update on public.lessons
  for each row execute function public.set_published_at();

-- ---------------------------------------------------------------------
-- 5. QUESTION BANK & EXAMS
-- ---------------------------------------------------------------------
create table public.questions (
  id                uuid primary key default gen_random_uuid(),
  chapter_id        uuid not null references public.chapters(id) on delete cascade,
  body              text not null check (char_length(body) between 1 and 5000),   -- Markdown + LaTeX ($...$)
  image_url         text,
  explanation       text,
  explanation_image_url text,
  difficulty        public.difficulty_level not null default 'medium',
  tags              text[] not null default '{}',
  source_ref        text,                                  -- e.g. "ঢাকা বোর্ড ২০২৩"
  created_by        uuid references auth.users(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table public.question_options (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 1000),
  image_url   text,
  is_correct  boolean not null default false,
  sort_order  int not null default 0
);
-- প্রতি প্রশ্নে ঠিক একটি সঠিক উত্তর (single-answer MCQ)
create unique index uq_one_correct_option on public.question_options(question_id) where is_correct;

create table public.exams (
  id                     uuid primary key default gen_random_uuid(),
  title                  text not null check (char_length(title) between 1 and 200),
  description            text,
  instructions           text,
  scope                  public.exam_scope not null,
  subject_id             uuid not null references public.subjects(id) on delete cascade,
  chapter_id             uuid references public.chapters(id) on delete cascade,
  lesson_id              uuid references public.lessons(id)  on delete cascade,
  mode                   public.exam_mode not null default 'practice',
  duration_sec           int  not null check (duration_sec between 60 and 4 * 3600),
  mark_per_question      numeric(5,2) not null default 1 check (mark_per_question > 0),
  negative_mark          numeric(5,2) not null default 0 check (negative_mark >= 0),
  pass_percentage        numeric(5,2) not null default 40 check (pass_percentage between 0 and 100),
  shuffle_questions      boolean not null default true,
  shuffle_options        boolean not null default true,
  max_attempts           int check (max_attempts is null or max_attempts > 0),   -- null = unlimited
  answer_visibility      public.answer_visibility not null default 'immediately',
  starts_at              timestamptz,                    -- live exam window
  ends_at                timestamptz,
  is_premium             boolean not null default false,
  is_published           boolean not null default false,
  created_by             uuid references auth.users(id),
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  constraint exams_scope_consistency check (
       (scope = 'subject' and chapter_id is null and lesson_id is null)
    or (scope = 'chapter' and chapter_id is not null and lesson_id is null)
    or (scope = 'lesson'  and chapter_id is not null and lesson_id is not null)
  ),
  constraint exams_live_window check (
       mode = 'practice'
    or (starts_at is not null and ends_at is not null and ends_at > starts_at)
  )
);

create table public.exam_questions (
  exam_id     uuid not null references public.exams(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete restrict,
  sort_order  int not null default 0,
  primary key (exam_id, question_id)
);

create table public.exam_attempts (
  id               uuid primary key default gen_random_uuid(),
  exam_id          uuid not null references public.exams(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  attempt_no       int  not null,
  status           public.attempt_status not null default 'in_progress',
  started_at       timestamptz not null default now(),
  deadline_at      timestamptz not null,
  submitted_at     timestamptz,
  question_order   uuid[] not null,                     -- shuffled order snapshot
  option_order     jsonb  not null default '{}'::jsonb, -- { question_id: [option_id,...] }
  total_questions  int not null,
  total_marks      numeric(7,2) not null,
  correct_count    int,
  wrong_count      int,
  skipped_count    int,
  score            numeric(7,2),
  percentage       numeric(5,2),
  is_passed        boolean,
  time_taken_sec   int,
  unique (exam_id, user_id, attempt_no)
);
-- একজন ইউজারের একটি এক্সামে একই সময়ে একটির বেশি in_progress attempt নয়
create unique index uq_one_active_attempt on public.exam_attempts(exam_id, user_id) where status = 'in_progress';

create table public.attempt_answers (
  attempt_id         uuid not null references public.exam_attempts(id) on delete cascade,
  question_id        uuid not null references public.questions(id) on delete cascade,
  selected_option_id uuid references public.question_options(id) on delete set null,
  is_correct         boolean,                -- submit এর সময় সার্ভার সেট করে
  answered_at        timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

create trigger trg_questions_updated before update on public.questions for each row execute function public.set_updated_at();
create trigger trg_exams_updated     before update on public.exams     for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 6. ENGAGEMENT: progress, bookmarks, notifications, devices
-- ---------------------------------------------------------------------
create table public.lesson_progress (
  user_id           uuid not null references auth.users(id) on delete cascade,
  lesson_id         uuid not null references public.lessons(id) on delete cascade,
  last_position_sec int not null default 0 check (last_position_sec >= 0),
  watched_sec       int not null default 0 check (watched_sec >= 0),
  is_completed      boolean not null default false,
  completed_at      timestamptz,
  updated_at        timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
create trigger trg_progress_updated before update on public.lesson_progress for each row execute function public.set_updated_at();

create table public.bookmarks (
  user_id     uuid not null references auth.users(id) on delete cascade,
  entity_type public.bookmark_type not null,
  entity_id   uuid not null,
  note        text check (char_length(note) <= 500),
  created_at  timestamptz not null default now(),
  primary key (user_id, entity_type, entity_id)
);

create table public.announcements (
  id           uuid primary key default gen_random_uuid(),
  level_id     uuid references public.levels(id) on delete cascade,  -- null = সবার জন্য
  title        text not null check (char_length(title) between 1 and 200),
  body         text not null,
  image_url    text,
  deep_link    text,                                    -- e.g. classroom://lesson/<id>
  is_pinned    boolean not null default false,
  is_published boolean not null default false,
  published_at timestamptz,
  expires_at   timestamptz,
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now()
);

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null,
  body       text not null,
  data       jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create table public.devices (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  device_id    text not null,                 -- app-generated stable install id
  fcm_token    text,
  platform     text not null check (platform in ('android', 'ios', 'web')),
  device_name  text,
  app_version  text,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  unique (user_id, device_id)
);

-- ---------------------------------------------------------------------
-- 7. PAYMENT-READY (MVP তে UI নেই, শুধু স্কিমা)
-- ---------------------------------------------------------------------
create table public.plans (
  id            uuid primary key default gen_random_uuid(),
  level_id      uuid references public.levels(id) on delete cascade,
  name          text not null,
  price_bdt     numeric(10,2) not null check (price_bdt >= 0),
  duration_days int not null check (duration_days > 0),
  is_active     boolean not null default false,
  created_at    timestamptz not null default now()
);

create table public.subscriptions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  plan_id         uuid not null references public.plans(id),
  status          public.subscription_status not null default 'pending',
  starts_at       timestamptz,
  ends_at         timestamptz,
  provider        text,                -- 'bkash' | 'sslcommerz'
  provider_txn_id text unique,
  amount_bdt      numeric(10,2),
  created_at      timestamptz not null default now()
);

create or replace function public.has_premium_access()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists (
    select 1 from public.subscriptions
    where user_id = auth.uid() and status = 'active' and now() between starts_at and ends_at
  );
$$;

-- ---------------------------------------------------------------------
-- 8. SYSTEM: settings & audit log
-- ---------------------------------------------------------------------
create table public.app_settings (
  key        text primary key check (key ~ '^[a-z0-9_.]+$'),
  value      jsonb not null,
  is_public  boolean not null default false,  -- true হলে অ্যাপ পড়তে পারবে (e.g. min_app_version)
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id         bigint generated always as identity primary key,
  actor_id   uuid,
  action     text not null,                 -- INSERT | UPDATE | DELETE
  table_name text not null,
  record_id  text,
  old_data   jsonb,
  new_data   jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.audit_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (
    auth.uid(), tg_op, tg_table_name,
    coalesce((case when tg_op = 'DELETE' then old.id else new.id end)::text, null),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array['levels','subjects','chapters','lessons','materials','questions','exams','announcements','plans'] loop
    execute format('create trigger trg_audit_%1$s after insert or update or delete on public.%1$I
                    for each row execute function public.audit_trigger()', t);
  end loop;
end $$;

-- user_roles এর জন্য আলাদা audit (id column নেই)
create or replace function public.audit_roles_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), tg_op, 'user_roles', coalesce(new.user_id, old.user_id)::text,
          case when tg_op <> 'INSERT' then to_jsonb(old) end,
          case when tg_op <> 'DELETE' then to_jsonb(new) end);
  return coalesce(new, old);
end $$;
create trigger trg_audit_user_roles after insert or update or delete on public.user_roles
  for each row execute function public.audit_roles_trigger();

-- ---------------------------------------------------------------------
-- 9. INDEXES
-- ---------------------------------------------------------------------
create index idx_subjects_level        on public.subjects(level_id, sort_order);
create index idx_chapters_subject      on public.chapters(subject_id, sort_order);
create index idx_lessons_chapter       on public.lessons(chapter_id, sort_order);
create index idx_lessons_published_at  on public.lessons(published_at desc) where is_published;
create index idx_lessons_search        on public.lessons using gin(search_vector);
create index idx_lessons_title_trgm    on public.lessons using gin(title gin_trgm_ops);
create index idx_materials_lesson      on public.materials(lesson_id, sort_order);
create index idx_questions_chapter     on public.questions(chapter_id);
create index idx_questions_tags        on public.questions using gin(tags);
create index idx_options_question      on public.question_options(question_id, sort_order);
create index idx_exams_subject         on public.exams(subject_id) where is_published;
create index idx_exams_chapter         on public.exams(chapter_id) where is_published;
create index idx_exams_lesson          on public.exams(lesson_id)  where is_published;
create index idx_exams_live            on public.exams(starts_at)  where mode = 'live' and is_published;
create index idx_exam_questions_q      on public.exam_questions(question_id);
create index idx_attempts_user         on public.exam_attempts(user_id, started_at desc);
create index idx_attempts_exam_score   on public.exam_attempts(exam_id, score desc) where status = 'submitted';
create index idx_attempts_deadline     on public.exam_attempts(deadline_at) where status = 'in_progress';
create index idx_progress_user_recent  on public.lesson_progress(user_id, updated_at desc);
create index idx_notifications_user    on public.notifications(user_id, created_at desc);
create index idx_announcements_pub     on public.announcements(published_at desc) where is_published;
create index idx_audit_created         on public.audit_logs(created_at desc);
create index idx_audit_table_record    on public.audit_logs(table_name, record_id);

-- ---------------------------------------------------------------------
-- 10. VISIBILITY HELPERS (published + সব parent published)
-- ---------------------------------------------------------------------
create or replace function public.is_chapter_visible(p_chapter_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.chapters c
    join public.subjects s on s.id = c.subject_id
    join public.levels   l on l.id = s.level_id
    where c.id = p_chapter_id and c.is_published and s.is_published and l.is_published
  );
$$;

create or replace function public.is_lesson_visible(p_lesson_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.lessons ls
    where ls.id = p_lesson_id and ls.is_published and public.is_chapter_visible(ls.chapter_id)
  );
$$;

-- ---------------------------------------------------------------------
-- 11. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.levels           enable row level security;
alter table public.profiles         enable row level security;
alter table public.user_roles       enable row level security;
alter table public.subjects         enable row level security;
alter table public.chapters         enable row level security;
alter table public.lessons          enable row level security;
alter table public.materials        enable row level security;
alter table public.questions        enable row level security;
alter table public.question_options enable row level security;
alter table public.exams            enable row level security;
alter table public.exam_questions   enable row level security;
alter table public.exam_attempts    enable row level security;
alter table public.attempt_answers  enable row level security;
alter table public.lesson_progress  enable row level security;
alter table public.bookmarks        enable row level security;
alter table public.announcements    enable row level security;
alter table public.notifications    enable row level security;
alter table public.devices          enable row level security;
alter table public.plans            enable row level security;
alter table public.subscriptions    enable row level security;
alter table public.app_settings     enable row level security;
alter table public.audit_logs       enable row level security;

-- ---- Admin: সব টেবিলে full access (audit_logs শুধু read) ----
do $$
declare t text;
begin
  foreach t in array array['levels','profiles','subjects','chapters','lessons','materials','questions',
                           'question_options','exams','exam_questions','exam_attempts','attempt_answers',
                           'lesson_progress','bookmarks','announcements','notifications','devices',
                           'plans','subscriptions','app_settings'] loop
    execute format('create policy "admin_all_%1$s" on public.%1$I for all to authenticated
                    using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

create policy "admin_read_audit"  on public.audit_logs for select to authenticated using (public.is_admin());
create policy "auth_admin_read_roles" on public.user_roles as permissive for select to supabase_auth_admin using (true);
create policy "admin_read_roles"  on public.user_roles for select to authenticated using (public.is_admin() or user_id = auth.uid());
-- role পরিবর্তন শুধু super_admin
create policy "super_admin_write_roles" on public.user_roles for all to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

-- ---- Student: published content read ----
create policy "student_read_levels" on public.levels for select to authenticated
  using (is_published and public.is_active_student());

create policy "student_read_subjects" on public.subjects for select to authenticated
  using (is_published and public.is_active_student()
         and exists (select 1 from public.levels l where l.id = level_id and l.is_published));

create policy "student_read_chapters" on public.chapters for select to authenticated
  using (public.is_active_student() and public.is_chapter_visible(id));

create policy "student_read_lessons" on public.lessons for select to authenticated
  using (public.is_active_student() and is_published and public.is_chapter_visible(chapter_id));
-- নোট: premium lesson এর metadata দেখা যাবে (lock আইকন দেখাতে), কিন্তু video/material access RPC/Edge Function এ চেক হবে।

create policy "student_read_materials" on public.materials for select to authenticated
  using (public.is_active_student() and is_published and public.is_lesson_visible(lesson_id)
         and ((select not is_premium from public.lessons where id = lesson_id) or public.has_premium_access()));

create policy "student_read_exams" on public.exams for select to authenticated
  using (public.is_active_student() and is_published
         and exists (select 1 from public.subjects s where s.id = subject_id and s.is_published));

-- ⚠️ questions, question_options, exam_questions: student এর জন্য কোনো SELECT policy নেই।
--    প্রশ্ন শুধু start_exam() RPC দিয়ে আসবে (is_correct ছাড়া)।

-- ---- Student: own data ----
create policy "own_profile_select" on public.profiles for select to authenticated using (id = auth.uid());
create policy "own_profile_update" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "own_attempts_select" on public.exam_attempts for select to authenticated using (user_id = auth.uid());
-- attempts insert/update শুধু RPC দিয়ে (no direct write policy)

create policy "own_answers_select" on public.attempt_answers for select to authenticated
  using (exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid()));

-- progress লেখা শুধু update_lesson_progress() RPC দিয়ে (watched_sec / is_completed জালিয়াতি ঠেকাতে)
create policy "own_progress_select" on public.lesson_progress for select to authenticated
  using (user_id = auth.uid());

create policy "own_bookmarks_all" on public.bookmarks for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own_notifications_select" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "own_notifications_update" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own_devices_all" on public.devices for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own_subscriptions_select" on public.subscriptions for select to authenticated using (user_id = auth.uid());

create policy "student_read_announcements" on public.announcements for select to authenticated
  using (is_published and public.is_active_student()
         and (expires_at is null or expires_at > now())
         and (level_id is null or level_id = (select level_id from public.profiles where id = auth.uid())));

create policy "student_read_plans" on public.plans for select to authenticated using (is_active);

create policy "public_settings_read" on public.app_settings for select to anon, authenticated using (is_public);

-- ---------------------------------------------------------------------
-- 12. EXAM ENGINE RPCs (SECURITY DEFINER — server-side grading)
-- ---------------------------------------------------------------------

-- 12.1 start_exam: নতুন attempt তৈরি অথবা চলমান attempt resume
create or replace function public.start_exam(p_exam_id uuid)
returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v_uid      uuid := auth.uid();
  v_exam     public.exams;
  v_attempt  public.exam_attempts;
  v_count    int;
  v_qids     uuid[];
  v_opt_ord  jsonb := '{}'::jsonb;
  v_q        uuid;
  v_deadline timestamptz;
begin
  if v_uid is null or not public.is_active_student() then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  select * into v_exam from public.exams where id = p_exam_id and is_published;
  if not found then raise exception 'EXAM_NOT_FOUND' using errcode = 'P0002'; end if;

  if v_exam.is_premium and not public.has_premium_access() then
    raise exception 'PREMIUM_REQUIRED' using errcode = '42501';
  end if;

  if v_exam.mode = 'live' then
    if now() < v_exam.starts_at then raise exception 'EXAM_NOT_STARTED'; end if;
    if now() > v_exam.ends_at   then raise exception 'EXAM_ENDED'; end if;
  end if;

  -- চলমান attempt থাকলে resume
  select * into v_attempt from public.exam_attempts
   where exam_id = p_exam_id and user_id = v_uid and status = 'in_progress';
  if found then
    if now() > v_attempt.deadline_at then
      perform public.finalize_attempt(v_attempt.id, 'expired');
    else
      return public.build_attempt_payload(v_attempt.id);
    end if;
  end if;

  select count(*) into v_count from public.exam_attempts where exam_id = p_exam_id and user_id = v_uid;
  if v_exam.max_attempts is not null and v_count >= v_exam.max_attempts then
    raise exception 'MAX_ATTEMPTS_REACHED';
  end if;

  select array_agg(question_id order by case when v_exam.shuffle_questions then random() else sort_order end)
    into v_qids
    from public.exam_questions where exam_id = p_exam_id;
  if v_qids is null or array_length(v_qids, 1) = 0 then raise exception 'EXAM_HAS_NO_QUESTIONS'; end if;

  foreach v_q in array v_qids loop
    v_opt_ord := v_opt_ord || jsonb_build_object(v_q::text, (
      select jsonb_agg(id order by case when v_exam.shuffle_options then random() else sort_order end)
      from public.question_options where question_id = v_q));
  end loop;

  v_deadline := now() + make_interval(secs => v_exam.duration_sec);
  if v_exam.mode = 'live' and v_deadline > v_exam.ends_at then v_deadline := v_exam.ends_at; end if;

  insert into public.exam_attempts (exam_id, user_id, attempt_no, deadline_at, question_order, option_order,
                                    total_questions, total_marks)
  values (p_exam_id, v_uid, v_count + 1, v_deadline, v_qids, v_opt_ord,
          array_length(v_qids, 1), array_length(v_qids, 1) * v_exam.mark_per_question)
  returning * into v_attempt;

  return public.build_attempt_payload(v_attempt.id);
end $$;

-- 12.2 build_attempt_payload: প্রশ্ন + অপশন (is_correct বাদে) + আগের saved answer
create or replace function public.build_attempt_payload(p_attempt_id uuid)
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'attempt_id',   a.id,
    'exam_id',      a.exam_id,
    'attempt_no',   a.attempt_no,
    'started_at',   a.started_at,
    'deadline_at',  a.deadline_at,
    'server_now',   now(),
    'total_marks',  a.total_marks,
    'questions', (
      select jsonb_agg(jsonb_build_object(
        'id',        q.id,
        'body',      q.body,
        'image_url', q.image_url,
        'selected_option_id', aa.selected_option_id,
        'options', (
          select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body, 'image_url', o.image_url)
                           order by array_position(
                             array(select jsonb_array_elements_text(a.option_order -> q.id::text))::uuid[], o.id))
          from public.question_options o where o.question_id = q.id
        )
      ) order by qo.ord)
      from unnest(a.question_order) with ordinality as qo(qid, ord)
      join public.questions q on q.id = qo.qid
      left join public.attempt_answers aa on aa.attempt_id = a.id and aa.question_id = q.id
    )
  )
  from public.exam_attempts a
  where a.id = p_attempt_id;
$$;
revoke execute on function public.build_attempt_payload(uuid) from public, anon, authenticated;

-- 12.3 save_answer: প্রতিটি উত্তর সাথে সাথে সেভ (auto-save, crash-safe)
create or replace function public.save_answer(p_attempt_id uuid, p_question_id uuid, p_option_id uuid)
returns void
language plpgsql volatile security definer set search_path = public as $$
declare v_attempt public.exam_attempts;
begin
  select * into v_attempt from public.exam_attempts
   where id = p_attempt_id and user_id = auth.uid() for update;
  if not found then raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002'; end if;
  if v_attempt.status <> 'in_progress' then raise exception 'ATTEMPT_CLOSED'; end if;
  if now() > v_attempt.deadline_at + interval '10 seconds' then   -- 10s network grace
    perform public.finalize_attempt(p_attempt_id, 'expired');
    raise exception 'TIME_UP';
  end if;
  if not (p_question_id = any(v_attempt.question_order)) then raise exception 'INVALID_QUESTION'; end if;
  if p_option_id is not null and not exists (
       select 1 from public.question_options where id = p_option_id and question_id = p_question_id) then
    raise exception 'INVALID_OPTION';
  end if;

  insert into public.attempt_answers (attempt_id, question_id, selected_option_id, answered_at)
  values (p_attempt_id, p_question_id, p_option_id, now())
  on conflict (attempt_id, question_id)
  do update set selected_option_id = excluded.selected_option_id, answered_at = now();
end $$;

-- 12.4 finalize_attempt: grading (internal)
create or replace function public.finalize_attempt(p_attempt_id uuid, p_status public.attempt_status)
returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  v_attempt public.exam_attempts;
  v_exam    public.exams;
  v_correct int; v_wrong int; v_skipped int; v_score numeric;
begin
  select * into v_attempt from public.exam_attempts where id = p_attempt_id for update;
  if v_attempt.status <> 'in_progress' then return; end if;
  select * into v_exam from public.exams where id = v_attempt.exam_id;

  update public.attempt_answers aa
     set is_correct = coalesce(o.is_correct, false)
    from public.question_options o
   where aa.attempt_id = p_attempt_id and o.id = aa.selected_option_id;

  select count(*) filter (where is_correct),
         count(*) filter (where selected_option_id is not null and not coalesce(is_correct, false))
    into v_correct, v_wrong
    from public.attempt_answers where attempt_id = p_attempt_id;

  v_skipped := v_attempt.total_questions - v_correct - v_wrong;
  v_score   := greatest(0, v_correct * v_exam.mark_per_question - v_wrong * v_exam.negative_mark);

  update public.exam_attempts set
    status         = p_status,
    submitted_at   = least(now(), deadline_at + interval '10 seconds'),
    correct_count  = v_correct,
    wrong_count    = v_wrong,
    skipped_count  = v_skipped,
    score          = v_score,
    percentage     = round(v_score * 100.0 / nullif(total_marks, 0), 2),
    is_passed      = (v_score * 100.0 / nullif(total_marks, 0)) >= v_exam.pass_percentage,
    time_taken_sec = extract(epoch from (least(now(), deadline_at) - started_at))::int
  where id = p_attempt_id;
end $$;
revoke execute on function public.finalize_attempt(uuid, public.attempt_status) from public, anon, authenticated;

-- 12.5 submit_exam: student submit করলে
create or replace function public.submit_exam(p_attempt_id uuid)
returns jsonb
language plpgsql volatile security definer set search_path = public as $$
begin
  if not exists (select 1 from public.exam_attempts where id = p_attempt_id and user_id = auth.uid()) then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;
  perform public.finalize_attempt(p_attempt_id, 'submitted');
  return public.get_attempt_result(p_attempt_id);
end $$;

-- 12.6 get_attempt_result: answer_visibility মেনে রেজাল্ট + রিভিউ
create or replace function public.get_attempt_result(p_attempt_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_attempt public.exam_attempts;
  v_exam    public.exams;
  v_reveal  boolean;
  v_rank    int;
begin
  select * into v_attempt from public.exam_attempts
   where id = p_attempt_id and (user_id = auth.uid() or public.is_admin());
  if not found then raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002'; end if;
  if v_attempt.status = 'in_progress' then raise exception 'ATTEMPT_IN_PROGRESS'; end if;
  select * into v_exam from public.exams where id = v_attempt.exam_id;

  v_reveal := public.is_admin() or case v_exam.answer_visibility
                when 'immediately' then true
                when 'after_end'   then v_exam.ends_at is null or now() > v_exam.ends_at
                else false end;

  select count(*) + 1 into v_rank from (
    select distinct on (user_id) user_id, score, time_taken_sec
      from public.exam_attempts
     where exam_id = v_attempt.exam_id and status <> 'in_progress' and attempt_no = 1
  ) best
  where best.score > v_attempt.score
     or (best.score = v_attempt.score and best.time_taken_sec < v_attempt.time_taken_sec);

  return jsonb_build_object(
    'attempt_id', v_attempt.id, 'exam_id', v_attempt.exam_id, 'exam_title', v_exam.title,
    'status', v_attempt.status, 'score', v_attempt.score, 'total_marks', v_attempt.total_marks,
    'percentage', v_attempt.percentage, 'is_passed', v_attempt.is_passed,
    'correct', v_attempt.correct_count, 'wrong', v_attempt.wrong_count, 'skipped', v_attempt.skipped_count,
    'time_taken_sec', v_attempt.time_taken_sec,
    'rank', case when v_attempt.attempt_no = 1 then v_rank end,
    'answers_revealed', v_reveal,
    'review', case when v_reveal then (
      select jsonb_agg(jsonb_build_object(
        'question_id', q.id, 'body', q.body, 'image_url', q.image_url,
        'explanation', q.explanation, 'explanation_image_url', q.explanation_image_url,
        'selected_option_id', aa.selected_option_id,
        'is_correct', aa.is_correct,
        'options', (select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body,
                                    'image_url', o.image_url, 'is_correct', o.is_correct) order by o.sort_order)
                      from public.question_options o where o.question_id = q.id)
      ) order by qo.ord)
      from unnest(v_attempt.question_order) with ordinality qo(qid, ord)
      join public.questions q on q.id = qo.qid
      left join public.attempt_answers aa on aa.attempt_id = v_attempt.id and aa.question_id = q.id
    ) end
  );
end $$;

-- 12.7 Leaderboard (প্রতি ইউজারের প্রথম attempt)
create or replace function public.get_exam_leaderboard(p_exam_id uuid, p_limit int default 50)
returns table (rank bigint, user_id uuid, full_name text, avatar_url text, score numeric, time_taken_sec int, is_me boolean)
language sql stable security definer set search_path = public as $$
  select dense_rank() over (order by a.score desc, a.time_taken_sec asc),
         a.user_id, p.full_name, p.avatar_url, a.score, a.time_taken_sec, a.user_id = auth.uid()
    from public.exam_attempts a
    join public.profiles p on p.id = a.user_id
   where a.exam_id = p_exam_id and a.attempt_no = 1 and a.status <> 'in_progress'
     and public.is_active_student()
   order by a.score desc, a.time_taken_sec asc
   limit least(coalesce(p_limit, 50), 200);
$$;

-- 12.8 Auto-expire: deadline পার হওয়া attempt গুলো grade করে দেয় (pg_cron প্রতি মিনিটে)
create or replace function public.expire_overdue_attempts()
returns int language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  for r in select id from public.exam_attempts
            where status = 'in_progress' and deadline_at + interval '10 seconds' < now() loop
    perform public.finalize_attempt(r.id, 'expired');
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.expire_overdue_attempts() from public, anon, authenticated;

select cron.schedule('expire-overdue-attempts', '* * * * *', $$select public.expire_overdue_attempts();$$);

-- ---------------------------------------------------------------------
-- 13. STUDENT DASHBOARD / PROGRESS RPCs
-- ---------------------------------------------------------------------
-- Streak: পরপর কত দিন পড়েছে/এক্সাম দিয়েছে (Asia/Dhaka টাইমজোন)
create or replace function public.get_my_streak()
returns int language sql stable security definer set search_path = public as $$
  with days as (
    select distinct (updated_at at time zone 'Asia/Dhaka')::date d from public.lesson_progress where user_id = auth.uid()
    union
    select distinct (started_at at time zone 'Asia/Dhaka')::date from public.exam_attempts where user_id = auth.uid()
  ), ordered as (
    select d, d - (row_number() over (order by d))::int as grp from days
  )
  select coalesce((
    select count(*)::int from ordered
     where grp = (select grp from ordered where d = (now() at time zone 'Asia/Dhaka')::date
                  or d = (now() at time zone 'Asia/Dhaka')::date - 1 order by d desc limit 1)
  ), 0);
$$;

create or replace function public.get_my_dashboard()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'lessons_completed', (select count(*) from public.lesson_progress where user_id = auth.uid() and is_completed),
    'watch_time_sec',    (select coalesce(sum(watched_sec), 0) from public.lesson_progress where user_id = auth.uid()),
    'exams_taken',       (select count(*) from public.exam_attempts where user_id = auth.uid() and status <> 'in_progress'),
    'avg_percentage',    (select round(avg(percentage), 1) from public.exam_attempts where user_id = auth.uid() and status <> 'in_progress'),
    'streak_days',       public.get_my_streak(),
    'continue_watching', (
      select coalesce(jsonb_agg(x), '[]'::jsonb) from (
        select lp.lesson_id, ls.title, ls.thumbnail_url, ls.video_duration_sec, lp.last_position_sec,
               c.title as chapter_title, s.name as subject_name, s.color_hex
          from public.lesson_progress lp
          join public.lessons  ls on ls.id = lp.lesson_id
          join public.chapters c  on c.id  = ls.chapter_id
          join public.subjects s  on s.id  = c.subject_id
         where lp.user_id = auth.uid() and not lp.is_completed and public.is_lesson_visible(ls.id)
         order by lp.updated_at desc limit 10) x),
    'upcoming_live_exams', (
      select coalesce(jsonb_agg(x), '[]'::jsonb) from (
        select e.id, e.title, e.starts_at, e.ends_at, e.duration_sec, s.name as subject_name
          from public.exams e join public.subjects s on s.id = e.subject_id
         where e.is_published and e.mode = 'live' and e.ends_at > now()
           and s.level_id = (select level_id from public.profiles where id = auth.uid())
         order by e.starts_at limit 5) x)
  );
$$;

-- Subject wise progress (% lessons completed)
create or replace function public.get_my_subject_progress(p_level_id uuid)
returns table (subject_id uuid, total_lessons bigint, completed_lessons bigint, percentage numeric)
language sql stable security definer set search_path = public as $$
  select s.id,
         count(ls.id),
         count(lp.lesson_id) filter (where lp.is_completed),
         round(100.0 * count(lp.lesson_id) filter (where lp.is_completed) / nullif(count(ls.id), 0), 1)
    from public.subjects s
    join public.chapters c on c.subject_id = s.id and c.is_published
    join public.lessons ls on ls.chapter_id = c.id and ls.is_published
    left join public.lesson_progress lp on lp.lesson_id = ls.id and lp.user_id = auth.uid()
   where s.level_id = p_level_id and s.is_published
   group by s.id;
$$;

-- Weak chapters (exam performance অনুযায়ী)
create or replace function public.get_my_weak_chapters(p_limit int default 5)
returns table (chapter_id uuid, chapter_title text, subject_name text, accuracy numeric, attempted bigint)
language sql stable security definer set search_path = public as $$
  select c.id, c.title, s.name,
         round(100.0 * count(*) filter (where aa.is_correct) / nullif(count(*), 0), 1) as accuracy,
         count(*)
    from public.attempt_answers aa
    join public.exam_attempts a on a.id = aa.attempt_id and a.user_id = auth.uid() and a.status <> 'in_progress'
    join public.questions q on q.id = aa.question_id
    join public.chapters c on c.id = q.chapter_id
    join public.subjects s on s.id = c.subject_id
   group by c.id, c.title, s.name
  having count(*) >= 5
   order by accuracy asc
   limit least(coalesce(p_limit, 5), 20);
$$;

-- Lesson progress upsert (client প্রতি ১০ সেকেন্ডে কল করে)
create or replace function public.update_lesson_progress(p_lesson_id uuid, p_position_sec int, p_delta_watched_sec int)
returns void language plpgsql volatile security definer set search_path = public as $$
declare v_duration int;
begin
  if not public.is_active_student() or not public.is_lesson_visible(p_lesson_id) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  select video_duration_sec into v_duration from public.lessons where id = p_lesson_id;

  insert into public.lesson_progress as lp (user_id, lesson_id, last_position_sec, watched_sec)
  values (auth.uid(), p_lesson_id, greatest(p_position_sec, 0), least(greatest(p_delta_watched_sec, 0), 60))
  on conflict (user_id, lesson_id) do update set
    last_position_sec = greatest(excluded.last_position_sec, 0),
    watched_sec       = lp.watched_sec + least(greatest(p_delta_watched_sec, 0), 60);  -- anti-abuse: max 60s per ping

  update public.lesson_progress
     set is_completed = true, completed_at = now()
   where user_id = auth.uid() and lesson_id = p_lesson_id and not is_completed
     and v_duration is not null and v_duration > 0 and watched_sec >= v_duration * 0.9;
end $$;

-- ---------------------------------------------------------------------
-- 14. ADMIN ANALYTICS RPCs
-- ---------------------------------------------------------------------
create or replace function public.admin_dashboard_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'NOT_AUTHORIZED' using errcode = '42501'; end if;
  return jsonb_build_object(
    'total_students',   (select count(*) from public.user_roles where role = 'student'),
    'new_students_7d',  (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'active_students_7d', (select count(distinct user_id) from public.lesson_progress where updated_at > now() - interval '7 days'),
    'total_lessons',    (select count(*) from public.lessons),
    'published_lessons',(select count(*) from public.lessons where is_published),
    'total_exams',      (select count(*) from public.exams),
    'total_questions',  (select count(*) from public.questions),
    'attempts_7d',      (select count(*) from public.exam_attempts where started_at > now() - interval '7 days'),
    'signups_by_day', (
      select coalesce(jsonb_agg(x order by x.day), '[]'::jsonb) from (
        select (created_at at time zone 'Asia/Dhaka')::date as day, count(*) as count
          from public.profiles where created_at > now() - interval '30 days' group by 1) x),
    'top_lessons', (
      select coalesce(jsonb_agg(x), '[]'::jsonb) from (
        select ls.id, ls.title, count(lp.user_id) as viewers
          from public.lessons ls join public.lesson_progress lp on lp.lesson_id = ls.id
         group by ls.id order by viewers desc limit 10) x)
  );
end $$;

create or replace function public.admin_exam_stats(p_exam_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'NOT_AUTHORIZED' using errcode = '42501'; end if;
  return jsonb_build_object(
    'attempts',       (select count(*) from public.exam_attempts where exam_id = p_exam_id and status <> 'in_progress'),
    'unique_students',(select count(distinct user_id) from public.exam_attempts where exam_id = p_exam_id),
    'avg_score',      (select round(avg(score), 2) from public.exam_attempts where exam_id = p_exam_id and status <> 'in_progress'),
    'pass_rate',      (select round(100.0 * avg(case when is_passed then 1 else 0 end), 1)
                         from public.exam_attempts where exam_id = p_exam_id and status <> 'in_progress'),
    'question_stats', (
      select coalesce(jsonb_agg(x), '[]'::jsonb) from (
        select q.id, left(q.body, 120) as body,
               count(aa.*) as answered,
               round(100.0 * count(*) filter (where aa.is_correct) / nullif(count(aa.*), 0), 1) as accuracy
          from public.exam_questions eq
          join public.questions q on q.id = eq.question_id
          left join public.attempt_answers aa on aa.question_id = q.id
               and aa.attempt_id in (select id from public.exam_attempts where exam_id = p_exam_id)
         where eq.exam_id = p_exam_id
         group by q.id order by accuracy asc nulls last) x)
  );
end $$;

-- ---------------------------------------------------------------------
-- 15. FUNCTION PERMISSIONS (least privilege)
-- ---------------------------------------------------------------------
-- Supabase ডিফল্টভাবে PUBLIC/anon কে execute দেয় — সেটা বন্ধ করে শুধু দরকারি গুলো authenticated কে দিচ্ছি
revoke execute on all functions in schema public from public, anon;
alter default privileges in schema public revoke execute on functions from public, anon;
grant execute on function public.start_exam(uuid)                  to authenticated;
grant execute on function public.save_answer(uuid, uuid, uuid)     to authenticated;
grant execute on function public.submit_exam(uuid)                 to authenticated;
grant execute on function public.get_attempt_result(uuid)          to authenticated;
grant execute on function public.get_exam_leaderboard(uuid, int)   to authenticated;
grant execute on function public.get_my_dashboard()                to authenticated;
grant execute on function public.get_my_streak()                   to authenticated;
grant execute on function public.get_my_subject_progress(uuid)     to authenticated;
grant execute on function public.get_my_weak_chapters(int)         to authenticated;
grant execute on function public.update_lesson_progress(uuid, int, int) to authenticated;
grant execute on function public.admin_dashboard_stats()           to authenticated;
grant execute on function public.admin_exam_stats(uuid)            to authenticated;
-- RLS policy গুলো এই helper গুলো invoker (authenticated) হিসেবে কল করে, তাই execute দরকার
grant execute on function public.is_admin()                        to authenticated;
grant execute on function public.is_super_admin()                  to authenticated;
grant execute on function public.current_role_name()               to authenticated;
grant execute on function public.is_active_student()               to authenticated;
grant execute on function public.has_premium_access()              to authenticated;
grant execute on function public.is_chapter_visible(uuid)          to authenticated;
grant execute on function public.is_lesson_visible(uuid)           to authenticated;

-- ---------------------------------------------------------------------
-- 15.1 ROLE PRIVILEGES (GRANTS) FOR SUPABASE PostgREST & AUTH
-- ---------------------------------------------------------------------
grant usage on schema public to postgres, anon, authenticated, service_role;

grant all on all tables in schema public to postgres, service_role;
grant all on all sequences in schema public to postgres, service_role, authenticated, anon;
grant all on all routines in schema public to postgres, service_role;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;

grant execute on all routines in schema public to anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to postgres, service_role;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant select on tables to anon;

alter default privileges in schema public grant all on sequences to postgres, service_role, authenticated, anon;
alter default privileges in schema public grant all on routines to postgres, service_role, authenticated, anon;

-- ---------------------------------------------------------------------
-- 16. STORAGE BUCKETS & POLICIES
-- ---------------------------------------------------------------------
-- public-assets : subject icon, thumbnail, question image, avatar (public read, UUID path)
-- materials     : private PDF (signed URL, 1 ঘণ্টা মেয়াদ)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('public-assets', 'public-assets', true,  5 * 1024 * 1024,   array['image/png','image/jpeg','image/webp','image/svg+xml']),
  ('materials',     'materials',     false, 100 * 1024 * 1024, array['application/pdf'])
on conflict (id) do nothing;

create policy "assets_public_read"  on storage.objects for select using (bucket_id = 'public-assets');
create policy "assets_admin_write"  on storage.objects for insert to authenticated
  with check (bucket_id = 'public-assets' and public.is_admin());
create policy "assets_admin_update" on storage.objects for update to authenticated
  using (bucket_id = 'public-assets' and public.is_admin());
create policy "assets_admin_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'public-assets' and public.is_admin());
-- student নিজের avatar: public-assets/avatars/<uid>/...
create policy "avatar_own_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'public-assets' and (storage.foldername(name))[1] = 'avatars'
              and (storage.foldername(name))[2] = auth.uid()::text);
create policy "avatar_own_update" on storage.objects for update to authenticated
  using (bucket_id = 'public-assets' and (storage.foldername(name))[1] = 'avatars'
         and (storage.foldername(name))[2] = auth.uid()::text);

create policy "materials_admin_all" on storage.objects for all to authenticated
  using (bucket_id = 'materials' and public.is_admin())
  with check (bucket_id = 'materials' and public.is_admin());
create policy "materials_student_read" on storage.objects for select to authenticated
  using (bucket_id = 'materials' and public.is_active_student()
         and exists (select 1 from public.materials m
                      where m.storage_path = storage.objects.name and m.is_published
                        and public.is_lesson_visible(m.lesson_id)));

-- ---------------------------------------------------------------------
-- 17. FIRST ADMIN (ONE-TIME, MANUAL) — এটা seed data নয়
-- ---------------------------------------------------------------------
-- ১) Admin প্যানেল বা Supabase Dashboard → Authentication → Add user দিয়ে নিজের অ্যাকাউন্ট খুলুন
-- ২) SQL Editor এ নিচের লাইনটি আপনার ইমেইল দিয়ে চালান (service role দিয়ে চলে, তাই RLS বাধা দেয় না):
--
--   update public.user_roles set role = 'super_admin'
--    where user_id = (select id from auth.users where email = 'YOUR_EMAIL@example.com');
--
-- ৩) Admin প্যানেলে logout → login করুন (নতুন JWT তে user_role আসবে)
-- =====================================================================
