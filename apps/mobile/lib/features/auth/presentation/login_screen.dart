import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_translator.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/google_icon.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'একটি সঠিক ইমেইল ঠিকানা প্রদান করুন');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'পাসওয়ার্ড ন্যূনতম ৬ অক্ষরের হতে হবে');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_tabController.index == 0) {
        // Sign In
        await authRepo.signInWithEmail(email: email, password: password);
      } else {
        // Sign Up
        if (name.isEmpty) {
          setState(() {
            _errorMessage = 'আপনার পূর্ণ নাম লিখুন';
            _isLoading = false;
          });
          return;
        }
        await authRepo.signUpWithEmail(email: email, password: password, fullName: name);
      }

      // Check if user has level selected
      final profile = await authRepo.getCurrentProfile();
      if (!mounted) return;

      if (profile?.levelId == null) {
        context.go('/onboarding');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorTranslator.translate(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!kIsWeb && success && mounted) {
        final profile = await ref.read(authRepositoryProvider).getCurrentProfile();
        if (!mounted) return;
        if (profile?.levelId == null) {
          context.go('/onboarding');
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorTranslator.translate(e);
      });
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // App Branding
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.graduationCap,
                    size: 34,
                    color: AppColors.neutral0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ClassRoom',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'শিক্ষার্থীদের ডিজিটাল পাঠশালা ও প্রস্তুতি মঞ্চ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
              ),
              const SizedBox(height: 32),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.neutral900
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.neutral800
                        : AppColors.neutral200,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.neutral800
                        : AppColors.neutral0,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary600,
                  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.neutral400
                      : AppColors.neutral600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'লগইন'),
                    Tab(text: 'নতুন একাউন্ট'),
                  ],
                  onTap: (_) => setState(() => _errorMessage = null),
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form fields
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_tabController.index == 1) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'আপনার পূর্ণ নাম',
                            prefixIcon: Icon(LucideIcons.user, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ইমেইল ঠিকানা',
                          prefixIcon: Icon(LucideIcons.mail, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'পাসওয়ার্ড',
                          prefixIcon: const Icon(LucideIcons.lock, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: _tabController.index == 0 ? 'লগইন করুন' : 'নিবন্ধন সম্পন্ন করুন',
                        isLoading: _isLoading,
                        onPressed: _handleAuth,
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.neutral800
                                  : AppColors.neutral200,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'অথবা',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.neutral400
                                    : AppColors.neutral500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.neutral800
                                  : AppColors.neutral200,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Sign In / Sign Up Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (_isLoading || _isGoogleLoading) ? null : _handleGoogleAuth,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.neutral900
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.neutral800
                                    : AppColors.neutral300,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isGoogleLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const GoogleIcon(size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _tabController.index == 0
                                            ? 'Google দিয়ে লগইন করুন'
                                            : 'Google দিয়ে একাউন্ট তৈরি করুন',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? AppColors.neutral100
                                              : AppColors.neutral800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

