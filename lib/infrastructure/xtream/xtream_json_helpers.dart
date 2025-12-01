// Kylos IPTV Player - Xtream JSON Helpers
// Helper extension for parsing Xtream API JSON responses safely.

/// Extension for safe JSON value extraction.
/// Xtream API returns inconsistent types (int as string, null values, etc.)
extension XtreamJsonX on Map<String, dynamic> {
  /// Gets a string value, converting from any type if needed.
  String str(String key, [String defaultValue = '']) =>
      this[key]?.toString() ?? defaultValue;

  /// Gets a nullable string value.
  String? strOrNull(String key) => this[key]?.toString();

  /// Gets an int value, parsing from string if needed.
  int integer(String key, [int defaultValue = 0]) =>
      int.tryParse(this[key]?.toString() ?? '') ?? defaultValue;

  /// Gets a nullable int value.
  int? intOrNull(String key) => int.tryParse(this[key]?.toString() ?? '');

  /// Gets a double value, parsing from string if needed.
  double decimal(String key, [double defaultValue = 0.0]) =>
      double.tryParse(this[key]?.toString() ?? '') ?? defaultValue;

  /// Gets a bool value, handling '0'/'1' strings.
  bool boolean(String key, [bool defaultValue = false]) {
    final value = this[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final str = value.toString().toLowerCase();
    return str == '1' || str == 'true';
  }
}
