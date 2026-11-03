import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/exams/data/exams_repository.dart';
import '../../features/exams/presentation/exam_intro_screen.dart';
import '../../features/exams/presentation/exam_result_screen.dart';
import '../../features/exams/presentation/exam_taking_screen.dart';
import '../../features/exams/presentation/exams_screen.dart';
import '../../features/lessons/data/lessons_repository.dart';
import '../../features/lessons/presentation/lesson_detail_screen.dart';
import '../../features/lessons/presentation/lessons_screen.dart';
import '../../features/materials/presentation/class_note_screen.dart';
import '../../features/materials/presentation/pdf_viewer_screen.dart';
import '../../features/profile/presentation/downloads_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subjects/presentation/chapters_screen.dart';
import '../../features/subjects/presentation/subjects_screen.dart';
import '../network/supabase_client.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate router when auth state changes
  ref.watch(currentSessionProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),

      // Nested Subject routes
      GoRoute(
        path: '/subjects/:id/chapters',
        builder: (context, state) {
          final subjectId = state.pathParameters['id']!;
          final subjectName = state.extra as String?;
          return ChaptersScreen(subjectId: subjectId, subjectName: subjectName);
        },
      ),
      GoRoute(
        path: '/chapters/:id/lessons',
        builder: (context, state) {
          final chapterId = state.pathParameters['id']!;
          final chapterName = state.extra as String?;
          return LessonsScreen(chapterId: chapterId, chapterName: chapterName);
        },
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (context, state) {
          final lessonId = state.pathParameters['id']!;
          return LessonDetailScreen(lessonId: lessonId);
        },
      ),

      // Materials routes
      GoRoute(
        path: '/materials/pdf/:id',
        builder: (context, state) {
          final materialId = state.pathParameters['id']!;
          final material = state.extra as LessonMaterialItem?;
          return PdfViewerScreen(materialId: materialId, initialMaterial: material);
        },
      ),
      GoRoute(
        path: '/materials/note/:id',
        builder: (context, state) {
          final materialId = state.pathParameters['id']!;
          final material = state.extra as LessonMaterialItem?;
          return ClassNoteScreen(materialId: materialId, initialMaterial: material);
        },
      ),

      // Exam taking & Result routes
      GoRoute(
        path: '/exams/:id/intro',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          final examTitle = state.extra as String?;
          return ExamIntroScreen(examId: examId, initialTitle: examTitle);
        },
      ),
      GoRoute(
        path: '/exams/:id/taking',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          final startData = state.extra as ExamStartResponse;
          return ExamTakingScreen(examId: examId, startData: startData);
        },
      ),
      GoRoute(
        path: '/exams/result/:attemptId',
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId']!;
          final result = state.extra as ExamSubmitResult;
          return ExamResultScreen(attemptId: attemptId, result: result);
        },
      ),

      // Bottom Navigation Stateful Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subjects',
                builder: (context, state) => const SubjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exams',
                builder: (context, state) => const ExamsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithBottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppColors.primary600,
          unselectedItemColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 22),
              activeIcon: Icon(LucideIcons.home, size: 22),
              label: 'ড্যাশবোর্ড',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookOpen, size: 22),
              activeIcon: Icon(LucideIcons.bookOpen, size: 22),
              label: 'বিষয়সমূহ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.fileCheck, size: 22),
              activeIcon: Icon(LucideIcons.fileCheck, size: 22),
              label: 'পরীক্ষা',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user, size: 22),
              activeIcon: Icon(LucideIcons.user, size: 22),
              label: 'প্রোফাইল',
            ),
          ],
        ),
      ),
    );
  }
}
