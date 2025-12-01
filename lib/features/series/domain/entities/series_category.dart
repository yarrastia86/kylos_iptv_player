// Kylos IPTV Player - Series Category Entity

/// Represents a TV Series category.
class SeriesCategory {
  const SeriesCategory({
    required this.id,
    required this.name,
    this.seriesCount = 0,
    this.sortOrder = 0,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final int seriesCount;
  final int sortOrder;
  final bool isFavorite;

  SeriesCategory copyWith({
    String? id,
    String? name,
    int? seriesCount,
    int? sortOrder,
    bool? isFavorite,
  }) {
    return SeriesCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      seriesCount: seriesCount ?? this.seriesCount,
      sortOrder: sortOrder ?? this.sortOrder,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
