// Kylos IPTV Player - Playlist URL Value Object
// Value object for validated playlist URLs.

/// Result of URL validation.
sealed class PlaylistUrlValidation {
  const PlaylistUrlValidation();
}

/// URL is valid.
class PlaylistUrlValid extends PlaylistUrlValidation {
  const PlaylistUrlValid();
}

/// URL is invalid with a reason.
class PlaylistUrlInvalid extends PlaylistUrlValidation {
  const PlaylistUrlInvalid(this.reason);
  final String reason;
}

/// Value object representing a validated playlist URL.
///
/// Ensures the URL is properly formatted and uses a supported protocol.
/// Immutable and equality is based on the normalized URL string.
class PlaylistUrl {
  PlaylistUrl._({
    required this.value,
    required this.protocol,
  });

  /// The normalized URL string.
  final String value;

  /// The URL protocol (http or https).
  final String protocol;

  /// Creates a PlaylistUrl from a string, returning null if invalid.
  static PlaylistUrl? tryParse(String input) {
    final validation = validate(input);
    if (validation is PlaylistUrlInvalid) {
      return null;
    }

    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    return PlaylistUrl._(
      value: trimmed,
      protocol: uri.scheme,
    );
  }

  /// Creates a PlaylistUrl from a string, throwing if invalid.
  factory PlaylistUrl.parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Invalid playlist URL: $input');
    }
    return result;
  }

  /// Validates a URL string and returns the validation result.
  static PlaylistUrlValidation validate(String input) {
    if (input.isEmpty) {
      return const PlaylistUrlInvalid('URL cannot be empty');
    }

    final trimmed = input.trim();

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return const PlaylistUrlInvalid(
        'URL must start with http:// or https://',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return const PlaylistUrlInvalid('Invalid URL format');
    }

    if (uri.host.isEmpty) {
      return const PlaylistUrlInvalid('URL must have a valid host');
    }

    return const PlaylistUrlValid();
  }

  /// Whether this URL uses HTTPS.
  bool get isSecure => protocol == 'https';

  /// Gets the host portion of the URL.
  String get host => Uri.parse(value).host;

  /// Gets the port, or null if using default port.
  int? get port {
    final uri = Uri.parse(value);
    return uri.hasPort ? uri.port : null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistUrl &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
