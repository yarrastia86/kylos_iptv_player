// Kylos IPTV Player - Playlist Series Repository
// Real implementation that fetches series from the active playlist source.

import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_category.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_info.dart';
import 'package:kylos_iptv_player/features/series/domain/repositories/series_repository.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_api_client.dart';

/// Real implementation of SeriesRepository that fetches from playlist sources.
class PlaylistSeriesRepository implements SeriesRepository {
  PlaylistSeriesRepository({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage {
    _loadFavoritesFromStorage();
  }

  final LocalStorage _localStorage;

  static const _favoritesKey = 'series_favorites';

  // Cached data
  List<Series> _seriesList = [];
  List<SeriesCategory> _categories = [];
  Set<String> _favorites = {};

  // Current playlist source
  PlaylistSource? _currentPlaylist;
  XtreamApiClient? _xtreamClient;

  /// Sets the active playlist source.
  Future<void> setPlaylistSource(PlaylistSource? playlist) async {
    debugPrint('[PlaylistSeriesRepository] setPlaylistSource called');
    debugPrint('[PlaylistSeriesRepository] playlist: ${playlist?.name}, type: ${playlist?.type}');
    debugPrint('[PlaylistSeriesRepository] current: ${_currentPlaylist?.name}');

    if (playlist?.id == _currentPlaylist?.id && _seriesList.isNotEmpty) {
      debugPrint('[PlaylistSeriesRepository] Same playlist with data, skipping');
      return;
    }

    _currentPlaylist = playlist;
    _seriesList = [];
    _categories = [];

    // Dispose old Xtream client
    _xtreamClient?.dispose();
    _xtreamClient = null;

    if (playlist == null) {
      debugPrint('[PlaylistSeriesRepository] No playlist provided');
      return;
    }

    // Create Xtream client if needed
    if (playlist.type == PlaylistType.xtream &&
        playlist.xtreamCredentials != null) {
      debugPrint('[PlaylistSeriesRepository] Creating Xtream client');
      _xtreamClient = XtreamApiClient(credentials: playlist.xtreamCredentials!);
    }

    // Load data
    debugPrint('[PlaylistSeriesRepository] Calling refresh()');
    await refresh();
    debugPrint('[PlaylistSeriesRepository] After refresh: ${_seriesList.length} series, ${_categories.length} categories');
  }

  @override
  Future<void> refresh() async {
    debugPrint('[PlaylistSeriesRepository] refresh() called');
    if (_currentPlaylist == null) {
      debugPrint('[PlaylistSeriesRepository] No current playlist in refresh');
      return;
    }

    debugPrint('[PlaylistSeriesRepository] Refreshing playlist type: ${_currentPlaylist!.type}');
    switch (_currentPlaylist!.type) {
      case PlaylistType.m3uUrl:
        // M3U playlists typically don't separate series content
        debugPrint('[PlaylistSeriesRepository] M3U URL not supported for Series');
        break;
      case PlaylistType.m3uFile:
        debugPrint('[PlaylistSeriesRepository] M3U file not supported for Series');
        break;
      case PlaylistType.xtream:
        await _loadFromXtream();
    }
    debugPrint('[PlaylistSeriesRepository] refresh() completed');
  }

  Future<void> _loadFromXtream() async {
    debugPrint('[PlaylistSeriesRepository] _loadFromXtream');
    if (_xtreamClient == null) {
      debugPrint('[PlaylistSeriesRepository] Xtream client is null');
      return;
    }

    try {
      // Load categories
      debugPrint('[PlaylistSeriesRepository] Loading Xtream series categories...');
      final xtreamCategories = await _xtreamClient!.getSeriesCategories();
      debugPrint('[PlaylistSeriesRepository] Got ${xtreamCategories.length} categories');
      _categories = xtreamCategories
          .map((c) => SeriesCategory(
                id: c.categoryId,
                name: c.categoryName,
              ))
          .toList();

      // Load all series
      debugPrint('[PlaylistSeriesRepository] Loading Xtream series...');
      final xtreamSeries = await _xtreamClient!.getSeries();
      debugPrint('[PlaylistSeriesRepository] Got ${xtreamSeries.length} series');
      _seriesList = xtreamSeries.map((s) {
        return Series(
          id: s.seriesId.toString(),
          name: s.name,
          categoryId: s.categoryId,
          categoryName: _getCategoryName(s.categoryId),
          coverUrl: s.cover,
          rating: s.rating,
          releaseDate: s.releaseDate,
          plot: s.plot,
          cast: s.cast,
          director: s.director,
          genre: s.genre,
          lastModified: s.lastModified,
          isFavorite: _favorites.contains(s.seriesId.toString()),
        );
      }).toList();

      // Update category counts
      _updateCategoryCounts();
      debugPrint('[PlaylistSeriesRepository] Xtream load complete: ${_seriesList.length} series');
    } catch (e) {
      debugPrint('[PlaylistSeriesRepository] Xtream Error: $e');
      throw Exception('Failed to load from Xtream: $e');
    }
  }

  void _updateCategoryCounts() {
    final counts = <String, int>{};
    for (final series in _seriesList) {
      if (series.categoryId != null) {
        counts[series.categoryId!] = (counts[series.categoryId!] ?? 0) + 1;
      }
    }

    _categories = _categories.map((cat) {
      return cat.copyWith(seriesCount: counts[cat.id] ?? 0);
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
  Future<List<SeriesCategory>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<SeriesCategory?> getCategory(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaginatedSeries> getSeries({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  }) async {
    var filteredSeries = categoryId != null
        ? _seriesList.where((s) => s.categoryId == categoryId).toList()
        : List<Series>.from(_seriesList);

    final totalCount = filteredSeries.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    final pageSeries = startIndex < totalCount
        ? filteredSeries.sublist(startIndex, endIndex)
        : <Series>[];

    return PaginatedSeries(
      series: pageSeries,
      currentPage: page,
      totalPages: totalPages > 0 ? totalPages : 1,
      totalCount: totalCount,
      categoryId: categoryId,
    );
  }

  @override
  Future<Series?> getSeriesById(String id) async {
    try {
      return _seriesList.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Series>> getSeriesByIds(List<String> ids) async {
    return _seriesList.where((s) => ids.contains(s.id)).toList();
  }

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 50}) async {
    final lowerQuery = query.toLowerCase();
    return _seriesList
        .where((s) => s.name.toLowerCase().contains(lowerQuery))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Series>> getFavoriteSeries() async {
    // Use _favorites Set as source of truth (persisted to storage)
    return _seriesList.where((s) => _favorites.contains(s.id)).toList();
  }

  /// Returns the count of favorite series.
  int get favoritesCount => _favorites.length;

  @override
  Future<void> setFavorite(String seriesId, bool isFavorite) async {
    if (isFavorite) {
      _favorites.add(seriesId);
    } else {
      _favorites.remove(seriesId);
    }

    // Update the series in the list
    final index = _seriesList.indexWhere((s) => s.id == seriesId);
    if (index != -1) {
      _seriesList[index] = _seriesList[index].copyWith(isFavorite: isFavorite);
    }

    // Persist to storage
    await _saveFavoritesToStorage();
  }

  /// Loads favorites from local storage.
  void _loadFavoritesFromStorage() {
    final savedFavorites = _localStorage.getStringList(_favoritesKey);
    if (savedFavorites != null) {
      _favorites = savedFavorites.toSet();
      debugPrint('[PlaylistSeriesRepository] Loaded ${_favorites.length} favorites from storage');
    }
  }

  /// Saves favorites to local storage.
  Future<void> _saveFavoritesToStorage() async {
    await _localStorage.setStringList(_favoritesKey, _favorites.toList());
    debugPrint('[PlaylistSeriesRepository] Saved ${_favorites.length} favorites to storage');
  }

  @override
  Future<int> getSeriesCount() async {
    return _seriesList.length;
  }

  @override
  Future<int> getCategorySeriesCount(String categoryId) async {
    return _seriesList.where((s) => s.categoryId == categoryId).length;
  }

  @override
  Future<SeriesInfo> getSeriesInfo(String seriesId) async {
    if (_xtreamClient == null) {
      throw Exception('Xtream client not initialized');
    }
    final seriesIdInt = int.tryParse(seriesId);
    if (seriesIdInt == null) {
      throw Exception('Invalid series ID: $seriesId');
    }
    final response = await _xtreamClient!.getSeriesInfo(seriesIdInt);
    return SeriesInfo.fromJson(response);
  }

  @override
  String getEpisodeStreamUrl(String episodeId, String containerExtension) {
    if (_xtreamClient == null) {
      throw Exception('Xtream client not initialized');
    }
    final episodeIdInt = int.tryParse(episodeId);
    if (episodeIdInt == null) {
      throw Exception('Invalid episode ID: $episodeId');
    }
    return _xtreamClient!.buildSeriesStreamUrl(episodeIdInt, containerExtension);
  }

  /// Disposes resources.
  void dispose() {
    _xtreamClient?.dispose();
  }
}
