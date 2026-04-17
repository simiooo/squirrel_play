/// Utility for cleaning and normalizing filenames.
///
/// Provides smart cleaning for display and API search purposes.
/// Implements 10 cleaning rules for metadata matching.
class FilenameCleaner {
  FilenameCleaner._();

  // Regex patterns for cleaning
  // Matches version patterns like: v1.0, 1.0.0, v1.0.0, (v1.0), [1.0.0]
  // Requires either a 'v' prefix OR at least one dot (to avoid matching years like 2077)
  static final RegExp _versionPattern = RegExp(
    r'[\s\(\[]*(?:[vV]\d+|\d+\.\d+)[\w\.]*[\s\)\]]*',
    caseSensitive: false,
  );

  static final RegExp _multipleSpacesPattern = RegExp(r'\s+');

  static final List<RegExp> _commonSuffixPatterns = [
    RegExp(r'\bsetup\b', caseSensitive: false),
    RegExp(r'\binstaller\b', caseSensitive: false),
    RegExp(r'\buninstall\b', caseSensitive: false),
    RegExp(r'\blauncher\b', caseSensitive: false),
    RegExp(r'\bpatch\b', caseSensitive: false),
    RegExp(r'\bupdate\b', caseSensitive: false),
  ];

  static final List<RegExp> _platformSuffixPatterns = [
    RegExp(r'\bwin32\b', caseSensitive: false),
    RegExp(r'\bwin64\b', caseSensitive: false),
    RegExp(r'\bx64\b', caseSensitive: false),
    RegExp(r'\bx86\b', caseSensitive: false),
    RegExp(r'\bwindows\b', caseSensitive: false),
    RegExp(r'\bpc\b', caseSensitive: false),
  ];

  static final List<RegExp> _languageSuffixPatterns = [
    RegExp(r'\ben\b', caseSensitive: false),
    RegExp(r'\beng\b', caseSensitive: false),
    RegExp(r'\benglish\b', caseSensitive: false),
    RegExp(r'\bmulti\b', caseSensitive: false),
  ];

  static final List<RegExp> _editionSuffixPatterns = [
    RegExp(r'\bgoty\b', caseSensitive: false),
    RegExp(r'\bdeluxe\b', caseSensitive: false),
    RegExp(r'\bpremium\b', caseSensitive: false),
    RegExp(r'\bgold\b', caseSensitive: false),
    RegExp(r'\bcomplete\b', caseSensitive: false),
    RegExp(r'\bultimate\b', caseSensitive: false),
  ];

  static final List<RegExp> _prefixPatterns = [
    RegExp(r'^the\s+', caseSensitive: false),
    RegExp(r'^a\s+', caseSensitive: false),
    RegExp(r'^an\s+', caseSensitive: false),
  ];

  /// Cleans a filename for display purposes.
  ///
  /// Removes file extension and common suffixes.
  static String cleanForDisplay(String filename) {
    // Remove extension
    var cleaned = filename;
    final lastDot = cleaned.lastIndexOf('.');
    if (lastDot > 0) {
      cleaned = cleaned.substring(0, lastDot);
    }

    // Replace underscores and hyphens with spaces
    cleaned = cleaned.replaceAll('_', ' ').replaceAll('-', ' ');

    // Trim extra spaces
    cleaned = cleaned.trim();

    return cleaned;
  }

  /// Cleans a filename for API search.
  ///
  /// Applies all 10 cleaning rules:
  /// 1. Remove file extension (.exe)
  /// 2. Replace underscores/hyphens with spaces
  /// 3. Remove version patterns: v1.0, 1.0.0, v1.0.0, (v1.0), [1.0.0]
  /// 4. Remove common suffixes: setup, installer, uninstall, launcher, patch, update
  /// 5. Remove platform suffixes: win32, win64, x64, x86, windows, pc
  /// 6. Remove language suffixes: en, eng, english, multi
  /// 7. Remove edition suffixes: goty, deluxe, premium, gold, complete, ultimate
  /// 8. Remove common prefixes: the, a, an (only if followed by space)
  /// 9. Collapse multiple spaces to single space
  /// 10. Trim leading/trailing whitespace
  static String cleanForSearch(String filename) {
    var cleaned = filename;

    // Rule 1: Remove file extension
    final lastDot = cleaned.lastIndexOf('.');
    if (lastDot > 0) {
      cleaned = cleaned.substring(0, lastDot);
    }

    // Rule 2: Replace underscores/hyphens with spaces
    cleaned = cleaned.replaceAll('_', ' ').replaceAll('-', ' ');

    // Rule 3: Remove version patterns
    cleaned = cleaned.replaceAll(_versionPattern, ' ');

    // Rule 4: Remove common suffixes
    for (final pattern in _commonSuffixPatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Rule 5: Remove platform suffixes
    for (final pattern in _platformSuffixPatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Rule 6: Remove language suffixes
    for (final pattern in _languageSuffixPatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Rule 7: Remove edition suffixes
    for (final pattern in _editionSuffixPatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Rule 8: Remove common prefixes
    for (final pattern in _prefixPatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    // Rule 9: Collapse multiple spaces
    cleaned = cleaned.replaceAll(_multipleSpacesPattern, ' ');

    // Rule 10: Trim whitespace
    cleaned = cleaned.trim();

    return cleaned;
  }

  /// Gets the confidence score for a cleaned filename.
  ///
  /// Returns a value between 0 and 1 indicating how confident
  /// we are that the cleaned name is a valid game title.
  /// Higher is better.
  static double getConfidenceScore(String cleaned) {
    if (cleaned.isEmpty) return 0.0;

    var score = 1.0;

    // Penalize very short names
    if (cleaned.length < 3) {
      score *= 0.5;
    }

    // Penalize names that are just numbers
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      score *= 0.3;
    }

    // Boost names with multiple words (more specific)
    final wordCount = cleaned.split(' ').length;
    if (wordCount >= 2) {
      score *= 1.1;
    }

    // Cap at 1.0
    return score.clamp(0.0, 1.0);
  }
}
