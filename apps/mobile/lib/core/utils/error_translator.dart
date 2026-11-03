class ErrorTranslator {
  ErrorTranslator._();

  static String translate(dynamic error) {
    final message = error.toString();

    if (message.contains('NOT_AUTHORIZED')) {
      return 'আপনার এই কনটেন্ট বা পরীক্ষাটি দেখার অনুমতি নেই।';
    }
    if (message.contains('EXAM_NOT_FOUND')) {
      return 'পরীক্ষাটি খুঁজে পাওয়া যায়নি।';
    }
    if (message.contains('PREMIUM_REQUIRED')) {
      return 'এই ক্লাস বা পরীক্ষাটি শুধুমাত্র প্রিমিয়াম শিক্ষার্থীদের জন্য।';
    }
    if (message.contains('EXAM_NOT_STARTED')) {
      return 'পরীক্ষাটি এখনো শুরু হয়নি। নির্ধারিত সময়ে আবার চেষ্টা করুন।';
    }
    if (message.contains('EXAM_ENDED')) {
      return 'পরীক্ষার সময়সীমা শেষ হয়ে গেছে।';
    }
    if (message.contains('MAX_ATTEMPTS_REACHED')) {
      return 'আপনি এই পরীক্ষার জন্য নির্ধারিত সর্বোচ্চ সুযোগ গ্রহণ করে ফেলেছেন।';
    }
    if (message.contains('EXAM_HAS_NO_QUESTIONS')) {
      return 'এই পরীক্ষায় এখনো কোনো প্রশ্ন যুক্ত করা হয়নি।';
    }
    if (message.contains('ATTEMPT_CLOSED') || message.contains('TIME_UP')) {
      return 'পরীক্ষার সময় শেষ! আপনার উত্তরসমূহ জমা হয়েছে।';
    }
    if (message.contains('INVALID_OPTION') || message.contains('INVALID_QUESTION')) {
      return 'অবৈধ উত্তর নির্বাচন করা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
    }
    if (message.contains('SocketException') || message.contains('connection error') || message.contains('Failed host lookup')) {
      return 'ইন্টারনেট সংযোগ পাওয়া যায়নি। অনুগ্রহ করে আপনার ডাটা বা ওয়াইফাই চেক করুন।';
    }

    return 'একটি সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
  }
}

