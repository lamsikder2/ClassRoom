import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট করতে চান?'),
        content: const Text('আপনি কি নিশ্চিত যে আপনার একাউন্ট থেকে লগআউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল ও সেটিংস', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
              profileAsync.when(
                loading: () => const ShimmerSkeleton(width: double.infinity, height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (profile) {
                  return Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary600.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.user, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName ?? 'শিক্ষার্থী',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
                              ),
                              const SizedBox(height: 6),
                              if (profile?.levelName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.primary900 : AppColors.primary50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? AppColors.primary700 : AppColors.primary200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    profile!.levelName!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.primary300 : AppColors.primary600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Theme Selector Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'অ্যাপ থিম (Theme)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ThemeChoiceChip(
                            icon: LucideIcons.sun,
                            label: 'লাইট',
                            isSelected: themeMode == ThemeMode.light,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ThemeChoiceChip(
                            icon: LucideIcons.moon,
                            label: 'ডার্ক',
                            isSelected: themeMode == ThemeMode.dark,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ThemeChoiceChip(
                            icon: LucideIcons.laptop,
                            label: 'সিস্টেম',
                            isSelected: themeMode == ThemeMode.system,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Menu Options
              _buildMenuSection(
                context: context,
                title: 'পড়াশোনা ও রিসোর্স',
                items: [
                  _MenuItem(
                    icon: LucideIcons.layers,
                    title: 'শ্রেণী পরিবর্তন করুন',
                    subtitle: 'অন্য ক্লাসের কনটেন্ট পড়তে শ্রেণী বদলান',
                    onTap: () => context.push('/onboarding'),
                  ),
                  _MenuItem(
                    icon: LucideIcons.downloadCloud,
                    title: 'অফলাইন ডাউনলোডসমূহ',
                    subtitle: 'সংরক্ষিত লেকচার শিট পড়ুন',
                    onTap: () => context.push('/downloads'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildMenuSection(
                context: context,
                title: 'অ্যাপ সেটিংস ও তথ্য',
                items: [
                  _MenuItem(
                    icon: LucideIcons.info,
                    title: 'অ্যাপ ভার্সন',
                    trailingText: 'v${AppConfig.appVersion}',
                  ),
                  _MenuItem(
                    icon: LucideIcons.shieldCheck,
                    title: 'নিরাপত্তা ও স্ক্রিন প্রটেকশন',
                    subtitle: 'DRM প্রটেকশন সক্রিয় আছে',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
                label: const Text('লগআউট করুন', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required List<_MenuItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral500),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary900 : AppColors.primary50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(items[i].icon, size: 18, color: AppColors.primary600),
                  ),
                  title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: items[i].subtitle != null
                      ? Text(items[i].subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.neutral500))
                      : null,
                  trailing: items[i].trailingText != null
                      ? Text(items[i].trailingText!, style: const TextStyle(color: AppColors.neutral500, fontSize: 13))
                      : const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.neutral400),
                  onTap: items[i].onTap,
                ),
                if (i < items.length - 1)
                  Divider(height: 1, indent: 56, color: isDark ? AppColors.neutral800 : AppColors.neutral100),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary700 : AppColors.primary600)
              : (isDark ? AppColors.neutral900 : AppColors.neutral100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? AppColors.neutral300 : AppColors.neutral700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.neutral300 : AppColors.neutral700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
  });
}
