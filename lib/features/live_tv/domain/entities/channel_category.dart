// Kylos IPTV Player - Channel Category Entity
// Domain entity representing a channel category/group.

/// Type of content within a category.
enum CategoryType {
  /// Live TV channels.
  live,

  /// Video on demand (movies).
  vod,

  /// TV series.
  series,
}

/// Represents a category/group of channels.
///
/// Categories organize channels into logical groups like "Sports",
/// "News", "Entertainment", etc.
class ChannelCategory {
  const ChannelCategory({
    required this.id,
    required this.name,
    this.type = CategoryType.live,
    this.parentId,
    this.channelCount = 0,
    this.sortOrder = 0,
    this.isHidden = false,
    this.isFavorite = false,
  });

  /// Unique identifier for this category.
  final String id;

  /// Display name of the category.
  final String name;

  /// Type of content in this category.
  final CategoryType type;

  /// Parent category ID for nested categories.
  final String? parentId;

  /// Number of channels in this category.
  final int channelCount;

  /// Sort order for display.
  final int sortOrder;

  /// Whether this category is hidden by the user.
  final bool isHidden;

  /// Whether this category is marked as favorite.
  final bool isFavorite;

  /// Whether this is a top-level category.
  bool get isTopLevel => parentId == null;

  /// Creates a copy with the given fields replaced.
  ChannelCategory copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? parentId,
    int? channelCount,
    int? sortOrder,
    bool? isHidden,
    bool? isFavorite,
  }) {
    return ChannelCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      channelCount: channelCount ?? this.channelCount,
      sortOrder: sortOrder ?? this.sortOrder,
      isHidden: isHidden ?? this.isHidden,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChannelCategory($id, $name)';
}
