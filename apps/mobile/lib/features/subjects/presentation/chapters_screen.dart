import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/subjects_repository.dart';

class ChaptersScreen extends ConsumerWidget {
  final String subjectId;
  final String? subjectName;

  const ChaptersScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersListProvider(subjectId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName ?? 'অধ্যায়সমূহ', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: chaptersAsync.when(
        loading: () => const ShimmerListPlaceholder(count: 5),
        error: (err, _) => EmptyStateWidget(
          title: 'অধ্যায় লোড করা যায়নি',
          description: err.toString(),
          actionLabel: 'আবার চেষ্টা করুন',
          onAction: () => ref.refresh(chaptersListProvider(subjectId)),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return EmptyStateWidget(
              icon: LucideIcons.list,
              title: 'কোনো অধ্যায় যোগ করা হয়নি',
              description: 'এই বিষয়ের আওতায় অ্যাডমিন এখনো কোনো অধ্যায় যোগ করেনি।',
              actionLabel: 'রিফ্রেশ করুন',
              onAction: () => ref.refresh(chaptersListProvider(subjectId)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    // Navigate to lessons of this chapter
                    context.push('/chapters/${chapter.id}/lessons', extra: chapter.name);
                  },
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary900 : AppColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      BengaliUtils.toBengaliNumerals(chapter.chapterNumber.toString().padLeft(2, '0')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primary300 : AppColors.primary600,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.playCircle, size: 14, color: AppColors.teal600),
                        const SizedBox(width: 4),
                        Text(
                          '${BengaliUtils.toBengaliNumerals(chapter.lessonCount)} টি ক্লাস',
                          style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                        ),
                        if (chapter.examCount > 0) ...[
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.helpCircle, size: 14, color: AppColors.amber600),
                          const SizedBox(width: 4),
                          Text(
                            '${BengaliUtils.toBengaliNumerals(chapter.examCount)} টি এক্সাম',
                            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, color: AppColors.neutral400, size: 20),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

