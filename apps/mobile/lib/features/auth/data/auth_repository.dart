import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class AcademicLevel {
  final String id;
  final String code;
  final String name;

  AcademicLevel({required this.id, required this.code, required this.name});

  factory AcademicLevel.fromJson(Map<String, dynamic> json) {
    return AcademicLevel(
      id: json['id'] as String,
      code: (json['slug'] ?? json['code'] ?? '') as String,
      name: json['name'] as String,
    );
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? levelId;
  final String? levelName;

  UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.levelId,
    this.levelName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? lName;
    if (json['levels'] != null && json['levels'] is Map) {
      lName = (json['levels'] as Map)['name'] as String?;
    }
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'শিক্ষার্থী',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      levelId: json['level_id'] as String?,
      levelName: lName,
    );
  }
}

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  Future<bool> signInWithGoogle() async {
    final redirectUrl = kIsWeb ? Uri.base.origin : 'io.supabase.classroom://login-callback';
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<List<AcademicLevel>> getActiveLevels() async {
    final response = await _supabase
        .from('levels')
        .select('id, slug, name, name_en, sort_order')
        .eq('is_published', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((e) => AcademicLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, phone, avatar_url, level_id, levels(name)')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<void> updateProfileLevel(String levelId) async {
    final user = currentUser;
    if (user == null) return;
    await _supabase.from('profiles').update({
      'level_id': levelId,
    }).eq('id', user.id);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch session changes
  ref.watch(currentUserProvider);
  return ref.watch(authRepositoryProvider).getCurrentProfile();
});

final activeLevelsProvider = FutureProvider<List<AcademicLevel>>((ref) async {
  return ref.watch(authRepositoryProvider).getActiveLevels();
});

