// Kylos IPTV Player - VOD Movie Entity
// Domain entity representing a video-on-demand movie.

/// Represents a VOD movie from an IPTV playlist.
///
/// Contains all metadata and stream information needed to display
/// and play a movie.
class VodMovie {
  const VodMovie({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.categoryId,
    this.categoryName,
    this.posterUrl,
    this.rating,
    this.releaseDate,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.duration,
    this.containerExtension,
    this.isFavorite = false,
  });

  /// Unique identifier for this movie within the playlist.
  final String id;

  /// Display name of the movie.
  final String name;

  /// URL for the movie stream.
  final String streamUrl;

  /// ID of the category this movie belongs to.
  final String? categoryId;

  /// Display name of the category this movie belongs to.
  final String? categoryName;

  /// URL of the movie poster/cover image.
  final String? posterUrl;

  /// Movie rating (e.g., "7.5").
  final String? rating;

  /// Release date of the movie.
  final String? releaseDate;

  /// Plot/description of the movie.
  final String? plot;

  /// Cast members.
  final String? cast;

  /// Director name.
  final String? director;

  /// Genre of the movie.
  final String? genre;

  /// Duration of the movie.
  final String? duration;

  /// Container extension (e.g., "mp4", "mkv").
  final String? containerExtension;

  /// Whether this movie is in the user's favorites.
  final bool isFavorite;

  /// Creates a copy with the given fields replaced.
  VodMovie copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? categoryId,
    String? categoryName,
    String? posterUrl,
    String? rating,
    String? releaseDate,
    String? plot,
    String? cast,
    String? director,
    String? genre,
    String? duration,
    String? containerExtension,
    bool? isFavorite,
  }) {
    return VodMovie(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      posterUrl: posterUrl ?? this.posterUrl,
      rating: rating ?? this.rating,
      releaseDate: releaseDate ?? this.releaseDate,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      containerExtension: containerExtension ?? this.containerExtension,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VodMovie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VodMovie($id, $name)';
}
