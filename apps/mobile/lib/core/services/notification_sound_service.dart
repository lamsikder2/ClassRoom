import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NotificationSoundService {
  NotificationSoundService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNotificationSound() async {
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Play chime from asset
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.wav'));
    } catch (e) {
      debugPrint('Notification sound error: $e');
    }
  }

  static void dispose() {
    _player.dispose();
  }
}

