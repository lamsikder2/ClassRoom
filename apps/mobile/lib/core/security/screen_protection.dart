import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenProtectionService {
  ScreenProtectionService._();

  static const MethodChannel _channel = MethodChannel('classroom/screen_protection');

  static Future<void> enableProtection() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('enableProtection');
      }
    } catch (e) {
      debugPrint('ScreenProtection enable error: $e');
    }
  }

  static Future<void> disableProtection() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('disableProtection');
      }
    } catch (e) {
      debugPrint('ScreenProtection disable error: $e');
    }
  }
}
