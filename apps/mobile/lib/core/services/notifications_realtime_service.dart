import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';
import '../../features/notifications/data/notifications_repository.dart';
import 'in_app_notification_service.dart';

class NotificationsRealtimeService {
  final SupabaseClient _supabase;
  final Ref _ref;
  RealtimeChannel? _alertsChannel;
  RealtimeChannel? _announcementsChannel;

  NotificationsRealtimeService(this._supabase, this._ref);

  void startListening() {
    stopListening();

    try {
      // 1. Subscribe to Broadcast channel 'classroom_alerts'
      _alertsChannel = _supabase.channel('classroom_alerts');
      _alertsChannel?.onBroadcast(
        event: 'new_alert',
        callback: (payload) {
          debugPrint('Realtime alert received: $payload');
          final title = payload['title'] as String? ?? 'নতুন নোটিফিকেশন';
          final body = payload['body'] as String? ?? '';
          final lessonId = payload['lesson_id'] as String?;
          final deepLink = payload['deep_link'] as String?;

          // Refresh notifications list in Riverpod
          _ref.invalidate(notificationsListProvider);

          // Show floating animated banner + play chime sound
          InAppNotificationService.show(
            title: title,
            body: body,
            lessonId: lessonId,
            deepLink: deepLink,
          );
        },
      ).subscribe();

      // 2. Also listen for Postgres INSERTs on 'announcements' table
      _announcementsChannel = _supabase.channel('public:announcements');
      _announcementsChannel?.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: (payload) {
          debugPrint('Postgres announcement insert received: ${payload.newRecord}');
          final record = payload.newRecord;
          if (record.isNotEmpty) {
            final isPublished = record['is_published'] as bool? ?? false;
            if (isPublished) {
              final title = record['title'] as String? ?? 'নতুন ঘোষণা';
              final body = record['body'] as String? ?? '';
              final deepLink = record['deep_link'] as String?;

              _ref.invalidate(notificationsListProvider);

              InAppNotificationService.show(
                title: title,
                body: body,
                deepLink: deepLink,
              );
            }
          }
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Realtime notifications initialization warning: $e');
    }
  }

  void stopListening() {
    try {
      if (_alertsChannel != null) {
        _supabase.removeChannel(_alertsChannel!);
        _alertsChannel = null;
      }
      if (_announcementsChannel != null) {
        _supabase.removeChannel(_announcementsChannel!);
        _announcementsChannel = null;
      }
    } catch (e) {
      debugPrint('Realtime remove channel error: $e');
    }
  }
}

final notificationsRealtimeServiceProvider = Provider<NotificationsRealtimeService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final service = NotificationsRealtimeService(supabase, ref);
  ref.onDispose(() {
    service.stopListening();
  });
  return service;
});

