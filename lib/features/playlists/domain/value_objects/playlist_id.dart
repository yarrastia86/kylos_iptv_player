// Kylos IPTV Player - Playlist ID Value Object
// Value object for playlist identifiers.

/// Value object representing a unique playlist identifier.
///
/// Ensures ID is non-empty and provides type safety for playlist references.
class PlaylistId {
  PlaylistId._(this.value);

  /// The raw ID value.
  final String value;

  /// Creates a PlaylistId from a string, returning null if invalid.
  static PlaylistId? tryParse(String input) {
    if (input.trim().isEmpty) {
      return null;
    }
    return PlaylistId._(input.trim());
  }

  /// Creates a PlaylistId from a string, throwing if invalid.
  factory PlaylistId.parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Invalid playlist ID: $input');
    }
    return result;
  }

  /// Generates a new unique PlaylistId.
  factory PlaylistId.generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return PlaylistId._('playlist_${timestamp}_$random');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
