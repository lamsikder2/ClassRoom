import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/security/screen_protection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/lessons_repository.dart';
import 'custom_video_controls.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  YoutubePlayerController? _ytController;
  Timer? _progressTimer;
  int _lastSyncedPosition = 0;
  bool _isDescriptionExpanded = false;
  bool _isManuallyFullscreen = false;

  @override
  void initState() {
    super.initState();
    // Enable screen protection to prevent screen recording and screenshots of classes
    ScreenProtectionService.enableProtection();

    // Allow both portrait and landscape orientation when viewing a class video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _ytController?.close();
    ScreenProtectionService.disableProtection();

    // Reset back to portrait and default system UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _toggleFullscreen() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape || _isManuallyFullscreen) {
      // Exit fullscreen -> Switch to Portrait
      setState(() => _isManuallyFullscreen = false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      // Re-enable rotation after a short delay so sensor can still work
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      });
    } else {
      // Enter fullscreen -> Switch to Landscape
      setState(() => _isManuallyFullscreen = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _initPlayer(String videoRef) {
    if (_ytController != null) return;

    // Clean videoId if full URL was stored
    String videoId = videoRef;
    if (videoId.contains('v=')) {
      videoId = videoId.split('v=')[1].split('&')[0];
    } else if (videoId.contains('youtu.be/')) {
      videoId = videoId.split('youtu.be/')[1].split('?')[0];
    }

    // Initialize custom-controlled YouTube player without native branding
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: false,
        showControls: false,
        showVideoAnnotations: false,
        enableCaption: false,
        privacyEnhancedMode: true,
        strictRelatedVideos: true,
        playsInline: true,
        enableKeyboard: false,
      ),
    );

    // Sync progress every 10 seconds
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_ytController == null) return;
      try {
        final position = await _ytController!.currentTime;
        final currentSec = position.toInt();
        final delta = currentSec - _lastSyncedPosition;
        if (delta > 0 && delta <= 30) {
          _lastSyncedPosition = currentSec;
          ref.read(lessonsRepositoryProvider).updateProgress(
                lessonId: widget.lessonId,
                positionSec: currentSec,
                deltaWatchedSec: delta,
              );
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape || _isManuallyFullscreen;

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('ক্লাস রুম', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const ShimmerListPlaceholder(count: 3),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: const Text('ক্লাস রুম', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: EmptyStateWidget(
          title: 'ক্লাস লোড করা যায়নি',
          description: err.toString(),
          actionLabel: 'আবার চেষ্টা করুন',
          onAction: () => ref.refresh(lessonDetailProvider(widget.lessonId)),
        ),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ক্লাস রুম', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: const EmptyStateWidget(
              title: 'ক্লাস পাওয়া যায়নি',
              description: 'অনুরোধকৃত ক্লাসটি খুঁজে পাওয়া যায়নি বা মুছে ফেলা হয়েছে।',
            ),
          );
        }

        final lesson = data.lesson;
        final materials = data.materials;
        final exams = data.exams;

        // Initialize video player if videoRef exists
        if (lesson.videoRef != null && lesson.videoRef!.isNotEmpty && _ytController == null) {
          _initPlayer(lesson.videoRef!);
        }

        // Fullscreen Landscape View
        if (isLandscape && _ytController != null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _toggleFullscreen();
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: _ytController!,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                  CustomVideoControls(
                    controller: _ytController!,
                    title: lesson.title,
                    isFullscreen: true,
                    onToggleFullscreen: _toggleFullscreen,
                    fallbackDuration: lesson.videoDurationSec != null
                        ? Duration(seconds: lesson.videoDurationSec!)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        // Portrait Normal View
        return Scaffold(
          appBar: AppBar(
            title: const Text('ক্লাস রুম', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Video Player Section
                if (_ytController != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        YoutubePlayer(
                          controller: _ytController!,
                          aspectRatio: 16 / 9,
                        ),
                        CustomVideoControls(
                          controller: _ytController!,
                          title: lesson.title,
                          isFullscreen: false,
                          onToggleFullscreen: _toggleFullscreen,
                          fallbackDuration: lesson.videoDurationSec != null
                              ? Duration(seconds: lesson.videoDurationSec!)
                              : null,
                        ),
                      ],
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppColors.neutral900,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.videoOff, color: AppColors.neutral500, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'এই ক্লাসের কোনো ভিডিও লিংক নেই',
                              style: TextStyle(color: AppColors.neutral400, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Lesson Title, Instructor, and Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (lesson.instructorName != null && lesson.instructorName!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.user, size: 12, color: AppColors.primary600),
                                  const SizedBox(width: 4),
                                  Text(
                                    lesson.instructorName!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (lesson.videoDurationSec != null && lesson.videoDurationSec! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.clock, size: 12, color: AppColors.neutral600),
                                  const SizedBox(width: 4),
                                  Text(
                                    BengaliUtils.formatDuration(lesson.videoDurationSec!),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutral600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.description!,
                                maxLines: _isDescriptionExpanded ? 100 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.neutral600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isDescriptionExpanded ? 'কম দেখুন' : 'আরও দেখুন...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.neutral200),

                // Materials & Exams Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.folder, size: 18, color: AppColors.primary600),
                          const SizedBox(width: 8),
                          Text(
                            'ক্লাস রিসোর্স ও পরীক্ষা',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (materials.isEmpty && exams.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: const Center(
                            child: Text(
                              'এই ক্লাসের জন্য এখনো কোনো লেকচার শিট, ক্লাস নোট বা পরীক্ষা সংযুক্ত করা হয়নি।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.neutral500, fontSize: 13),
                            ),
                          ),
                        ),
                      ],

                      // Materials small cards
                      for (final mat in materials) ...[
                        _buildMaterialCard(context, mat),
                        const SizedBox(height: 10),
                      ],

                      // Exams small cards
                      for (final exam in exams) ...[
                        _buildExamCard(context, exam),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialCard(BuildContext context, LessonMaterialItem mat) {
    final isSheet = mat.type == 'lecture_sheet';
    final cardColor = isSheet ? AppColors.errorContainer.withOpacity(0.4) : AppColors.teal50;
    final iconColor = isSheet ? AppColors.error : AppColors.teal600;
    final iconData = isSheet ? LucideIcons.fileText : LucideIcons.bookOpen;
    final badgeLabel = isSheet ? 'লেকচার শিট' : 'ক্লাস নোট';

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          if (isSheet) {
            context.push('/materials/pdf/${mat.id}', extra: mat);
          } else {
            context.push('/materials/note/${mat.id}', extra: mat);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mat.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isSheet)
                      Text(
                        mat.allowDownload ? 'প্রিভিউ ও ডাউনলোড করুন' : 'শুধুমাত্র প্রিভিউ',
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                      ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, LessonExamItem exam) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          context.push('/exams/${exam.id}/intro', extra: exam.title);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.amber500.withOpacity(0.5)),
            color: AppColors.amber100.withOpacity(0.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.checkSquare, color: AppColors.amber600, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ক্লাস এক্সাম',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amber600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'সময়: ${BengaliUtils.formatDurationWords(exam.durationMinutes)} • পূর্ণমান: ${BengaliUtils.toBengaliNumerals(exam.totalMarks.toInt())}',
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  context.push('/exams/${exam.id}/intro', extra: exam.title);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: AppColors.amber500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('পরীক্ষা দাও', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

