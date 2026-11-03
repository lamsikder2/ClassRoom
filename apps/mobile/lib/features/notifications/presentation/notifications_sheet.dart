import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/notifications_repository.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'এইমাত্র';
    if (diff.inMinutes < 60) return '${BengaliUtils.toBengaliNumerals(diff.inMinutes)} মিনিট আগে';
    if (diff.inHours < 24) return '${BengaliUtils.toBengaliNumerals(diff.inHours)} ঘন্টা আগে';
    if (diff.inDays < 7) return '${BengaliUtils.toBengaliNumerals(diff.inDays)} দিন আগে';
    return '${BengaliUtils.toBengaliNumerals(dt.day)}/${BengaliUtils.toBengaliNumerals(dt.month)}/${BengaliUtils.toBengaliNumerals(dt.year)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primary900 : AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.bell, size: 18, color: AppColors.primary600),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'নোটিফিকেশন ও ঘোষণা',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.neutral800 : AppColors.neutral200),

          // Body List
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: ShimmerListPlaceholder(count: 3),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('লোড করতে সমস্যা: $err'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.bellOff,
                              size: 28,
                              color: AppColors.neutral400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'কোনো নতুন নোটিফিকেশন নেই',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'নতুন কোনো ক্লাস, লাইভ পরীক্ষা বা ঘোষণা আসলে এখানে দেখতে পাবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral900 : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.isAnnouncement
                                  ? AppColors.amber100
                                  : (isDark ? AppColors.primary900 : AppColors.primary100),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.isAnnouncement ? LucideIcons.megaphone : LucideIcons.bell,
                              size: 18,
                              color: item.isAnnouncement ? AppColors.amber600 : AppColors.primary600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.neutral600,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

