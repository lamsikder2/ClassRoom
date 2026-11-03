import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class ExamListItem {
  final String id;
  final String title;
  final String? description;
  final String examType; // live, practice, quiz
  final int durationMinutes;
  final double totalMarks;
  final double negativeMarkingRate;
  final DateTime? liveStartAt;
  final DateTime? liveEndAt;
  final String? subjectName;
  final String? chapterName;

  ExamListItem({
    required this.id,
    required this.title,
    this.description,
    required this.examType,
    required this.durationMinutes,
    required this.totalMarks,
    this.negativeMarkingRate = 0.0,
    this.liveStartAt,
    this.liveEndAt,
    this.subjectName,
    this.chapterName,
  });

  factory ExamListItem.fromJson(Map<String, dynamic> json) {
    String? subName;
    String? chName;
    if (json['subjects'] != null && json['subjects'] is Map) {
      subName = (json['subjects'] as Map)['name'] as String?;
    }
    if (json['chapters'] != null && json['chapters'] is Map) {
      chName = ((json['chapters'] as Map)['title'] ?? (json['chapters'] as Map)['name']) as String?;
    }

    return ExamListItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      examType: (json['mode'] ?? json['exam_type'] ?? 'practice') as String,
      durationMinutes: ((json['duration_sec'] != null ? (json['duration_sec'] as int) ~/ 60 : json['duration_minutes']) ?? 20) as int,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 20.0,
      negativeMarkingRate: ((json['negative_mark'] ?? json['negative_marking_rate']) as num?)?.toDouble() ?? 0.0,
      liveStartAt: (json['starts_at'] ?? json['live_start_at']) != null ? DateTime.tryParse((json['starts_at'] ?? json['live_start_at']) as String) : null,
      liveEndAt: (json['ends_at'] ?? json['live_end_at']) != null ? DateTime.tryParse((json['ends_at'] ?? json['live_end_at']) as String) : null,
      subjectName: subName,
      chapterName: chName,
    );
  }
}

class QuestionOption {
  final String id;
  final String optionText;
  final int sortOrder;
  final String? imageUrl;

  QuestionOption({
    required this.id,
    required this.optionText,
    required this.sortOrder,
    this.imageUrl,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      optionText: (json['body'] ?? json['option_text'] ?? '') as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
    );
  }
}

class ExamQuestion {
  final String id;
  final String questionText;
  final double marks;
  final String? imageUrl;
  final List<QuestionOption> options;

  ExamQuestion({
    required this.id,
    required this.questionText,
    required this.marks,
    this.imageUrl,
    required this.options,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return ExamQuestion(
      id: json['id'] as String,
      questionText: (json['body'] ?? json['question_text'] ?? '') as String,
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      options: opts,
    );
  }
}

class ExamStartResponse {
  final String attemptId;
  final String examId;
  final DateTime serverNow;
  final DateTime expiresAt;
  final List<ExamQuestion> questions;

  ExamStartResponse({
    required this.attemptId,
    required this.examId,
    required this.serverNow,
    required this.expiresAt,
    required this.questions,
  });

  factory ExamStartResponse.fromJson(Map<String, dynamic> json) {
    final qList = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
        .toList();

    final deadlineStr = (json['deadline_at'] ?? json['expires_at'] ?? json['deadline'] ?? json['server_now']) as String;

    return ExamStartResponse(
      attemptId: json['attempt_id'] as String,
      examId: json['exam_id'] as String,
      serverNow: DateTime.parse(json['server_now'] as String),
      expiresAt: DateTime.parse(deadlineStr),
      questions: qList,
    );
  }
}

class ExamReviewOption {
  final String id;
  final String body;
  final String? imageUrl;
  final bool isCorrect;

  ExamReviewOption({
    required this.id,
    required this.body,
    this.imageUrl,
    required this.isCorrect,
  });

  factory ExamReviewOption.fromJson(Map<String, dynamic> json) {
    return ExamReviewOption(
      id: json['id'] as String,
      body: (json['body'] ?? '') as String,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class ExamReviewItem {
  final String questionId;
  final String body;
  final String? imageUrl;
  final String? explanation;
  final String? explanationImageUrl;
  final String? selectedOptionId;
  final bool? isCorrect;
  final List<ExamReviewOption> options;

  ExamReviewItem({
    required this.questionId,
    required this.body,
    this.imageUrl,
    this.explanation,
    this.explanationImageUrl,
    this.selectedOptionId,
    this.isCorrect,
    required this.options,
  });

  factory ExamReviewItem.fromJson(Map<String, dynamic> json) {
    return ExamReviewItem(
      questionId: (json['question_id'] ?? json['id'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      explanation: json['explanation'] as String?,
      explanationImageUrl: (json['explanation_image_url'] ?? json['explanationImageUrl']) as String?,
      selectedOptionId: json['selected_option_id'] as String?,
      isCorrect: json['is_correct'] as bool?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => ExamReviewOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExamSubmitResult {
  final String attemptId;
  final double totalScore;
  final double totalMarks;
  final double percentage;
  final bool passed;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final double negativeDeduction;
  final int? rank;
  final List<ExamReviewItem>? review;

  ExamSubmitResult({
    required this.attemptId,
    required this.totalScore,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.negativeDeduction,
    this.rank,
    this.review,
  });

  factory ExamSubmitResult.fromJson(Map<String, dynamic> json) {
    final revList = (json['review'] as List<dynamic>?)
        ?.map((e) => ExamReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ExamSubmitResult(
      attemptId: json['attempt_id'] as String,
      totalScore: (json['score'] ?? json['total_score'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: (json['is_passed'] ?? json['passed']) as bool? ?? false,
      correctCount: (json['correct'] ?? json['correct_count']) as int? ?? 0,
      incorrectCount: (json['wrong'] ?? json['incorrect_count']) as int? ?? 0,
      skippedCount: (json['skipped'] ?? json['skipped_count']) as int? ?? 0,
      negativeDeduction: (json['negative_deduction'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int?,
      review: revList,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String studentName;
  final double score;
  final int timeTakenSec;

  LeaderboardEntry({
    required this.rank,
    required this.studentName,
    required this.score,
    required this.timeTakenSec,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      studentName: json['student_name'] as String? ?? 'শিক্ষার্থী',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      timeTakenSec: json['time_taken_sec'] as int? ?? 0,
    );
  }
}

class ExamsRepository {
  final SupabaseClient _supabase;
  ExamsRepository(this._supabase);

  Future<List<ExamListItem>> getExams({String? subjectId, String? chapterId}) async {
    var query = _supabase
        .from('exams')
        .select('*, subjects(name), chapters(title)')
        .eq('is_published', true);

    if (subjectId != null) query = query.eq('subject_id', subjectId);
    if (chapterId != null) query = query.eq('chapter_id', chapterId);

    final response = await query.order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => ExamListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExamListItem?> getExamById(String examId) async {
    final response = await _supabase
        .from('exams')
        .select('*, subjects(name), chapters(title)')
        .eq('id', examId)
        .maybeSingle();

    if (response == null) return null;
    return ExamListItem.fromJson(response);
  }

  Future<ExamStartResponse> startExam(String examId) async {
    final response = await _supabase.rpc('start_exam', params: {
      'p_exam_id': examId,
    });
    return ExamStartResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required String? optionId,
  }) async {
    await _supabase.rpc('save_answer', params: {
      'p_attempt_id': attemptId,
      'p_question_id': questionId,
      'p_option_id': optionId,
    });
  }

  Future<ExamSubmitResult> submitExam(String attemptId) async {
    final response = await _supabase.rpc('submit_exam', params: {
      'p_attempt_id': attemptId,
    });
    return ExamSubmitResult.fromJson(response as Map<String, dynamic>);
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String examId) async {
    try {
      final response = await _supabase.rpc('get_exam_leaderboard', params: {
        'p_exam_id': examId,
        'p_limit': 50,
      });
      return (response as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  return ExamsRepository(ref.watch(supabaseClientProvider));
});

final examsListProvider = FutureProvider<List<ExamListItem>>((ref) async {
  return ref.watch(examsRepositoryProvider).getExams();
});

final examDetailProvider = FutureProvider.family<ExamListItem?, String>((ref, examId) async {
  return ref.watch(examsRepositoryProvider).getExamById(examId);
});
