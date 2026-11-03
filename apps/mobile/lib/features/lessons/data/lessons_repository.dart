import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class LessonItem {
  final String id;
  final String chapterId;
  final String title;
  final String? description;
  final String videoProvider;
  final String? videoRef;
  final int? videoDurationSec;
  final String? thumbnailUrl;
  final String? instructorName;
  final int sortOrder;

  LessonItem({
    required this.id,
    required this.chapterId,
    required this.title,
    this.description,
    required this.videoProvider,
    this.videoRef,
    this.videoDurationSec,
    this.thumbnailUrl,
    this.instructorName,
    this.sortOrder = 0,
  });

  factory LessonItem.fromJson(Map<String, dynamic> json) {
    return LessonItem(
      id: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      videoProvider: json['video_provider'] as String? ?? 'youtube',
      videoRef: json['video_ref'] as String?,
      videoDurationSec: json['video_duration_sec'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructorName: json['instructor_name'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class LessonMaterialItem {
  final String id;
  final String lessonId;
  final String type; // lecture_sheet, class_note, other
  final String source; // drive, rich_text, storage
  final String title;
  final String? driveFileId;
  final String? contentMd;
  final int? fileSizeBytes;
  final bool allowDownload;

  LessonMaterialItem({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.source,
    required this.title,
    this.driveFileId,
    this.contentMd,
    this.fileSizeBytes,
    this.allowDownload = true,
  });

  factory LessonMaterialItem.fromJson(Map<String, dynamic> json) {
    return LessonMaterialItem(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      title: json['title'] as String,
      driveFileId: json['drive_file_id'] as String?,
      contentMd: json['content_md'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      allowDownload: json['allow_download'] as bool? ?? true,
    );
  }
}

class LessonExamItem {
  final String id;
  final String title;
  final int durationMinutes;
  final double totalMarks;

  LessonExamItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.totalMarks,
  });

  factory LessonExamItem.fromJson(Map<String, dynamic> json) {
    final durSec = json['duration_sec'] as int?;
    return LessonExamItem(
      id: json['id'] as String,
      title: json['title'] as String,
      durationMinutes: durSec != null ? durSec ~/ 60 : (json['duration_minutes'] as int? ?? 15),
      totalMarks: (json['total_marks'] ?? json['mark_per_question'] as num?)?.toDouble() ?? 20.0,
    );
  }
}

class LessonDetailData {
  final LessonItem lesson;
  final List<LessonMaterialItem> materials;
  final List<LessonExamItem> exams;

  LessonDetailData({
    required this.lesson,
    required this.materials,
    required this.exams,
  });
}

class LessonsRepository {
  final SupabaseClient _supabase;
  LessonsRepository(this._supabase);

  Future<List<LessonItem>> getLessonsForChapter(String chapterId) async {
    final response = await _supabase
        .from('lessons')
        .select('*')
        .eq('chapter_id', chapterId)
        .eq('is_published', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((e) => LessonItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LessonDetailData?> getLessonDetail(String lessonId) async {
    final lessonRes = await _supabase
        .from('lessons')
        .select('*')
        .eq('id', lessonId)
        .maybeSingle();

    if (lessonRes == null) return null;
    final lesson = LessonItem.fromJson(lessonRes);

    final materialsRes = await _supabase
        .from('materials')
        .select('*')
        .eq('lesson_id', lessonId);

    final materials = (materialsRes as List<dynamic>)
        .map((e) => LessonMaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Check if there is a lesson-linked exam
    final examsRes = await _supabase
        .from('exams')
        .select('id, title, duration_sec, mark_per_question')
        .eq('lesson_id', lessonId)
        .eq('is_published', true);

    final exams = (examsRes as List<dynamic>)
        .map((e) => LessonExamItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return LessonDetailData(
      lesson: lesson,
      materials: materials,
      exams: exams,
    );
  }

  Future<LessonMaterialItem?> getMaterialById(String materialId) async {
    final res = await _supabase
        .from('materials')
        .select('*')
        .eq('id', materialId)
        .maybeSingle();
    if (res == null) return null;
    return LessonMaterialItem.fromJson(res);
  }

  Future<void> updateProgress({
    required String lessonId,
    required int positionSec,
    required int deltaWatchedSec,
  }) async {
    try {
      await _supabase.rpc('update_lesson_progress', params: {
        'p_lesson_id': lessonId,
        'p_position_sec': positionSec,
        'p_delta_watched_sec': deltaWatchedSec,
      });
    } catch (_) {
      // Non-blocking background sync
    }
  }
}

final lessonsRepositoryProvider = Provider<LessonsRepository>((ref) {
  return LessonsRepository(ref.watch(supabaseClientProvider));
});

final chapterLessonsProvider = FutureProvider.family<List<LessonItem>, String>((ref, chapterId) async {
  return ref.watch(lessonsRepositoryProvider).getLessonsForChapter(chapterId);
});

final lessonDetailProvider = FutureProvider.family<LessonDetailData?, String>((ref, lessonId) async {
  return ref.watch(lessonsRepositoryProvider).getLessonDetail(lessonId);
});
