// Kylos IPTV Player - VOD Repository Interface
// Domain layer interface for VOD (movie) data operations.

import 'package:kylos_iptv_player/features/vod/domain/entities/vod_category.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';

/// Result of loading movies with pagination support.
class PaginatedMovies {
  const PaginatedMovies({
    required this.movies,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.categoryId,
  });

  /// List of movies for the current page.
  final List<VodMovie> movies;

  /// Current page number (0-indexed).
  final int currentPage;

  /// Total number of pages available.
  final int totalPages;

  /// Total number of movies.
  final int totalCount;

  /// Category ID if filtered.
  final String? categoryId;

  /// Whether there are more pages to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether this is an empty result.
  bool get isEmpty => movies.isEmpty;

  /// Creates an empty result.
  factory PaginatedMovies.empty() {
    return const PaginatedMovies(
      movies: [],
      currentPage: 0,
      totalPages: 0,
      totalCount: 0,
    );
  }

  /// Merges another page of results into this one.
  PaginatedMovies merge(PaginatedMovies other) {
    return PaginatedMovies(
      movies: [...movies, ...other.movies],
      currentPage: other.currentPage,
      totalPages: other.totalPages,
      totalCount: other.totalCount,
      categoryId: categoryId,
    );
  }
}

/// Repository interface for VOD (movie) operations.
///
/// Defines the contract for accessing VOD data from any source
/// (M3U playlist, Xtream API, local cache, etc.).
abstract class VodRepository {
  /// Gets all categories for the active playlist.
  Future<List<VodCategory>> getCategories();

  /// Gets a single category by ID.
  Future<VodCategory?> getCategory(String id);

  /// Gets movies with pagination support.
  ///
  /// [page] - Zero-indexed page number.
  /// [pageSize] - Number of movies per page.
  /// [categoryId] - Optional category filter.
  Future<PaginatedMovies> getMovies({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  });

  /// Gets a single movie by ID.
  Future<VodMovie?> getMovie(String id);

  /// Gets movies by a list of IDs.
  Future<List<VodMovie>> getMoviesByIds(List<String> ids);

  /// Searches movies by name.
  ///
  /// [query] - Search query string.
  /// [limit] - Maximum number of results.
  Future<List<VodMovie>> searchMovies(String query, {int limit = 50});

  /// Gets favorite movies.
  Future<List<VodMovie>> getFavoriteMovies();

  /// Sets a movie as favorite.
  Future<void> setFavorite(String movieId, bool isFavorite);

  /// Refreshes movie data from the source.
  Future<void> refresh();

  /// Gets the total count of movies.
  Future<int> getMovieCount();

  /// Gets the total count of movies in a category.
  Future<int> getCategoryMovieCount(String categoryId);
}
