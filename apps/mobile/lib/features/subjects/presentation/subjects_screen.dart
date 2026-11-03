import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../../auth/data/auth_repository.dart';
import '../data/subjects_repository.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  Color _parseHexColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিষয়সমূহ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => profile?.levelName != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary900 : AppColors.primary50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.primary700 : AppColors.primary200,
                          ),
                        ),
                        child: Text(
                          profile!.levelName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primary300 : AppColors.primary600,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const ShimmerListPlaceholder(count: 6),
        error: (err, _) => EmptyStateWidget(
          title: 'বিষয় লোড করা যায়নি',
          description: err.toString(),
          actionLabel: 'আবার চেষ্টা করুন',
          onAction: () => ref.refresh(subjectsListProvider),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyStateWidget(
              icon: LucideIcons.bookOpen,
              title: 'কোনো বিষয় পাওয়া যায়নি',
              description: 'অ্যাডমিন প্যানেল থেকে এখনো এই শ্রেণীর জন্য কোনো বিষয় যুক্ত করা হয়নি।',
              actionLabel: 'রিফ্রেশ করুন',
              onAction: () => ref.refresh(subjectsListProvider),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectColor = _parseHexColor(subject.color, AppColors.primary600);

              return Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    context.push('/subjects/${subject.id}/chapters', extra: subject.name);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.book,
                            color: subjectColor,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          subject.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.folder, size: 14, color: AppColors.neutral500),
                            const SizedBox(width: 4),
                            Text(
                              '${BengaliUtils.toBengaliNumerals(subject.chapterCount)} টি অধ্যায়',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

