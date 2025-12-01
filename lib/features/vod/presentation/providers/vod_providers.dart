// Kylos IPTV Player - VOD Providers
// Riverpod providers for VOD (movie) state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/vod/data/repositories/playlist_vod_repository.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_category.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/domain/repositories/vod_repository.dart';

/// State for the VOD list (categories view).
class VodListState {
  const VodListState({
    this.categories = const [],
    this.totalCount = 0,
    this.allMoviesCount = 0,
    this.favoritesCount = 0,
    this.isLoading = false,
    this.error,
  });

  /// Available categories.
  final List<VodCategory> categories;

  /// Total movie count for current filter.
  final int totalCount;

  /// Total count of ALL movies (not affected by category filter).
  final int allMoviesCount;

  /// Total count of favorite movies (from storage).
  final int favoritesCount;

  /// Whether initial load is in progress.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  VodListState copyWith({
    List<VodCategory>? categories,
    int? totalCount,
    int? allMoviesCount,
    int? favoritesCount,
    bool? isLoading,
    String? error,
  }) {
    return VodListState(
      categories: categories ?? this.categories,
      totalCount: totalCount ?? this.totalCount,
      allMoviesCount: allMoviesCount ?? this.allMoviesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for VOD categories.
class VodListNotifier extends StateNotifier<VodListState> {
  VodListNotifier({
    required this.playlistVodRepository,
    required this.ref,
  }) : super(const VodListState());

  final PlaylistVodRepository playlistVodRepository;
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
      await playlistVodRepository.setPlaylistSource(activePlaylist);

      // Load categories
      final categories = await playlistVodRepository.getCategories();

      // Get total movie count
      final totalCount = await playlistVodRepository.getMovieCount();

      state = state.copyWith(
        categories: categories,
        totalCount: totalCount,
        allMoviesCount: totalCount,
        favoritesCount: playlistVodRepository.favoritesCount,
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
      await playlistVodRepository.setPlaylistSource(null);
      await playlistVodRepository.setPlaylistSource(activePlaylist);

      // Load categories
      final categories = await playlistVodRepository.getCategories();
      final totalCount = await playlistVodRepository.getMovieCount();

      state = state.copyWith(
        categories: categories,
        totalCount: totalCount,
        allMoviesCount: totalCount,
        favoritesCount: playlistVodRepository.favoritesCount,
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

/// State for the movie list (movies in a category).
class MovieListState {
  const MovieListState({
    this.movies = const [],
    this.selectedCategoryId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalCount = 0,
    this.allMoviesCount = 0,
    this.favoritesCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// List of loaded movies.
  final List<VodMovie> movies;

  /// Currently selected category filter.
  final String? selectedCategoryId;

  /// Current page number.
  final int currentPage;

  /// Total pages available.
  final int totalPages;

  /// Total movie count for current filter.
  final int totalCount;

  /// Total count of ALL movies (not affected by category filter).
  final int allMoviesCount;

  /// Total count of favorite movies (from storage).
  final int favoritesCount;

  /// Whether initial load is in progress.
  final bool isLoading;

  /// Whether loading more movies.
  final bool isLoadingMore;

  /// Error message if loading failed.
  final String? error;

  /// Whether there are more movies to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether movies are available.
  bool get hasMovies => movies.isNotEmpty;

  /// Creates a loading state.
  factory MovieListState.loading() {
    return const MovieListState(isLoading: true);
  }

  /// Creates a copy with the given fields replaced.
  MovieListState copyWith({
    List<VodMovie>? movies,
    String? selectedCategoryId,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    int? allMoviesCount,
    int? favoritesCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return MovieListState(
      movies: movies ?? this.movies,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      allMoviesCount: allMoviesCount ?? this.allMoviesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Notifier for the movie list.
class MovieListNotifier extends StateNotifier<MovieListState> {
  MovieListNotifier({
    required this.playlistVodRepository,
    required this.ref,
  }) : super(const MovieListState());

  final PlaylistVodRepository playlistVodRepository;
  final Ref ref;

  static const _pageSize = 50;

  /// Loads movies for the active playlist.
  Future<void> loadMovies() async {
    // Check if there's an active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      state = state.copyWith(movies: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Set the playlist source on the repository (will refresh data if changed)
      await playlistVodRepository.setPlaylistSource(activePlaylist);

      // Load first page of movies (no filter to get total count)
      final result = await playlistVodRepository.getMovies(
        page: 0,
        pageSize: _pageSize,
        categoryId: null, // No filter to get ALL movies count
      );

      state = state.copyWith(
        movies: result.movies,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        allMoviesCount: result.totalCount, // Store total count of ALL movies
        favoritesCount: playlistVodRepository.favoritesCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load movies: $e',
      );
    }
  }

  /// Loads the next page of movies.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    // No pagination for favorites - all are loaded at once
    if (state.selectedCategoryId == 'favorites') return;

    state = state.copyWith(isLoadingMore: true);

    try {
      // Handle "all" category as null (no filter)
      final effectiveCategoryId =
          state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;

      final result = await playlistVodRepository.getMovies(
        page: state.currentPage + 1,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        movies: [...state.movies, ...result.movies],
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Filters movies by category.
  Future<void> selectCategory(String? categoryId) async {
    if (categoryId == state.selectedCategoryId) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      movies: [],
      currentPage: 0,
      isLoading: true,
    );

    try {
      // Handle special "favorites" category
      if (categoryId == 'favorites') {
        final favorites = await playlistVodRepository.getFavoriteMovies();
        state = state.copyWith(
          movies: favorites,
          currentPage: 0,
          totalPages: 1,
          totalCount: favorites.length,
          isLoading: false,
        );
        return;
      }

      // Handle "all" category as null (no filter)
      final effectiveCategoryId = categoryId == 'all' ? null : categoryId;

      final result = await playlistVodRepository.getMovies(
        page: 0,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        movies: result.movies,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to filter movies: $e',
      );
    }
  }

  /// Toggles favorite status for a movie.
  Future<void> toggleFavorite(String movieId) async {
    final movieIndex = state.movies.indexWhere((m) => m.id == movieId);
    if (movieIndex == -1) return;

    final movie = state.movies[movieIndex];
    final newFavorite = !movie.isFavorite;
    final isViewingFavorites = state.selectedCategoryId == 'favorites';

    // Optimistic update
    List<VodMovie> updatedMovies;
    if (isViewingFavorites && !newFavorite) {
      // Remove movie from list when unfavoriting while viewing favorites
      updatedMovies = [...state.movies];
      updatedMovies.removeAt(movieIndex);
    } else {
      updatedMovies = [...state.movies];
      updatedMovies[movieIndex] = movie.copyWith(isFavorite: newFavorite);
    }

    final newFavoritesCount = state.favoritesCount + (newFavorite ? 1 : -1);
    state = state.copyWith(
      movies: updatedMovies,
      favoritesCount: newFavoritesCount,
      totalCount: isViewingFavorites ? updatedMovies.length : state.totalCount,
    );

    try {
      await playlistVodRepository.setFavorite(movieId, newFavorite);
    } catch (e) {
      // Revert on error
      if (isViewingFavorites && !newFavorite) {
        // Re-insert movie at original position
        updatedMovies.insert(movieIndex, movie);
      } else {
        updatedMovies[movieIndex] = movie;
      }
      state = state.copyWith(
        movies: updatedMovies,
        favoritesCount: state.favoritesCount + (newFavorite ? -1 : 1),
        totalCount: isViewingFavorites ? updatedMovies.length : state.totalCount,
      );
    }
  }

  /// Refreshes movie data from source.
  Future<void> refresh() async {
    // Get the active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Force refresh by clearing and reloading
      await playlistVodRepository.setPlaylistSource(null);
      await playlistVodRepository.setPlaylistSource(activePlaylist);

      // Handle "all" category as null (no filter)
      final effectiveCategoryId =
          state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;

      final result = await playlistVodRepository.getMovies(
        page: 0,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        movies: result.movies,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh movies: $e',
      );
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the VOD list notifier (categories view).
final vodListNotifierProvider =
    StateNotifierProvider<VodListNotifier, VodListState>((ref) {
  final playlistVodRepository = ref.watch(playlistVodRepositoryProvider);
  return VodListNotifier(
    playlistVodRepository: playlistVodRepository,
    ref: ref,
  );
});

/// Provider for the movie list notifier.
final movieListNotifierProvider =
    StateNotifierProvider<MovieListNotifier, MovieListState>((ref) {
  final playlistVodRepository = ref.watch(playlistVodRepositoryProvider);
  return MovieListNotifier(
    playlistVodRepository: playlistVodRepository,
    ref: ref,
  );
});

/// Placeholder for the playlist VOD repository provider - should be overridden.
/// This provides access to the concrete implementation with setPlaylistSource().
final playlistVodRepositoryProvider =
    Provider<PlaylistVodRepository>((ref) {
  throw UnimplementedError(
    'playlistVodRepositoryProvider must be overridden with an implementation',
  );
});

/// Provider for the base VOD repository interface.
/// Delegates to playlistVodRepositoryProvider.
final vodRepositoryProvider = Provider<VodRepository>((ref) {
  return ref.watch(playlistVodRepositoryProvider);
});

/// Provider to search movies.
final movieSearchProvider =
    FutureProvider.family<List<VodMovie>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repository = ref.watch(vodRepositoryProvider);
  return repository.searchMovies(query);
});

/// Provider for favorite movies.
final favoriteMoviesProvider = FutureProvider<List<VodMovie>>((ref) async {
  final repository = ref.watch(vodRepositoryProvider);
  return repository.getFavoriteMovies();
});
