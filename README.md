# ClassRoom 🎓

A modern, production-grade EdTech platform designed for online learning, examinations, and academic management.

## 🚀 Architecture Overview

- **Mobile Application (`apps/mobile/`)**: Cross-platform Flutter application (Android & Web) for students featuring:
  - Video lessons with YouTube player integration
  - Interactive MCQ Exams (Live & Practice modes) with instant auto-grading
  - Mathematical equations rendering via KaTeX / LaTeX (`$E = mc^2$`)
  - Lecture sheets, class notes & PDF viewer
  - Screen protection (`FLAG_SECURE`) against cheating and recording
  - Offline-first caching and Riverpod state management

- **Admin Management Portal (`apps/admin/`)**: Next.js (App Router, React 19, Tailwind CSS) dashboard for administrators featuring:
  - Responsive mobile drawer navigation (usable on mobile and desktop)
  - Levels, Subjects & Chapters management
  - Question Bank with Excel bulk-import and LaTeX math support
  - Live & Practice Exam creator
  - Student & User access control (block/unblock, role assignments)
  - Notice & Announcements carousel manager
  - Comprehensive Audit logs

- **Backend & Database (`supabase/`)**: Supabase Cloud (PostgreSQL 15) with:
  - Strict Row Level Security (RLS) policies
  - Stored Procedures and RPC functions (`start_exam`, `submit_exam`, `admin_dashboard_stats`)
  - Storage buckets for questions, PDFs, and assets

## 🛠️ Getting Started

### Admin Panel
```bash
cd apps/admin
npm install
npm run dev # Runs on http://localhost:3000
```

### Mobile App (Flutter)
```bash
cd apps/mobile
flutter pub get
flutter run -d chrome # Web
# or
flutter build apk --release # Android APK
```

## 📄 License
Private & Proprietary - ClassRoom.
# ClassRoom
