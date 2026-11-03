# ClassRoom — সম্পূর্ণ ডকুমেন্টেশন ও আর্কিটেকচার গাইড

> **ClassRoom** হলো বাংলাদেশের শিক্ষার্থীদের জন্য একটি আধুনিক, দ্রুত এবং সুরক্ষিত লার্নিং ও পরীক্ষা প্ল্যাটফর্ম।
> এই রিপোজিটরির `docs/` ফোল্ডারে সম্পূর্ণ সিস্টেমের প্রোডাক্ট রিকোয়ারমেন্ট, টেকনিক্যাল আর্কিটেকচার, ডেটাবেস স্কিমা, সিকিউরিটি রুলস, ডিজাইন সিস্টেম এবং কোড জেনারেশনের প্রম্পট অন্তর্ভুক্ত রয়েছে।

---

## ১. ডকুমেন্টেশন ইনডেক্স ও পড়ার ক্রম

সিস্টেমটি ভালোভাবে বুঝতে এবং ধাপে ধাপে কোড লিখতে নিচের ক্রমানুসারে ডকুমেন্টগুলো অনুসরণ করুন:

| ক্রম | ফাইল | বিবরণ ও মূল বিষয়বস্তু |
|:---:|---|---|
| **01** | [`01-PRD.md`](01-PRD.md) | **Product Requirements Document:** প্রোডাক্ট ভিশন, ইউজার পারসোনা, পূর্ণাঙ্গ ফিচার লিস্ট (P0/P1), ইউজার জার্নি এবং একসেপ্টেন্স ক্রাইটেরিয়া। |
| **02** | [`02-TRD.md`](02-TRD.md) | **Technical Requirements Document:** হাই-লেভেল সিস্টেম আর্কিটেকচার, টেক স্ট্যাক, ডেটা ফ্লো, API কন্ট্র্যাক্টস এবং ক্যাশিং স্ট্র্যাটেজি। |
| **03** | [`03-DATABASE.md`](03-DATABASE.md) | **Database Architecture:** সম্পূর্ণ ER ডায়াগ্রাম, টেবিল ডিকশনারি, কনস্ট্রেইন্টস, ইনডেক্স, আরপিসি (RPC) এবং স্টোরেজ বাকেট গাইড। |
| 🗄️ | [`sql/schema.sql`](sql/schema.sql) | **Production Database Script:** রান করার জন্য সম্পূর্ণ রেডি PostgreSQL স্কিমা (PGlite দিয়ে ২৭টি ইন্টিগ্রেশন টেস্টে শতভাগ ভেরিফাইড)। |
| **04** | [`04-SECURITY.md`](04-SECURITY.md) | **Security & Anti-Cheat:** Auth, JWT হুক, Row-Level Security (RLS), পরীক্ষার অ্যান্টি-চিট মেকানিজম, স্ক্রিনশট ব্লক (DRM) ও OWASP চেকলিস্ট। |
| **05** | [`05-DESIGN-SYSTEM.md`](05-DESIGN-SYSTEM.md) | **Design System & Wireframes:** রঙের টোকেন, টাইপোগ্রাফি (`Hind Siliguri`), স্পেসিং, কম্পোনেন্ট লাইব্রেরি এবং প্রতিটি স্ক্রিনের ASCII ওয়্যারফ্রেম। |
| **06** | [`06-FLUTTER-APP.md`](06-FLUTTER-APP.md) | **Flutter Student App Spec:** Feature-First আর্কিটেকচার, Riverpod, GoRouter, ইউনিফাইড ভিডিও প্লেয়ার, ড্রাইভ পিডিএফ রেন্ডারার ও এক্সাম স্টেট মেশিন। |
| **07** | [`07-ADMIN-PANEL.md`](07-ADMIN-PANEL.md) | **Next.js Admin Panel Spec:** Next.js 15 App Router, শ্যাডসিএন UI, কনটেন্ট CRUD, বাল্ক এক্সেল প্রশ্ন ইমপোর্ট, ড্রাইভ লিঙ্ক এক্সট্র্যাক্টর ও এক্সাম অ্যানালিটিক্স। |
| **08** | [`08-ROADMAP.md`](08-ROADMAP.md) | **Implementation Roadmap:** ফেজ ০ থেকে ৭ পর্যন্ত বিস্তারিত টাস্ক ব্রেকডাউন, টেস্টিং স্ট্র্যাটেজি এবং প্লে স্টোর/ভার্সেল লঞ্চ চেকলিস্ট। |
| **09** | [`09-AI-BUILD-PROMPTS.md`](09-AI-BUILD-PROMPTS.md) | **AI Build Prompts:** ধাপে ধাপে কপি-পেস্ট করে কোড বানানোর জন্য ১০টি স্বয়ংসম্পূর্ণ প্রোডাকশন প্রম্পট। |

---

## ২. মূল আর্কিটেকচার সারসংক্ষেপ

```mermaid
flowchart TB
  subgraph Frontend
    App["📱 Flutter Student App<br/>(Android & iOS)"]
    Admin["🖥️ Next.js 15 Admin Website<br/>(Vercel Hosted)"]
  end

  subgraph Supabase BaaS (Singapore)
    Auth["🔐 Supabase Auth<br/>(JWT + user_role claim)"]
    DB[("🐘 PostgreSQL 15+<br/>(RLS + RPC Exam Engine)")]
    Storage["📦 Storage Buckets<br/>(public-assets / materials)"]
    Edge["⚡ Edge Functions<br/>(bunny-signed-url, send-push)"]
    Cron["⏰ pg_cron<br/>(auto-expire overdue exams)"]
  end

  subgraph External Media
    YT["YouTube Unlisted<br/>(Embed Player)"]
    Bunny["Bunny Stream<br/>(Secure HLS)"]
    Drive["Google Drive<br/>(PDF Native Preview)"]
    FCM["Firebase Cloud Messaging<br/>(Push Notifications)"]
  end

  App --> Auth
  App --> DB
  App --> Storage
  App --> Edge
  Admin --> Auth
  Admin --> DB
  Admin --> Storage
  Admin --> Edge

  Edge --> Bunny
  Edge --> FCM
  App --> YT
  App --> Bunny
  App --> Drive
```

---

## ৩. কুইক স্টার্ট গাইড (Zero to Running)

### ধাপ ১: ডাটাবেস কার্যকর করা (Database Setup)
1. [Supabase](https://supabase.com)-এ একটি নতুন প্রজেক্ট তৈরি করুন (রিজিয়ন: `Southeast Asia (Singapore)` নির্বাচন করুন)।
2. Supabase ড্যাশবোর্ডের বাম মেনু থেকে **SQL Editor**-এ যান।
3. [`docs/sql/schema.sql`](sql/schema.sql) ফাইলের সমস্ত কোড কপি করে পেস্ট করুন এবং **Run** চাপুন।

### ধাপ ২: কাস্টম অ্যাক্সেস টোকেন হুক যুক্ত করা
1. Supabase Dashboard -> **Authentication** -> **Hooks**-এ যান।
2. **Custom Access Token (JWT)** সেকশনে হুক হিসেবে `public.custom_access_token_hook` নির্বাচন করে সংরক্ষণ করুন।

### ধাপ ৩: প্রথম সুপার অ্যাডমিন তৈরি (One-Time Bootstrap)
1. Supabase Auth অথবা তৈরি করা অ্যাডমিন প্যানেল থেকে সাধারণ ইমেইল/পাসওয়ার্ড দিয়ে একটি অ্যাকাউন্ট সাইনআপ করুন।
2. SQL Editor-এ নিচের কুয়েরিটি আপনার ইমেইল দিয়ে রান করুন:
   ```sql
   update public.user_roles set role = 'super_admin'
   where user_id = (select id from auth.users where email = 'your-email@example.com');
   ```
3. এবার লগআউট করে পুনরায় লগইন করলে আপনার অ্যাকাউন্টে সুপার অ্যাডমিন প্রিভিলেজ সক্রিয় হয়ে যাবে।

---

## ৪. ⚠️ "NO DEMO DATA" পলিসি

এই পুরো প্ল্যাটফর্মে কোনো হার্ডকোডেড বা ডামি কনটেন্ট নেই:
- সমস্ত বিষয়, অধ্যায়, ক্লাস, শিট ও পরীক্ষা অ্যাডমিন ওয়েবসাইট থেকে ইনপুট হবে।
- কনটেন্ট না থাকলে ক্লায়েন্ট স্ক্রিনে কোনো ফাঁকা বা ভাঙা লেআউট আসবে না; প্রতিটি স্ক্রিনে বাংলায় পরিষ্কার তথ্যসমৃদ্ধ **Empty State Widget** প্রদর্শিত হবে।
- টেস্ট ও মক ডেটা শুধুমাত্র `test/` ফোল্ডারের ভেতরে সীমাবদ্ধ থাকবে, যা প্রোডাকশন ডেটাবেসে কখনোই প্রবেশ করবে না।

---

## ৫. পরবর্তী পদক্ষেপ

কোড তৈরি শুরু করতে [`docs/08-ROADMAP.md`](08-ROADMAP.md)-এর ফেজভিত্তিক টাস্কগুলো দেখুন এবং [`docs/09-AI-BUILD-PROMPTS.md`](09-AI-BUILD-PROMPTS.md)-এর প্রম্পটগুলো ব্যবহার করে দ্রুত মডিউলগুলো বিল্ড করুন!

