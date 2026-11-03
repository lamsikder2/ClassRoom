import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../core/utils/error_translator.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/exams_repository.dart';

class ExamIntroScreen extends ConsumerStatefulWidget {
  final String examId;
  final String? initialTitle;

  const ExamIntroScreen({
    super.key,
    required this.examId,
    this.initialTitle,
  });

  @override
  ConsumerState<ExamIntroScreen> createState() => _ExamIntroScreenState();
}

class _ExamIntroScreenState extends ConsumerState<ExamIntroScreen> {
  bool _isStarting = false;
  String? _errorMessage;

  Future<void> _startExam() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(examsRepositoryProvider);
      final startData = await repo.startExam(widget.examId);

      if (!mounted) return;
      context.pushReplacement('/exams/${widget.examId}/taking', extra: startData);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorTranslator.translate(e);
      });
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(examDetailProvider(widget.examId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle ?? 'পরীক্ষার নির্দেশিকা'),
      ),
      body: examAsync.when(
        loading: () => const ShimmerListPlaceholder(count: 3),
        error: (err, _) => EmptyStateWidget(
          title: 'পরীক্ষা লোড করা যায়নি',
          description: err.toString(),
          actionLabel: 'আবার চেষ্টা করুন',
          onAction: () => ref.refresh(examDetailProvider(widget.examId)),
        ),
        data: (exam) {
          if (exam == null) {
            return const EmptyStateWidget(
              title: 'পরীক্ষা পাওয়া যায়নি',
              description: 'অনুরোধকৃত পরীক্ষাটি খুঁজে পাওয়া যায়নি বা মুছে ফেলা হয়েছে।',
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary100),
                    ),
                    child: Column(
                      children: [
                        Text(
                          exam.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary900,
                          ),
                        ),
                        if (exam.chapterName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'অধ্যায়: ${exam.chapterName}',
                            style: const TextStyle(fontSize: 14, color: AppColors.primary700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          icon: LucideIcons.clock,
                          label: 'সময়সীমা',
                          value: BengaliUtils.formatDurationWords(exam.durationMinutes),
                          color: AppColors.teal600,
                          bgColor: AppColors.teal50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBox(
                          icon: LucideIcons.award,
                          label: 'পূর্ণমান',
                          value: '${BengaliUtils.toBengaliNumerals(exam.totalMarks.toInt())} নম্বর',
                          color: AppColors.primary600,
                          bgColor: AppColors.primary50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          icon: LucideIcons.alertTriangle,
                          label: 'নেগেটিভ মার্কিং',
                          value: exam.negativeMarkingRate > 0
                              ? '${BengaliUtils.toBengaliNumerals(exam.negativeMarkingRate)} নম্বর'
                              : 'নেই',
                          color: exam.negativeMarkingRate > 0 ? AppColors.error : AppColors.success,
                          bgColor: exam.negativeMarkingRate > 0 ? AppColors.errorContainer : AppColors.successContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBox(
                          icon: LucideIcons.checkCircle,
                          label: 'পরীক্ষার ধরন',
                          value: exam.examType == 'live' ? 'লাইভ পরীক্ষা' : 'অনুশীলন',
                          color: exam.examType == 'live' ? AppColors.live : AppColors.teal600,
                          bgColor: exam.examType == 'live' ? AppColors.liveContainer : AppColors.teal50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Rules card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'পরীক্ষার্থীর জন্য জরুরি নিয়মাবলী:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem('১.', 'একবার পরীক্ষা শুরু হলে টাইমার কোনোভাবেই থামানো যাবে না।'),
                        _buildRuleItem('২.', 'প্রতিটি অপশন ট্যাপ করার সাথে সাথে উত্তর স্বয়ংক্রিয়ভাবে সেভ হবে।'),
                        if (exam.negativeMarkingRate > 0)
                          _buildRuleItem('৩.', 'ভুল উত্তরের ক্ষেত্রে প্রতিটি ভুলের জন্য নির্ধারিত নম্বর কাটা যাবে।')
                        else
                          _buildRuleItem('৩.', 'এই পরীক্ষায় কোনো নেগেটিভ মার্কিং প্রযোজ্য নয়।'),
                        _buildRuleItem('৪.', 'পরীক্ষা চলাকালে অ্যাপ মিনিমাইজ বা ব্যাকগ্রাউন্ডে নেওয়া নিষিদ্ধ।'),
                        _buildRuleItem('৫.', 'সময় শেষ হওয়া মাত্র স্বয়ংক্রিয়ভাবে খাতা জমা হয়ে যাবে।'),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'আমি প্রস্তুত, পরীক্ষা শুরু করো',
                    isLoading: _isStarting,
                    onPressed: _startExam,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bullet, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary600)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.neutral700))),
        ],
      ),
    );
  }
}

