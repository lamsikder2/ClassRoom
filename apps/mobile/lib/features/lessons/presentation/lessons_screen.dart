import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/shimmer_loading.dart';
import '../data/lessons_repository.dart';

class LessonsScreen extends ConsumerWidget {
  final String chapterId;
  final String? chapterName;

  const LessonsScreen({
    super.key,
    required this.chapterId,
    this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(chapterLessonsProvider(chapterId));

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterName ?? 'ক্লাসসমূহ', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: lessonsAsync.when(
        loading: () => const ShimmerListPlaceholder(count: 4),
        error: (err, _) => EmptyStateWidget(
          title: 'ক্লাস লোড করা যায়নি',
          description: err.toString(),
          actionLabel: 'আবার চেষ্টা করুন',
          onAction: () => ref.refresh(chapterLessonsProvider(chapterId)),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return EmptyStateWidget(
              icon: LucideIcons.playCircle,
              title: 'কোনো ক্লাস পাওয়া যায়নি',
              description: 'এই অধ্যায়ের অধীনে এখনো কোনো ভিডিও ক্লাস যুক্ত করা হয়নি।',
              actionLabel: 'রিফ্রেশ করুন',
              onAction: () => ref.refresh(chapterLessonsProvider(chapterId)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final classNumber = BengaliUtils.toBengaliNumerals((index + 1).toString().padLeft(2, '0'));

              return Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    context.push('/lessons/${lesson.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail box with duration overlay
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: lesson.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppColors.neutral100,
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (_, __, ___) => _buildDefaultThumbnail(context),
                                    )
                                  : _buildDefaultThumbnail(context),
                            ),
                            // Duration pill
                            if (lesson.videoDurationSec != null && lesson.videoDurationSec! > 0)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    BengaliUtils.formatDuration(lesson.videoDurationSec!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            // Center Play Icon
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary600.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.play,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ক্লাস $classNumber',
                                      style: const TextStyle(
                                        color: AppColors.primary600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (lesson.instructorName != null && lesson.instructorName!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ইন্সট্রাক্টর: ${lesson.instructorName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lesson.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
    );
  }

  Widget _buildDefaultThumbnail(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.video,
          color: Colors.white30,
          size: 48,
        ),
      ),
    );
  }
}

