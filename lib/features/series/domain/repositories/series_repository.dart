// Kylos IPTV Player - Series Repository Interface
// Domain layer interface for series data operations.

import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_category.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_info.dart';

/// Result of loading series with pagination support.
class PaginatedSeries {
  const PaginatedSeries({
    required this.series,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.categoryId,
  });

  /// List of series for the current page.
  final List<Series> series;

  /// Current page number (0-indexed).
  final int currentPage;

  /// Total number of pages available.
  final int totalPages;

  /// Total number of series.
  final int totalCount;

  /// Category ID if filtered.
  final String? categoryId;

  /// Whether there are more pages to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether this is an empty result.
  bool get isEmpty => series.isEmpty;

  /// Creates an empty result.
  factory PaginatedSeries.empty() {
    return const PaginatedSeries(
      series: [],
      currentPage: 0,
      totalPages: 0,
      totalCount: 0,
    );
  }

  /// Merges another page of results into this one.
  PaginatedSeries merge(PaginatedSeries other) {
    return PaginatedSeries(
      series: [...series, ...other.series],
      currentPage: other.currentPage,
      totalPages: other.totalPages,
      totalCount: other.totalCount,
      categoryId: categoryId,
    );
  }
}

/// Repository interface for series operations.
///
/// Defines the contract for accessing series data from any source
/// (M3U playlist, Xtream API, local cache, etc.).
abstract class SeriesRepository {
  /// Gets all categories for the active playlist.
  Future<List<SeriesCategory>> getCategories();

  /// Gets a single category by ID.
  Future<SeriesCategory?> getCategory(String id);

  /// Gets series with pagination support.
  ///
  /// [page] - Zero-indexed page number.
  /// [pageSize] - Number of series per page.
  /// [categoryId] - Optional category filter.
  Future<PaginatedSeries> getSeries({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  });

  /// Gets a single series by ID.
  Future<Series?> getSeriesById(String id);

  /// Gets series by a list of IDs.
  Future<List<Series>> getSeriesByIds(List<String> ids);

  /// Searches series by name.
  ///
  /// [query] - Search query string.
  /// [limit] - Maximum number of results.
  Future<List<Series>> searchSeries(String query, {int limit = 50});

  /// Gets favorite series.
  Future<List<Series>> getFavoriteSeries();

  /// Sets a series as favorite.
  Future<void> setFavorite(String seriesId, bool isFavorite);

  /// Refreshes series data from the source.
  Future<void> refresh();

  /// Gets the total count of series.
  Future<int> getSeriesCount();

  /// Gets the total count of series in a category.
  Future<int> getCategorySeriesCount(String categoryId);

  /// Gets detailed info for a single series, including seasons and episodes.
  Future<SeriesInfo> getSeriesInfo(String seriesId);

  /// Gets the stream URL for an episode.
  String getEpisodeStreamUrl(String episodeId, String containerExtension);
}
