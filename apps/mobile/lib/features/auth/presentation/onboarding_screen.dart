import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/auth_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _selectedLevelId;
  bool _isSubmitting = false;

  Future<void> _saveLevel() async {
    if (_selectedLevelId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).updateProfileLevel(_selectedLevelId!);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('লেভেল সংরক্ষণে ত্রুটি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(activeLevelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('আপনার শ্রেণী নির্বাচন করুন'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'তুমি কোন শ্রেণীতে পড়ছো?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'তোমার শ্রেণী অনুযায়ী বিষয়, ক্লাস ও পরীক্ষার কনটেন্ট প্রদর্শিত হবে।',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: levelsAsync.when(
                  loading: () => const ShimmerListPlaceholder(count: 4),
                  error: (err, _) => EmptyStateWidget(
                    title: 'ডাটা লোড করা যায়নি',
                    description: err.toString(),
                    actionLabel: 'আবার চেষ্টা করুন',
                    onAction: () => ref.refresh(activeLevelsProvider),
                  ),
                  data: (levels) {
                    if (levels.isEmpty) {
                      return EmptyStateWidget(
                        icon: LucideIcons.layers,
                        title: 'কোনো শ্রেণী পাওয়া যায়নি',
                        description: 'অ্যাডমিন প্যানেল থেকে এখনো কোনো ক্লাস বা লেভেল যোগ করা হয়নি।',
                        actionLabel: 'রিফ্রেশ করুন',
                        onAction: () => ref.refresh(activeLevelsProvider),
                      );
                    }

                    return ListView.separated(
                      itemCount: levels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final level = levels[index];
                        final isSelected = _selectedLevelId == level.id;

                        return InkWell(
                          onTap: () => setState(() => _selectedLevelId = level.id),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.primary900
                                      : AppColors.primary50)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary600
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.neutral800
                                        : AppColors.neutral200),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary600 : AppColors.neutral100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.bookOpen,
                                    color: isSelected ? AppColors.neutral0 : AppColors.neutral600,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.primary600
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? AppColors.neutral100
                                                  : AppColors.neutral900),
                                        ),
                                      ),
                                      Text(
                                        level.code,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Radio<String>(
                                  value: level.id,
                                  groupValue: _selectedLevelId,
                                  activeColor: AppColors.primary600,
                                  onChanged: (val) => setState(() => _selectedLevelId = val),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'পড়া শুরু করো',
                isLoading: _isSubmitting,
                onPressed: _selectedLevelId == null ? null : _saveLevel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

