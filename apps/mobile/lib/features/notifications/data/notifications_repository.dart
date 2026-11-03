import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final bool isAnnouncement;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.isAnnouncement = false,
  });

  factory NotificationItem.fromNotificationJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read_at'] != null,
      isAnnouncement: false,
    );
  }

  factory NotificationItem.fromAnnouncementJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse((json['published_at'] ?? json['created_at']) as String),
      isRead: false,
      isAnnouncement: true,
    );
  }
}

class NotificationsRepository {
  final SupabaseClient _supabase;
  NotificationsRepository(this._supabase);

  Future<List<NotificationItem>> getNotifications() async {
    final user = _supabase.auth.currentUser;
    final List<NotificationItem> items = [];

    // Fetch public published announcements
    try {
      final announcementsRes = await _supabase
          .from('announcements')
          .select('*')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(20);

      for (final a in announcementsRes as List<dynamic>) {
        items.add(NotificationItem.fromAnnouncementJson(a as Map<String, dynamic>));
      }
    } catch (_) {
      // announcements table might be empty or restricted
    }

    // Fetch student's own notifications if authenticated
    if (user != null) {
      try {
        final notificationsRes = await _supabase
            .from('notifications')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(20);

        for (final n in notificationsRes as List<dynamic>) {
          items.add(NotificationItem.fromNotificationJson(n as Map<String, dynamic>));
        }
      } catch (_) {
        // notifications table might be empty
      }
    }

    // Sort combined by created_at descending
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

final notificationsListProvider = FutureProvider<List<NotificationItem>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getNotifications();
});

