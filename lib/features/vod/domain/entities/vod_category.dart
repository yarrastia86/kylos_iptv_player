// Kylos IPTV Player - VOD Category Entity

/// Represents a VOD (movie) category.
class VodCategory {
  const VodCategory({
    required this.id,
    required this.name,
    this.movieCount = 0,
    this.sortOrder = 0,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final int movieCount;
  final int sortOrder;
  final bool isFavorite;

  VodCategory copyWith({
    String? id,
    String? name,
    int? movieCount,
    int? sortOrder,
    bool? isFavorite,
  }) {
    return VodCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      movieCount: movieCount ?? this.movieCount,
      sortOrder: sortOrder ?? this.sortOrder,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VodCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
