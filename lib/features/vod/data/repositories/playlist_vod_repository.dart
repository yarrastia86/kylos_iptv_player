// Kylos IPTV Player - Playlist VOD Repository
// Real implementation that fetches movies from the active playlist source.

import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_category.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/domain/repositories/vod_repository.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_api_client.dart';

/// Real implementation of VodRepository that fetches from playlist sources.
class PlaylistVodRepository implements VodRepository {
  PlaylistVodRepository({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage {
    _loadFavoritesFromStorage();
  }

  final LocalStorage _localStorage;

  static const _favoritesKey = 'vod_favorites';

  // Cached data
  List<VodMovie> _movies = [];
  List<VodCategory> _categories = [];
  Set<String> _favorites = {};

  // Current playlist source
  PlaylistSource? _currentPlaylist;
  XtreamApiClient? _xtreamClient;

  /// Sets the active playlist source.
  Future<void> setPlaylistSource(PlaylistSource? playlist) async {
    debugPrint('[PlaylistVodRepository] setPlaylistSource called');
    debugPrint('[PlaylistVodRepository] playlist: ${playlist?.name}, type: ${playlist?.type}');
    debugPrint('[PlaylistVodRepository] current: ${_currentPlaylist?.name}');

    if (playlist?.id == _currentPlaylist?.id && _movies.isNotEmpty) {
      debugPrint('[PlaylistVodRepository] Same playlist with data, skipping');
      return;
    }

    _currentPlaylist = playlist;
    _movies = [];
    _categories = [];

    // Dispose old Xtream client
    _xtreamClient?.dispose();
    _xtreamClient = null;

    if (playlist == null) {
      debugPrint('[PlaylistVodRepository] No playlist provided');
      return;
    }

    // Create Xtream client if needed
    if (playlist.type == PlaylistType.xtream &&
        playlist.xtreamCredentials != null) {
      debugPrint('[PlaylistVodRepository] Creating Xtream client');
      _xtreamClient = XtreamApiClient(credentials: playlist.xtreamCredentials!);
    }

    // Load data
    debugPrint('[PlaylistVodRepository] Calling refresh()');
    await refresh();
    debugPrint('[PlaylistVodRepository] After refresh: ${_movies.length} movies, ${_categories.length} categories');
  }

  @override
  Future<void> refresh() async {
    debugPrint('[PlaylistVodRepository] refresh() called');
    if (_currentPlaylist == null) {
      debugPrint('[PlaylistVodRepository] No current playlist in refresh');
      return;
    }

    debugPrint('[PlaylistVodRepository] Refreshing playlist type: ${_currentPlaylist!.type}');
    switch (_currentPlaylist!.type) {
      case PlaylistType.m3uUrl:
        // M3U playlists typically don't separate VOD content
        debugPrint('[PlaylistVodRepository] M3U URL not supported for VOD');
        break;
      case PlaylistType.m3uFile:
        debugPrint('[PlaylistVodRepository] M3U file not supported for VOD');
        break;
      case PlaylistType.xtream:
        await _loadFromXtream();
    }
    debugPrint('[PlaylistVodRepository] refresh() completed');
  }

  Future<void> _loadFromXtream() async {
    debugPrint('[PlaylistVodRepository] _loadFromXtream');
    if (_xtreamClient == null) {
      debugPrint('[PlaylistVodRepository] Xtream client is null');
      return;
    }

    try {
      // Load categories
      debugPrint('[PlaylistVodRepository] Loading Xtream VOD categories...');
      final xtreamCategories = await _xtreamClient!.getVodCategories();
      debugPrint('[PlaylistVodRepository] Got ${xtreamCategories.length} categories');
      _categories = xtreamCategories
          .map((c) => VodCategory(
                id: c.categoryId,
                name: c.categoryName,
              ))
          .toList();

      // Load all VOD streams
      debugPrint('[PlaylistVodRepository] Loading Xtream VOD streams...');
      final xtreamStreams = await _xtreamClient!.getVodStreams();
      debugPrint('[PlaylistVodRepository] Got ${xtreamStreams.length} streams');
      _movies = xtreamStreams.map((s) {
        final streamUrl = _xtreamClient!.buildVodStreamUrl(
          s.streamId,
          s.containerExtension ?? 'mp4',
        );
        return VodMovie(
          id: s.streamId.toString(),
          name: s.name,
          streamUrl: streamUrl,
          categoryId: s.categoryId,
          categoryName: _getCategoryName(s.categoryId),
          posterUrl: s.streamIcon,
          rating: s.rating,
          releaseDate: s.releaseDate,
          plot: s.plot,
          cast: s.cast,
          director: s.director,
          genre: s.genre,
          duration: s.duration,
          containerExtension: s.containerExtension,
          isFavorite: _favorites.contains(s.streamId.toString()),
        );
      }).toList();

      // Update category counts
      _updateCategoryCounts();
      debugPrint('[PlaylistVodRepository] Xtream load complete: ${_movies.length} movies');
    } catch (e) {
      debugPrint('[PlaylistVodRepository] Xtream Error: $e');
      throw Exception('Failed to load from Xtream: $e');
    }
  }

  void _updateCategoryCounts() {
    final counts = <String, int>{};
    for (final movie in _movies) {
      if (movie.categoryId != null) {
        counts[movie.categoryId!] = (counts[movie.categoryId!] ?? 0) + 1;
      }
    }

    _categories = _categories.map((cat) {
      return cat.copyWith(movieCount: counts[cat.id] ?? 0);
    }).toList();
  }

  String? _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<VodCategory>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<VodCategory?> getCategory(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaginatedMovies> getMovies({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  }) async {
    var filteredMovies = categoryId != null
        ? _movies.where((m) => m.categoryId == categoryId).toList()
        : List<VodMovie>.from(_movies);

    final totalCount = filteredMovies.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    final pageMovies = startIndex < totalCount
        ? filteredMovies.sublist(startIndex, endIndex)
        : <VodMovie>[];

    return PaginatedMovies(
      movies: pageMovies,
      currentPage: page,
      totalPages: totalPages > 0 ? totalPages : 1,
      totalCount: totalCount,
      categoryId: categoryId,
    );
  }

  @override
  Future<VodMovie?> getMovie(String id) async {
    try {
      return _movies.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<VodMovie>> getMoviesByIds(List<String> ids) async {
    return _movies.where((m) => ids.contains(m.id)).toList();
  }

  @override
  Future<List<VodMovie>> searchMovies(String query, {int limit = 50}) async {
    final lowerQuery = query.toLowerCase();
    return _movies
        .where((m) => m.name.toLowerCase().contains(lowerQuery))
        .take(limit)
        .toList();
  }

  @override
  Future<List<VodMovie>> getFavoriteMovies() async {
    // Use _favorites Set as source of truth (persisted to storage)
    return _movies.where((m) => _favorites.contains(m.id)).toList();
  }

  /// Returns the count of favorite movies.
  int get favoritesCount => _favorites.length;

  @override
  Future<void> setFavorite(String movieId, bool isFavorite) async {
    if (isFavorite) {
      _favorites.add(movieId);
    } else {
      _favorites.remove(movieId);
    }

    // Update the movie in the list
    final index = _movies.indexWhere((m) => m.id == movieId);
    if (index != -1) {
      _movies[index] = _movies[index].copyWith(isFavorite: isFavorite);
    }

    // Persist to storage
    await _saveFavoritesToStorage();
  }

  /// Loads favorites from local storage.
  void _loadFavoritesFromStorage() {
    final savedFavorites = _localStorage.getStringList(_favoritesKey);
    if (savedFavorites != null) {
      _favorites = savedFavorites.toSet();
      debugPrint('[PlaylistVodRepository] Loaded ${_favorites.length} favorites from storage');
    }
  }

  /// Saves favorites to local storage.
  Future<void> _saveFavoritesToStorage() async {
    await _localStorage.setStringList(_favoritesKey, _favorites.toList());
    debugPrint('[PlaylistVodRepository] Saved ${_favorites.length} favorites to storage');
  }

  @override
  Future<int> getMovieCount() async {
    return _movies.length;
  }

  @override
  Future<int> getCategoryMovieCount(String categoryId) async {
    return _movies.where((m) => m.categoryId == categoryId).length;
  }

  /// Disposes resources.
  void dispose() {
    _xtreamClient?.dispose();
  }
}
