class BengaliUtils {
  BengaliUtils._();

  static const Map<String, String> _digits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  /// Converts English numbers to Bengali numerals (e.g. 120 -> "১২০")
  static String toBengaliNumerals(dynamic number) {
    if (number == null) return '';
    final str = number.toString();
    return str.split('').map((char) => _digits[char] ?? char).join();
  }

  /// Formats seconds into MM:SS or HH:MM:SS with Bengali digits
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '${toBengaliNumerals(h)}:${toBengaliNumerals(m)}:${toBengaliNumerals(s)}';
    } else {
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '${toBengaliNumerals(m)}:${toBengaliNumerals(s)}';
    }
  }

  /// Formats duration into words: "৪৫ মিনিট" or "১ ঘণ্টা ৩০ মিনিট"
  static String formatDurationWords(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${toBengaliNumerals(totalMinutes)} মিনিট';
    }
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (remainingMinutes == 0) {
      return '${toBengaliNumerals(hours)} ঘণ্টা';
    }
    return '${toBengaliNumerals(hours)} ঘণ্টা ${toBengaliNumerals(remainingMinutes)} মিনিট';
  }
}

