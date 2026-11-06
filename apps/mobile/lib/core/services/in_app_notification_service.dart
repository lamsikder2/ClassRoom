import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import 'notification_sound_service.dart';

class InAppNotificationService {
  InAppNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _currentEntry;

  static void show({
    required String title,
    required String body,
    String? deepLink,
    String? lessonId,
  }) {
    // Play sound immediately
    NotificationSoundService.playNotificationSound();

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Remove existing entry if any
    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppBannerWidget(
        title: title,
        body: body,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
        onTap: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            if (lessonId != null && lessonId.isNotEmpty) {
              ctx.push('/lessons/$lessonId');
            } else if (deepLink != null && deepLink.isNotEmpty) {
              if (deepLink.startsWith('/')) {
                ctx.push(deepLink);
              }
            }
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _InAppBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppBannerWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_InAppBannerWidget> createState() => _InAppBannerWidgetState();
}

class _InAppBannerWidgetState extends State<_InAppBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Auto dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 5000), () {
      _close();
    });
  }

  void _close() {
    _dismissTimer?.cancel();
    if (mounted) {
      _animController.reverse().then((_) {
        widget.onDismiss();
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -5) {
                  _close();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A), // Slate 900
                      Color(0xFF064E3B), // Emerald 900
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary900.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary500.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bell Icon with glow
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary400,
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.bellRing,
                          color: AppColors.primary300,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Body
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'নতুন আপডেট',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (widget.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _close,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

