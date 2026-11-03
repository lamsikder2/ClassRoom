import 'package:flutter_test/flutter_test.dart';
import 'package:classroom/core/utils/bengali_utils.dart';
import 'package:classroom/core/utils/drive_utils.dart';
import 'package:classroom/core/utils/error_translator.dart';

void main() {
  group('BengaliUtils tests', () {
    test('converts English digits to Bengali numerals', () {
      expect(BengaliUtils.toBengaliNumerals(12345), '১২৩৪৫');
      expect(BengaliUtils.toBengaliNumerals('0'), '০');
      expect(BengaliUtils.toBengaliNumerals('2026'), '২০২৬');
    });

    test('formats duration into MM:SS with Bengali numerals', () {
      expect(BengaliUtils.formatDuration(65), '০১:০৫');
      expect(BengaliUtils.formatDuration(3665), '০১:০১:০৫');
    });

    test('formats duration into friendly Bengali words', () {
      expect(BengaliUtils.formatDurationWords(25), '২৫ মিনিট');
      expect(BengaliUtils.formatDurationWords(60), '১ ঘণ্টা');
      expect(BengaliUtils.formatDurationWords(90), '১ ঘণ্টা ৩০ মিনিট');
    });
  });

  group('DriveUtils tests', () {
    test('extracts file ID from standard Google Drive URL', () {
      const url = 'https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view?usp=sharing';
      expect(DriveUtils.extractFileId(url), '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms');
    });

    test('extracts file ID from open?id= URL', () {
      const url = 'https://drive.google.com/open?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms';
      expect(DriveUtils.extractFileId(url), '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms');
    });

    test('generates correct direct download URL', () {
      const fileId = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms';
      expect(
        DriveUtils.getDirectDownloadUrl(fileId),
        'https://drive.usercontent.google.com/download?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms&export=download&confirm=t',
      );
    });
  });

  group('ErrorTranslator tests', () {
    test('translates Postgres and RPC error codes into student-friendly Bengali', () {
      expect(
        ErrorTranslator.translate('Exception: EXAM_ENDED'),
        'পরীক্ষার সময়সীমা শেষ হয়ে গেছে।',
      );
      expect(
        ErrorTranslator.translate('Exception: MAX_ATTEMPTS_REACHED'),
        'আপনি এই পরীক্ষার জন্য নির্ধারিত সর্বোচ্চ সুযোগ গ্রহণ করে ফেলেছেন।',
      );
      expect(
        ErrorTranslator.translate('SocketException: OS Error: connection error'),
        'ইন্টারনেট সংযোগ পাওয়া যায়নি। অনুগ্রহ করে আপনার ডাটা বা ওয়াইফাই চেক করুন।',
      );
    });
  });
}
