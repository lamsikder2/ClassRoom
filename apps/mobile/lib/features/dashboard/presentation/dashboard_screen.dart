import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../../auth/data/auth_repository.dart';
import '../../exams/data/exams_repository.dart';
import '../../notifications/presentation/notifications_sheet.dart';
import '../../subjects/data/subjects_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _parseHexColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return fallback;
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'শুভ সকাল';
    if (hour >= 12 && hour < 17) return 'শুভ দুপুর';
    if (hour >= 17 && hour < 20) return 'শুভ বিকেল';
    return 'শুভ রাত্রি';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);
    final examsAsync = ref.watch(examsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral950 : AppColors.neutral50,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary600,
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(subjectsListProvider);
            ref.invalidate(examsListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER & APP BRANDING BAR
                Row(
                  children: [
                    // Brand Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary600.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Title & Tagline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ClassRoom',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppColors.primary900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary600.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'শিক্ষার্থীদের ডিজিটাল পাঠশালা',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Theme Switcher Button (☀️ / 🌙)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral900 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: isDark ? 'লাইট মোড' : 'ডার্ক মোড',
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        icon: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 19,
                          color: isDark ? AppColors.amber500 : AppColors.neutral700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification Button (🔔)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral900 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'নোটিফিকেশন ও ঘোষণা',
                        onPressed: () => NotificationsSheet.show(context),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              LucideIcons.bell,
                              size: 19,
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Profile / Logout Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral900 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'লগআউট / একাউন্ট পরিবর্তন',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('লগআউট করতে চান?'),
                              content: const Text('আপনি কি নিশ্চিত যে আপনার একাউন্ট থেকে লগআউট করে লগইন পেজে যেতে চান?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('না'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('লগআউট', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                        icon: Icon(
                          LucideIcons.logOut,
                          size: 18,
                          color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. HERO GREETING & STUDY PROGRESS CARD
                profileAsync.maybeWhen(
                  data: (profile) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              ),
                              child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getTimeGreeting()},',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    profile?.fullName ?? 'প্রিয় শিক্ষার্থী',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (profile?.levelName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  profile!.levelName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.target, size: 18, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'আজকের লক্ষ্য: ১টি অধ্যায় রিভিশন ও ১টি মডেল টেস্ট',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '৮০% সম্পন্ন',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  orElse: () => const ShimmerSkeleton(width: double.infinity, height: 130),
                ),
                const SizedBox(height: 20),

                // 3. WEEKLY STREAK & STUDY HABIT TRACKER
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: AppColors.streakGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange500.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.flame, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'পড়াশোনার স্ট্রিক',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange500.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '৩ দিন 🔥',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.orange500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'প্রতিদিন ক্লাসে অংশ নিয়ে স্ট্রিক ধরে রাখো',
                                  style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 7 Day tracker dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDayDot('শনি', isCompleted: true, isDark: isDark),
                          _buildDayDot('রবি', isCompleted: true, isDark: isDark),
                          _buildDayDot('সোম', isCompleted: true, isDark: isDark),
                          _buildDayDot('মঙ্গল', isToday: true, isDark: isDark),
                          _buildDayDot('বুধ', isDark: isDark),
                          _buildDayDot('বৃহঃ', isDark: isDark),
                          _buildDayDot('শুক্র', isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. QUICK SHORTCUT ACCESS TILES
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context: context,
                        icon: LucideIcons.bookOpen,
                        title: 'বিষয়সমূহ',
                        subtitle: 'সব অধ্যায় ও ক্লাস',
                        color: AppColors.primary600,
                        bgColor: AppColors.primary50,
                        onTap: () => context.go('/subjects'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        context: context,
                        icon: LucideIcons.timer,
                        title: 'পরীক্ষাসমূহ',
                        subtitle: 'মডেল ও লাইভ এক্সাম',
                        color: AppColors.live,
                        bgColor: AppColors.liveContainer,
                        onTap: () => context.go('/exams'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 5. SUBJECTS SECTION HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'তোমার বিষয়সমূহ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        ),
                        Text(
                          'অধ্যায়ভিত্তিক লেকচার ও রিভিশন শিট',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.neutral400 : AppColors.neutral500),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/subjects'),
                      icon: const Text('সবগুলো দেখো', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      label: const Icon(LucideIcons.chevronRight, size: 16),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary600,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Horizontal Subjects Carousel
                subjectsAsync.when(
                  loading: () => const SizedBox(
                    height: 140,
                    child: ShimmerListPlaceholder(count: 3),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral900 : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('বিষয় লোড সমস্যা: $err', style: const TextStyle(fontSize: 13)),
                  ),
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'কোনো বিষয় পাওয়া যায়নি। অ্যাডমিন থেকে বিষয় যোগ করুন।',
                            style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final color = _parseHexColor(subject.color, AppColors.primary600);

                          return InkWell(
                            onTap: () {
                              context.push('/subjects/${subject.id}/chapters', extra: subject.name);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 164,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(LucideIcons.bookOpen, size: 22, color: color),
                                      ),
                                      const Icon(LucideIcons.arrowUpRight, size: 18, color: AppColors.neutral400),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    subject.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${BengaliUtils.toBengaliNumerals(subject.chapterCount)} টি অধ্যায়',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // 6. EXAMS SECTION HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'পরীক্ষাসমূহ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        ),
                        Text(
                          'লাইভ মডেল টেস্ট ও অনুশীলন',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.neutral400 : AppColors.neutral500),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/exams'),
                      icon: const Text('সবগুলো দেখো', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      label: const Icon(LucideIcons.chevronRight, size: 16),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary600,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                examsAsync.when(
                  loading: () => const ShimmerListPlaceholder(count: 2),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (exams) {
                    if (exams.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'বর্তমানে কোনো পরীক্ষা নেই। নতুন পরীক্ষা যুক্ত হলে এখানে দেখতে পাবে।',
                            style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                          ),
                        ),
                      );
                    }

                    final recentExams = exams.take(3).toList();
                    return Column(
                      children: [
                        for (final exam in recentExams) ...[
                          _buildDashboardExamCard(context, exam, isDark),
                          const SizedBox(height: 14),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayDot(String label, {bool isCompleted = false, bool isToday = false, required bool isDark}) {
    Color circleColor;
    Widget icon;

    if (isCompleted) {
      circleColor = AppColors.teal600;
      icon = const Icon(LucideIcons.check, size: 14, color: Colors.white);
    } else if (isToday) {
      circleColor = AppColors.primary600;
      icon = const Icon(LucideIcons.flame, size: 14, color: Colors.white);
    } else {
      circleColor = isDark ? AppColors.neutral800 : AppColors.neutral200;
      icon = Text(
        '•',
        style: TextStyle(color: isDark ? AppColors.neutral600 : AppColors.neutral400, fontSize: 16),
      );
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isToday || isCompleted
                ? [
                    BoxShadow(
                      color: circleColor.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday
                ? AppColors.primary600
                : (isDark ? AppColors.neutral400 : AppColors.neutral500),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardExamCard(BuildContext context, ExamListItem exam, bool isDark) {
    final isLive = exam.examType == 'live';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? AppColors.live.withOpacity(0.5) : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? AppColors.live.withOpacity(0.12)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLive ? AppColors.liveContainer : (isDark ? AppColors.primary900 : AppColors.primary50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLive ? LucideIcons.radio : LucideIcons.fileCheck,
                  color: isLive ? AppColors.live : AppColors.primary600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLive ? AppColors.live.withOpacity(0.12) : AppColors.teal50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLive) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.live,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                isLive ? 'লাইভ পরীক্ষা' : 'অনুশীলন',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLive ? AppColors.live : AppColors.teal600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (exam.chapterName != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${exam.chapterName!}',
                            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: AppColors.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    BengaliUtils.formatDurationWords(exam.durationMinutes),
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.award, size: 14, color: AppColors.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    '${BengaliUtils.toBengaliNumerals(exam.totalMarks.toInt())} নম্বর',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/exams/${exam.id}/intro', extra: exam.title);
                },
                icon: const Text('অংশ নিন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                label: const Icon(LucideIcons.arrowRight, size: 15),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? AppColors.live : AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
