// Kylos IPTV Player - Series Providers
// Riverpod providers for series state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/series/data/repositories/playlist_series_repository.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_category.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_info.dart';
import 'package:kylos_iptv_player/features/series/domain/repositories/series_repository.dart';

/// State for the series list (categories view).
class SeriesListState {
  const SeriesListState({
    this.categories = const [],
    this.totalCount = 0,
    this.allSeriesCount = 0,
    this.favoritesCount = 0,
    this.isLoading = false,
    this.error,
  });

  /// Available categories.
  final List<SeriesCategory> categories;

  /// Total series count for current filter.
  final int totalCount;

  /// Total count of ALL series (not affected by category filter).
  final int allSeriesCount;

  /// Total count of favorite series (from storage).
  final int favoritesCount;

  /// Whether initial load is in progress.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  SeriesListState copyWith({
    List<SeriesCategory>? categories,
    int? totalCount,
    int? allSeriesCount,
    int? favoritesCount,
    bool? isLoading,
    String? error,
  }) {
    return SeriesListState(
      categories: categories ?? this.categories,
      totalCount: totalCount ?? this.totalCount,
      allSeriesCount: allSeriesCount ?? this.allSeriesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for series categories.
class SeriesListNotifier extends StateNotifier<SeriesListState> {
  SeriesListNotifier({
    required this.playlistSeriesRepository,
    required this.ref,
  }) : super(const SeriesListState());

  final PlaylistSeriesRepository playlistSeriesRepository;
  final Ref ref;

  /// Loads categories for the active playlist.
  Future<void> loadCategories() async {
    // Check if there's an active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      state = state.copyWith(categories: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Set the playlist source on the repository (will refresh data if changed)
      await playlistSeriesRepository.setPlaylistSource(activePlaylist);

      // Load categories
      final categories = await playlistSeriesRepository.getCategories();

      // Get total series count
      final totalCount = await playlistSeriesRepository.getSeriesCount();

      state = state.copyWith(
        categories: categories,
        totalCount: totalCount,
        allSeriesCount: totalCount,
        favoritesCount: playlistSeriesRepository.favoritesCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load categories: $e',
      );
    }
  }

  /// Refreshes data from source.
  Future<void> refresh() async {
    // Get the active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Force refresh by clearing and reloading
      await playlistSeriesRepository.setPlaylistSource(null);
      await playlistSeriesRepository.setPlaylistSource(activePlaylist);

      // Load categories
      final categories = await playlistSeriesRepository.getCategories();
      final totalCount = await playlistSeriesRepository.getSeriesCount();

      state = state.copyWith(
        categories: categories,
        totalCount: totalCount,
        allSeriesCount: totalCount,
        favoritesCount: playlistSeriesRepository.favoritesCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh: $e',
      );
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State for the series list (series in a category).
class SeriesItemListState {
  const SeriesItemListState({
    this.series = const [],
    this.selectedCategoryId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalCount = 0,
    this.allSeriesCount = 0,
    this.favoritesCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// List of loaded series.
  final List<Series> series;

  /// Currently selected category filter.
  final String? selectedCategoryId;

  /// Current page number.
  final int currentPage;

  /// Total pages available.
  final int totalPages;

  /// Total series count for current filter.
  final int totalCount;

  /// Total count of ALL series (not affected by category filter).
  final int allSeriesCount;

  /// Total count of favorite series (from storage).
  final int favoritesCount;

  /// Whether initial load is in progress.
  final bool isLoading;

  /// Whether loading more series.
  final bool isLoadingMore;

  /// Error message if loading failed.
  final String? error;

  /// Whether there are more series to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether series are available.
  bool get hasSeries => series.isNotEmpty;

  /// Creates a loading state.
  factory SeriesItemListState.loading() {
    return const SeriesItemListState(isLoading: true);
  }

  /// Creates a copy with the given fields replaced.
  SeriesItemListState copyWith({
    List<Series>? series,
    String? selectedCategoryId,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    int? allSeriesCount,
    int? favoritesCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return SeriesItemListState(
      series: series ?? this.series,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      allSeriesCount: allSeriesCount ?? this.allSeriesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Notifier for the series list.
class SeriesItemListNotifier extends StateNotifier<SeriesItemListState> {
  SeriesItemListNotifier({
    required this.playlistSeriesRepository,
    required this.ref,
  }) : super(const SeriesItemListState());

  final PlaylistSeriesRepository playlistSeriesRepository;
  final Ref ref;

  static const _pageSize = 50;

  /// Loads series for the active playlist.
  Future<void> loadSeries() async {
    // Check if there's an active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      state = state.copyWith(series: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Set the playlist source on the repository (will refresh data if changed)
      await playlistSeriesRepository.setPlaylistSource(activePlaylist);

      // Load first page of series (no filter to get total count)
      final result = await playlistSeriesRepository.getSeries(
        page: 0,
        pageSize: _pageSize,
        categoryId: null, // No filter to get ALL series count
      );

      state = state.copyWith(
        series: result.series,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        allSeriesCount: result.totalCount, // Store total count of ALL series
        favoritesCount: playlistSeriesRepository.favoritesCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load series: $e',
      );
    }
  }

  /// Loads the next page of series.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    // No pagination for favorites - all are loaded at once
    if (state.selectedCategoryId == 'favorites') return;

    state = state.copyWith(isLoadingMore: true);

    try {
      // Handle "all" category as null (no filter)
      final effectiveCategoryId =
          state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;

      final result = await playlistSeriesRepository.getSeries(
        page: state.currentPage + 1,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        series: [...state.series, ...result.series],
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Filters series by category.
  Future<void> selectCategory(String? categoryId) async {
    if (categoryId == state.selectedCategoryId) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      series: [],
      currentPage: 0,
      isLoading: true,
    );

    try {
      // Handle special "favorites" category
      if (categoryId == 'favorites') {
        final favorites = await playlistSeriesRepository.getFavoriteSeries();
        state = state.copyWith(
          series: favorites,
          currentPage: 0,
          totalPages: 1,
          totalCount: favorites.length,
          isLoading: false,
        );
        return;
      }

      // Handle "all" category as null (no filter)
      final effectiveCategoryId = categoryId == 'all' ? null : categoryId;

      final result = await playlistSeriesRepository.getSeries(
        page: 0,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        series: result.series,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to filter series: $e',
      );
    }
  }

  /// Toggles favorite status for a series.
  Future<void> toggleFavorite(String seriesId) async {
    final seriesIndex = state.series.indexWhere((s) => s.id == seriesId);
    if (seriesIndex == -1) return;

    final series = state.series[seriesIndex];
    final newFavorite = !series.isFavorite;
    final isViewingFavorites = state.selectedCategoryId == 'favorites';

    // Optimistic update
    List<Series> updatedSeries;
    if (isViewingFavorites && !newFavorite) {
      // Remove series from list when unfavoriting while viewing favorites
      updatedSeries = [...state.series];
      updatedSeries.removeAt(seriesIndex);
    } else {
      updatedSeries = [...state.series];
      updatedSeries[seriesIndex] = series.copyWith(isFavorite: newFavorite);
    }

    final newFavoritesCount = state.favoritesCount + (newFavorite ? 1 : -1);
    state = state.copyWith(
      series: updatedSeries,
      favoritesCount: newFavoritesCount,
      totalCount: isViewingFavorites ? updatedSeries.length : state.totalCount,
    );

    try {
      await playlistSeriesRepository.setFavorite(seriesId, newFavorite);
    } catch (e) {
      // Revert on error
      if (isViewingFavorites && !newFavorite) {
        // Re-insert series at original position
        updatedSeries.insert(seriesIndex, series);
      } else {
        updatedSeries[seriesIndex] = series;
      }
      state = state.copyWith(
        series: updatedSeries,
        favoritesCount: state.favoritesCount + (newFavorite ? -1 : 1),
        totalCount: isViewingFavorites ? updatedSeries.length : state.totalCount,
      );
    }
  }

  /// Refreshes series data from source.
  Future<void> refresh() async {
    // Get the active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Force refresh by clearing and reloading
      await playlistSeriesRepository.setPlaylistSource(null);
      await playlistSeriesRepository.setPlaylistSource(activePlaylist);

      // Handle "all" category as null (no filter)
      final effectiveCategoryId =
          state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;

      final result = await playlistSeriesRepository.getSeries(
        page: 0,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        series: result.series,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh series: $e',
      );
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the series list notifier (categories view).
final seriesListNotifierProvider =
    StateNotifierProvider<SeriesListNotifier, SeriesListState>((ref) {
  final playlistSeriesRepository = ref.watch(playlistSeriesRepositoryProvider);
  return SeriesListNotifier(
    playlistSeriesRepository: playlistSeriesRepository,
    ref: ref,
  );
});

/// Provider for the series item list notifier.
final seriesItemListNotifierProvider =
    StateNotifierProvider<SeriesItemListNotifier, SeriesItemListState>((ref) {
  final playlistSeriesRepository = ref.watch(playlistSeriesRepositoryProvider);
  return SeriesItemListNotifier(
    playlistSeriesRepository: playlistSeriesRepository,
    ref: ref,
  );
});

/// Placeholder for the playlist series repository provider - should be overridden.
/// This provides access to the concrete implementation with setPlaylistSource().
final playlistSeriesRepositoryProvider =
    Provider<PlaylistSeriesRepository>((ref) {
  throw UnimplementedError(
    'playlistSeriesRepositoryProvider must be overridden with an implementation',
  );
});

/// Provider for the base series repository interface.
/// Delegates to playlistSeriesRepositoryProvider.
final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return ref.watch(playlistSeriesRepositoryProvider);
});

/// Provider to search series.
final seriesSearchProvider =
    FutureProvider.family<List<Series>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repository = ref.watch(seriesRepositoryProvider);
  return repository.searchSeries(query);
});

/// Provider for favorite series.
final favoriteSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final repository = ref.watch(seriesRepositoryProvider);
  return repository.getFavoriteSeries();
});

/// Provider for fetching detailed info for a single series.
final seriesInfoProvider =
    FutureProvider.autoDispose.family<SeriesInfo, String>((ref, seriesId) {
  final repository = ref.watch(seriesRepositoryProvider);
  return repository.getSeriesInfo(seriesId);
});
