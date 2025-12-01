// Kylos IPTV Player - Channel Entity
// Domain entity representing a live TV channel.

/// Represents a live TV channel from an IPTV playlist.
///
/// Contains all metadata and stream information needed to display
/// and play a channel.
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.categoryId,
    this.categoryName,
    this.logoUrl,
    this.epgChannelId,
    this.channelNumber,
    this.isFavorite = false,
    this.isLocked = false,
  });

  /// Unique identifier for this channel within the playlist.
  final String id;

  /// Display name of the channel.
  final String name;

  /// URL for the live stream.
  final String streamUrl;

  /// ID of the category this channel belongs to.
  final String? categoryId;

  /// Display name of the category this channel belongs to.
  final String? categoryName;

  /// URL of the channel logo image.
  final String? logoUrl;

  /// EPG channel ID for matching program guide data.
  final String? epgChannelId;

  /// Channel number for numeric tuning.
  final int? channelNumber;

  /// Whether this channel is in the user's favorites.
  final bool isFavorite;

  /// Whether this channel is locked by parental controls.
  final bool isLocked;

  /// Creates a copy with the given fields replaced.
  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? categoryId,
    String? categoryName,
    String? logoUrl,
    String? epgChannelId,
    int? channelNumber,
    bool? isFavorite,
    bool? isLocked,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      logoUrl: logoUrl ?? this.logoUrl,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      channelNumber: channelNumber ?? this.channelNumber,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Channel($id, $name)';
}
