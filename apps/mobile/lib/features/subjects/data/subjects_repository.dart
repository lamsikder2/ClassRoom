import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/data/auth_repository.dart';

class SubjectItem {
  final String id;
  final String name;
  final String? code;
  final String? color;
  final String? iconName;
  final int chapterCount;

  SubjectItem({
    required this.id,
    required this.name,
    this.code,
    this.color,
    this.iconName,
    this.chapterCount = 0,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    int chCount = 0;
    if (json['chapters'] != null && json['chapters'] is List) {
      chCount = (json['chapters'] as List).length;
    }
    return SubjectItem(
      id: json['id'] as String,
      name: json['name'] as String,
      code: (json['slug'] ?? json['code']) as String?,
      color: (json['color_hex'] ?? json['color']) as String?,
      iconName: (json['icon_url'] ?? json['icon_name']) as String?,
      chapterCount: chCount,
    );
  }
}

class ChapterItem {
  final String id;
  final String subjectId;
  final String name;
  final int chapterNumber;
  final String? description;
  final int lessonCount;
  final int examCount;

  ChapterItem({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.chapterNumber,
    this.description,
    this.lessonCount = 0,
    this.examCount = 0,
  });

  factory ChapterItem.fromJson(Map<String, dynamic> json) {
    int lCount = 0;
    int eCount = 0;
    if (json['lessons'] != null && json['lessons'] is List) {
      lCount = (json['lessons'] as List).length;
    }
    if (json['exams'] != null && json['exams'] is List) {
      eCount = (json['exams'] as List).length;
    }
    return ChapterItem(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      name: (json['title'] ?? json['name'] ?? '') as String,
      chapterNumber: (json['chapter_no'] ?? json['chapter_number'] ?? 1) as int,
      description: json['description'] as String?,
      lessonCount: lCount,
      examCount: eCount,
    );
  }
}

class SubjectsRepository {
  final SupabaseClient _supabase;
  SubjectsRepository(this._supabase);

  Future<List<SubjectItem>> getSubjectsForLevel(String? levelId) async {
    var query = _supabase
        .from('subjects')
        .select('id, level_id, name, slug, color_hex, icon_url, sort_order, chapters(id)')
        .eq('is_published', true);

    if (levelId != null) {
      query = query.eq('level_id', levelId);
    }

    final response = await query.order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((e) => SubjectItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChapterItem>> getChaptersForSubject(String subjectId) async {
    final response = await _supabase
        .from('chapters')
        .select('id, subject_id, title, chapter_no, description, sort_order, lessons(id), exams(id)')
        .eq('subject_id', subjectId)
        .eq('is_published', true)
        .order('chapter_no', ascending: true);

    return (response as List<dynamic>)
        .map((e) => ChapterItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectItem?> getSubjectById(String subjectId) async {
    final response = await _supabase
        .from('subjects')
        .select('id, name, slug, color_hex, icon_url')
        .eq('id', subjectId)
        .maybeSingle();

    if (response == null) return null;
    return SubjectItem.fromJson(response);
  }
}

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(supabaseClientProvider));
});

final subjectsListProvider = FutureProvider<List<SubjectItem>>((ref) async {
  // Watch profile without hard-blocking so subjects load quickly
  final profileAsync = ref.watch(currentProfileProvider);
  final levelId = profileAsync.asData?.value?.levelId;
  return ref.watch(subjectsRepositoryProvider).getSubjectsForLevel(levelId);
});

final chaptersListProvider = FutureProvider.family<List<ChapterItem>, String>((ref, subjectId) async {
  return ref.watch(subjectsRepositoryProvider).getChaptersForSubject(subjectId);
});

