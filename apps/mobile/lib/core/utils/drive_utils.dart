class DriveUtils {
  DriveUtils._();

  static final RegExp _driveRegex = RegExp(
    r'(?:https?:\/\/)?(?:drive\.google\.com\/(?:file\/d\/|open\?id=|uc\?id=)|docs\.google\.com\/file\/d\/)([a-zA-Z0-9_-]{25,})',
    caseSensitive: false,
  );

  /// Extracts Google Drive 25-50 char file ID from various Drive URL formats
  static String? extractFileId(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final trimmed = input.trim();
    final match = _driveRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    // If user provided a raw file ID
    if (RegExp(r'^[a-zA-Z0-9_-]{25,}$').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  /// Direct binary stream download URL for Google Drive files
  static String getDirectDownloadUrl(String fileId) {
    return 'https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t';
  }

  /// Webview embed preview URL
  static String getPreviewEmbedUrl(String fileId) {
    return 'https://drive.google.com/file/d/$fileId/preview';
  }
}

