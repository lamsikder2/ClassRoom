import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/math_text_widget.dart';
import '../data/exams_repository.dart';

class ExamResultScreen extends StatelessWidget {
  final String attemptId;
  final ExamSubmitResult result;

  const ExamResultScreen({
    super.key,
    required this.attemptId,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = result.passed;

    return WillPopScope(
      onWillPop: () async {
        context.go('/exams');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('পরীক্ষার ফলাফল', style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isPassed ? AppColors.brandGradient : null,
                    color: isPassed ? null : AppColors.neutral800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassed ? LucideIcons.award : LucideIcons.refreshCw,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPassed ? 'অভিনন্দন! তুমি উত্তীর্ণ হয়েছো 🎉' : 'আরও একটু অনুশীলনের প্রয়োজন!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            BengaliUtils.toBengaliNumerals(result.totalScore.toStringAsFixed(1)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${BengaliUtils.toBengaliNumerals(result.totalMarks.toInt())}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'প্রাপ্ত নম্বর: ${BengaliUtils.toBengaliNumerals(result.percentage.toStringAsFixed(1))}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rank banner if rank exists
                if (result.rank != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.amber100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amber500),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trophy, color: AppColors.amber600, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('লাইভ লিডারবোর্ড স্থান', style: TextStyle(fontSize: 12, color: AppColors.neutral700)),
                              Text(
                                '${BengaliUtils.toBengaliNumerals(result.rank)} তম স্থান',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.amber600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4-cell Breakdown Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCell(
                        context,
                        label: 'সঠিক উত্তর',
                        count: result.correctCount,
                        color: AppColors.success,
                        bgColor: AppColors.successContainer,
                        icon: LucideIcons.checkCircle2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCell(
                        context,
                        label: 'ভুল উত্তর',
                        count: result.incorrectCount,
                        color: AppColors.error,
                        bgColor: AppColors.errorContainer,
                        icon: LucideIcons.xCircle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCell(
                        context,
                        label: 'অনুত্তরিত',
                        count: result.skippedCount,
                        color: AppColors.neutral500,
                        bgColor: AppColors.neutral100,
                        icon: LucideIcons.helpCircle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCell(
                        context,
                        label: 'নেগেটিভ কাটা',
                        count: null,
                        customValue: '-${BengaliUtils.toBengaliNumerals(result.negativeDeduction.toStringAsFixed(2))}',
                        color: AppColors.warning,
                        bgColor: AppColors.warningContainer,
                        icon: LucideIcons.minusCircle,
                      ),
                    ),
                  ],
                ),

                // Review Section (if answers are revealed)
                if (result.review != null && result.review!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(LucideIcons.fileCheck, size: 20, color: AppColors.primary600),
                      const SizedBox(width: 8),
                      const Text(
                        'প্রশ্নোত্তর ও সমাধান পর্যালোচনা',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${BengaliUtils.toBengaliNumerals(result.review!.length)} টি প্রশ্ন',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...result.review!.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return _buildReviewCard(context, idx, item);
                  }),
                ],

                const SizedBox(height: 32),

                // Buttons
                CustomButton(
                  text: 'হোম ড্যাশবোর্ডে ফিরে যাও',
                  onPressed: () => context.go('/dashboard'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/exams'),
                  icon: const Icon(LucideIcons.list, size: 18),
                  label: const Text('অন্যান্য পরীক্ষা দেখুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(
    BuildContext context, {
    required String label,
    int? count,
    String? customValue,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
          const SizedBox(height: 2),
          Text(
            customValue ?? BengaliUtils.toBengaliNumerals(count ?? 0),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, int index, ExamReviewItem item) {
    const letters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
    final isCorrect = item.isCorrect == true;
    final isSkipped = item.selectedOptionId == null;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (isSkipped) {
      badgeBg = AppColors.neutral100;
      badgeText = AppColors.neutral600;
      badgeLabel = 'অনুত্তরিত';
      badgeIcon = LucideIcons.helpCircle;
    } else if (isCorrect) {
      badgeBg = AppColors.successContainer;
      badgeText = AppColors.success;
      badgeLabel = 'সঠিক';
      badgeIcon = LucideIcons.checkCircle2;
    } else {
      badgeBg = AppColors.errorContainer;
      badgeText = AppColors.error;
      badgeLabel = 'ভুল';
      badgeIcon = LucideIcons.xCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withOpacity(0.3)
              : isSkipped
                  ? AppColors.neutral200
                  : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with question number and status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'প্রশ্ন ${BengaliUtils.toBengaliNumerals(index + 1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Body
          MathTextWidget(
            text: item.body,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),

          // Question Image
          if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!.trim(),
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  height: 120,
                  color: AppColors.neutral100,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Review Options
          ...item.options.asMap().entries.map((optEntry) {
            final optIdx = optEntry.key;
            final opt = optEntry.value;
            final isAnswerChosen = item.selectedOptionId == opt.id;
            final isThisCorrect = opt.isCorrect;

            final letter = optIdx < letters.length ? letters[optIdx] : '${optIdx + 1}';

            Color borderCol = AppColors.neutral200;
            Color bgCol = Theme.of(context).cardColor;

            if (isThisCorrect) {
              borderCol = AppColors.success;
              bgCol = AppColors.successContainer.withOpacity(0.4);
            } else if (isAnswerChosen && !isThisCorrect) {
              borderCol = AppColors.error;
              bgCol = AppColors.errorContainer.withOpacity(0.4);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgCol,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol, width: (isThisCorrect || isAnswerChosen) ? 1.5 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isThisCorrect
                          ? AppColors.success
                          : (isAnswerChosen ? AppColors.error : AppColors.neutral100),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: (isThisCorrect || isAnswerChosen) ? Colors.white : AppColors.neutral700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (opt.body.trim().isNotEmpty)
                          MathTextWidget(
                            text: opt.body,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: (isThisCorrect || isAnswerChosen) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        if (opt.imageUrl != null && opt.imageUrl!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: CachedNetworkImage(
                                imageUrl: opt.imageUrl!.trim(),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isThisCorrect)
                    const Icon(LucideIcons.check, size: 18, color: AppColors.success)
                  else if (isAnswerChosen)
                    const Icon(LucideIcons.x, size: 18, color: AppColors.error),
                ],
              ),
            );
          }),

          // Explanation / Solution Box
          if ((item.explanation != null && item.explanation!.trim().isNotEmpty) ||
              (item.explanationImageUrl != null && item.explanationImageUrl!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.lightbulb, size: 16, color: AppColors.amber600),
                      SizedBox(width: 6),
                      Text(
                        'সমাধান / ব্যাখ্যা',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amber700,
                        ),
                      ),
                    ],
                  ),
                  if (item.explanation != null && item.explanation!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    MathTextWidget(
                      text: item.explanation!,
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral800, height: 1.4),
                    ),
                  ],
                  if (item.explanationImageUrl != null && item.explanationImageUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.explanationImageUrl!.trim(),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

