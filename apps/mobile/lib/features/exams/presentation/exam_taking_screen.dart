import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/security/screen_protection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../core/utils/error_translator.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/math_text_widget.dart';
import '../data/exams_repository.dart';

class ExamTakingScreen extends ConsumerStatefulWidget {
  final String examId;
  final ExamStartResponse startData;

  const ExamTakingScreen({
    super.key,
    required this.examId,
    required this.startData,
  });

  @override
  ConsumerState<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends ConsumerState<ExamTakingScreen> with WidgetsBindingObserver {
  late ExamStartResponse _data;
  int _currentIndex = 0;
  final Map<String, String?> _selectedAnswers = {}; // questionId -> optionId
  final Set<String> _savingQuestions = {};

  Timer? _timer;
  Duration _remaining = Duration.zero;
  late Duration _serverOffset;
  bool _isSubmitting = false;
  int _backgroundWarningCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenProtectionService.enableProtection();

    _data = widget.startData;
    // Calculate server offset
    _serverOffset = _data.serverNow.difference(DateTime.now());
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundWarningCount++;
      // Cheating prevention warning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          content: Text(
            'সতর্কবার্তা! পরীক্ষা চলাকালীন অ্যাপ পরিবর্তন বা মিনিমাইজ করা নিষিদ্ধ। (সতর্কতা: ${BengaliUtils.toBengaliNumerals(_backgroundWarningCount)})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final currentServerTime = DateTime.now().add(_serverOffset);
    final diff = _data.expiresAt.difference(currentServerTime);

    if (diff.isNegative || diff.inSeconds <= 0) {
      _timer?.cancel();
      setState(() => _remaining = Duration.zero);
      _autoSubmitOnTimeUp();
    } else {
      setState(() => _remaining = diff);
    }
  }

  Future<void> _autoSubmitOnTimeUp() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('সময় শেষ! তোমার খাতা স্বয়ংক্রিয়ভাবে জমা নেওয়া হচ্ছে...'),
        ),
      );
    }

    try {
      final repo = ref.read(examsRepositoryProvider);
      final result = await repo.submitExam(_data.attemptId);
      if (mounted) {
        context.pushReplacement('/exams/result/${_data.attemptId}', extra: result);
      }
    } catch (_) {
      if (mounted) context.go('/exams');
    }
  }

  Future<void> _selectOption(String questionId, String optionId) async {
    setState(() {
      _selectedAnswers[questionId] = optionId;
      _savingQuestions.add(questionId);
    });

    try {
      final repo = ref.read(examsRepositoryProvider);
      await repo.saveAnswer(
        attemptId: _data.attemptId,
        questionId: questionId,
        optionId: optionId,
      );
    } catch (_) {
      // Offline or network error
    } finally {
      if (mounted) {
        setState(() => _savingQuestions.remove(questionId));
      }
    }
  }

  Future<void> _submitExam() async {
    final answeredCount = _selectedAnswers.values.where((v) => v != null).length;
    final totalCount = _data.questions.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পরীক্ষা জমা দিতে চাও?'),
        content: Text(
          'তুমি মোট ${BengaliUtils.toBengaliNumerals(totalCount)} টির মধ্যে ${BengaliUtils.toBengaliNumerals(answeredCount)} টি প্রশ্নের উত্তর দিয়েছো। জমা দিলে আর কোনো উত্তর পরিবর্তন করা যাবে না।',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('আরও সময় নাও'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, জমা দাও', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(examsRepositoryProvider);
      final result = await repo.submitExam(_data.attemptId);
      if (!mounted) return;
      context.pushReplacement('/exams/result/${_data.attemptId}', extra: result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(ErrorTranslator.translate(e))),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtectionService.disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_data.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('পরীক্ষা')),
        body: const Center(child: Text('এই পরীক্ষায় কোনো প্রশ্ন যুক্ত করা হয়নি।')),
      );
    }

    final currentQuestion = _data.questions[_currentIndex];
    final selectedOptionId = _selectedAnswers[currentQuestion.id];
    final isLastQuestion = _currentIndex == _data.questions.length - 1;
    final isTimerLow = _remaining.inMinutes < 3;

    return WillPopScope(
      onWillPop: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('পরীক্ষা থেকে বের হতে চাও?'),
            content: const Text('পরীক্ষা চলাকালীন বের হলে টাইমার চালু থাকবে। তুমি কি নিশ্চিত?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না, চালিয়ে যাও')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('বের হয়ে যান', style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
        return leave ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'প্রশ্ন ${BengaliUtils.toBengaliNumerals(_currentIndex + 1)} / ${BengaliUtils.toBengaliNumerals(_data.questions.length)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            // Timer pill
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTimerLow ? AppColors.errorContainer : AppColors.primary50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTimerLow ? AppColors.error : AppColors.primary200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: isTimerLow ? AppColors.error : AppColors.primary600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    BengaliUtils.formatDuration(_remaining.inSeconds),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTimerLow ? AppColors.error : AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Question & Options Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MathTextWidget(
                              text: currentQuestion.questionText,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            if (currentQuestion.imageUrl != null &&
                                currentQuestion.imageUrl!.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: currentQuestion.imageUrl!.trim(),
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Container(
                                    height: 180,
                                    alignment: Alignment.center,
                                    color: AppColors.neutral100,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.neutral100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.imageOff, size: 18, color: AppColors.neutral500),
                                        SizedBox(width: 8),
                                        Text('ছবি লোড করা যায়নি', style: TextStyle(color: AppColors.neutral600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Options
                      for (int i = 0; i < currentQuestion.options.length; i++) ...[
                        _buildOptionTile(
                          option: currentQuestion.options[i],
                          questionId: currentQuestion.id,
                          index: i,
                          isSelected: selectedOptionId == currentQuestion.options[i].id,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Question Palette & Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: const Border(top: BorderSide(color: AppColors.neutral200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Palette horizontal scroll
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _data.questions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final q = _data.questions[idx];
                          final isAnswered = _selectedAnswers[q.id] != null;
                          final isCurrent = idx == _currentIndex;

                          Color bgColor = AppColors.neutral100;
                          Color textColor = AppColors.neutral700;

                          if (isCurrent) {
                            bgColor = AppColors.primary600;
                            textColor = Colors.white;
                          } else if (isAnswered) {
                            bgColor = AppColors.success;
                            textColor = Colors.white;
                          }

                          return InkWell(
                            onTap: () => setState(() => _currentIndex = idx),
                            borderRadius: BorderRadius.circular(19),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                BengaliUtils.toBengaliNumerals(idx + 1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _currentIndex--),
                              child: const Text('পূর্ববর্তী'),
                            ),
                          ),
                        if (_currentIndex > 0) const SizedBox(width: 12),
                        if (!isLastQuestion)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _currentIndex++),
                              child: const Text('পরবর্তী'),
                            ),
                          )
                        else
                          Expanded(
                            child: CustomButton(
                              text: 'খাতা জমা দাও',
                              backgroundColor: AppColors.success,
                              isLoading: _isSubmitting,
                              onPressed: _submitExam,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required QuestionOption option,
    required String questionId,
    required int index,
    required bool isSelected,
  }) {
    const letters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
    final letter = index < letters.length ? letters[index] : '${index + 1}';

    return InkWell(
      onTap: () => _selectOption(questionId, option.id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary600 : AppColors.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary600 : AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.neutral700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (option.optionText.trim().isNotEmpty)
                    MathTextWidget(
                      text: option.optionText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary900 : null,
                      ),
                    ),
                  if (option.imageUrl != null && option.imageUrl!.trim().isNotEmpty) ...[
                    if (option.optionText.trim().isNotEmpty) const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: CachedNetworkImage(
                          imageUrl: option.imageUrl!.trim(),
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            height: 70,
                            alignment: Alignment.center,
                            color: AppColors.neutral100,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(LucideIcons.imageOff, size: 16, color: AppColors.neutral400),
                                SizedBox(width: 6),
                                Text('ছবি লোড করা যায়নি', style: TextStyle(color: AppColors.neutral500, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

