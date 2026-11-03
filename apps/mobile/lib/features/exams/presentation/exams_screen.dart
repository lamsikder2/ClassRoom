import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../../../shared/components/status_badge.dart';
import '../data/exams_repository.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Live, 2: Practice

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('পরীক্ষাসমূহ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(0, 'সব পরীক্ষা'),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'লাইভ এক্সাম'),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'অনুশীলন'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),

          // Exam List
          Expanded(
            child: examsAsync.when(
              loading: () => const ShimmerListPlaceholder(count: 4),
              error: (err, _) => EmptyStateWidget(
                title: 'পরীক্ষা লোড করা যায়নি',
                description: err.toString(),
                actionLabel: 'আবার চেষ্টা করুন',
                onAction: () => ref.refresh(examsListProvider),
              ),
              data: (exams) {
                final filtered = exams.where((e) {
                  if (_selectedFilterIndex == 1) return e.examType == 'live';
                  if (_selectedFilterIndex == 2) return e.examType == 'practice' || e.examType == 'quiz';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: LucideIcons.fileCheck,
                    title: 'কোনো পরীক্ষা পাওয়া যায়নি',
                    description: _selectedFilterIndex == 1
                        ? 'বর্তমানে কোনো লাইভ পরীক্ষা চলমান নেই।'
                        : 'অ্যাডমিন প্যানেল থেকে এখনো কোনো পরীক্ষা যুক্ত করা হয়নি।',
                    actionLabel: 'রিফ্রেশ করুন',
                    onAction: () => ref.refresh(examsListProvider),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final exam = filtered[index];
                    final isLive = exam.examType == 'live';

                    return Material(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          context.push('/exams/${exam.id}/intro', extra: exam.title);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isLive
                                  ? AppColors.live.withOpacity(0.5)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.neutral800
                                      : AppColors.neutral200),
                              width: isLive ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isLive)
                                    StatusBadge.live()
                                  else
                                    StatusBadge.practice(),
                                  const SizedBox(width: 8),
                                  if (exam.subjectName != null)
                                    StatusBadge.tag(exam.subjectName!),
                                  const Spacer(),
                                  if (exam.negativeMarkingRate > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${BengaliUtils.toBengaliNumerals(exam.negativeMarkingRate)} নেগেটিভ',
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                exam.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (exam.chapterName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'অধ্যায়: ${exam.chapterName}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(LucideIcons.clock, size: 14, color: AppColors.neutral500),
                                  const SizedBox(width: 4),
                                  Text(
                                    BengaliUtils.formatDurationWords(exam.durationMinutes),
                                    style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(LucideIcons.award, size: 14, color: AppColors.neutral500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${BengaliUtils.toBengaliNumerals(exam.totalMarks.toInt())} নম্বর',
                                    style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.push('/exams/${exam.id}/intro', extra: exam.title);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLive ? AppColors.live : AppColors.primary600,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('অংশ নিন', style: TextStyle(fontSize: 13, color: Colors.white)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterIndex = index);
      },
      selectedColor: AppColors.primary600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? AppColors.neutral300 : AppColors.neutral700),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral100,
      side: BorderSide(
        color: isSelected ? Colors.transparent : (isDark ? AppColors.neutral800 : AppColors.neutral200),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

