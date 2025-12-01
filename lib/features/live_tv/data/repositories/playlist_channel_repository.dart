// Kylos IPTV Player - Playlist Channel Repository
// Real implementation that fetches channels from the active playlist source.

import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/channel_repository.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/infrastructure/m3u/m3u_parser.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_api_client.dart';

/// Real implementation of ChannelRepository that fetches from playlist sources.
class PlaylistChannelRepository implements ChannelRepository {
  PlaylistChannelRepository({
    M3uParser? m3uParser,
    required LocalStorage localStorage,
  })  : _m3uParser = m3uParser ?? M3uParser(),
        _localStorage = localStorage {
    _loadFavoritesFromStorage();
  }

  final M3uParser _m3uParser;
  final LocalStorage _localStorage;

  static const _favoritesKey = 'channel_favorites';

  // Cached data
  List<Channel> _channels = [];
  List<ChannelCategory> _categories = [];
  Set<String> _favorites = {};
  final Set<String> _locked = {};

  // Current playlist source
  PlaylistSource? _currentPlaylist;
  XtreamApiClient? _xtreamClient;

  /// Sets the active playlist source.
  Future<void> setPlaylistSource(PlaylistSource? playlist) async {
    debugPrint('[PlaylistChannelRepository] setPlaylistSource called');
    debugPrint('[PlaylistChannelRepository] playlist: ${playlist?.name}, type: ${playlist?.type}');
    debugPrint('[PlaylistChannelRepository] current: ${_currentPlaylist?.name}');

    if (playlist?.id == _currentPlaylist?.id && _channels.isNotEmpty) {
      debugPrint('[PlaylistChannelRepository] Same playlist with data, skipping');
      return;
    }

    _currentPlaylist = playlist;
    _channels = [];
    _categories = [];

    // Dispose old Xtream client
    _xtreamClient?.dispose();
    _xtreamClient = null;

    if (playlist == null) {
      debugPrint('[PlaylistChannelRepository] No playlist provided');
      return;
    }

    // Create Xtream client if needed
    if (playlist.type == PlaylistType.xtream &&
        playlist.xtreamCredentials != null) {
      debugPrint('[PlaylistChannelRepository] Creating Xtream client');
      _xtreamClient = XtreamApiClient(credentials: playlist.xtreamCredentials!);
    }

    // Load data
    debugPrint('[PlaylistChannelRepository] Calling refresh()');
    await refresh();
    debugPrint('[PlaylistChannelRepository] After refresh: ${_channels.length} channels, ${_categories.length} categories');
  }

  @override
  Future<void> refresh() async {
    debugPrint('[PlaylistChannelRepository] refresh() called');
    if (_currentPlaylist == null) {
      debugPrint('[PlaylistChannelRepository] No current playlist in refresh');
      return;
    }

    debugPrint('[PlaylistChannelRepository] Refreshing playlist type: ${_currentPlaylist!.type}');
    switch (_currentPlaylist!.type) {
      case PlaylistType.m3uUrl:
        await _loadFromM3uUrl();
      case PlaylistType.m3uFile:
        await _loadFromM3uFile();
      case PlaylistType.xtream:
        await _loadFromXtream();
    }
    debugPrint('[PlaylistChannelRepository] refresh() completed');
  }

  Future<void> _loadFromM3uUrl() async {
    final url = _currentPlaylist?.url?.value;
    debugPrint('[PlaylistChannelRepository] _loadFromM3uUrl: $url');
    if (url == null) {
      debugPrint('[PlaylistChannelRepository] M3U URL is null');
      return;
    }

    try {
      debugPrint('[PlaylistChannelRepository] Parsing M3U from URL...');
      final playlist = await _m3uParser.parseFromUrl(url);
      debugPrint('[PlaylistChannelRepository] M3U parsed: ${playlist.entries.length} entries');
      _processM3uPlaylist(playlist);
    } catch (e) {
      debugPrint('[PlaylistChannelRepository] M3U Error: $e');
      throw Exception('Failed to load M3U playlist: $e');
    }
  }

  Future<void> _loadFromM3uFile() async {
    // TODO: Implement file loading when file picker is added
    throw UnimplementedError('M3U file loading not yet implemented');
  }

  Future<void> _loadFromXtream() async {
    debugPrint('[PlaylistChannelRepository] _loadFromXtream');
    if (_xtreamClient == null) {
      debugPrint('[PlaylistChannelRepository] Xtream client is null');
      return;
    }

    try {
      // Load categories
      debugPrint('[PlaylistChannelRepository] Loading Xtream categories...');
      final xtreamCategories = await _xtreamClient!.getLiveCategories();
      debugPrint('[PlaylistChannelRepository] Got ${xtreamCategories.length} categories');
      _categories = xtreamCategories
          .map((c) => ChannelCategory(
                id: c.categoryId,
                name: c.categoryName,
                type: CategoryType.live,
              ))
          .toList();

      // Load all streams
      debugPrint('[PlaylistChannelRepository] Loading Xtream streams...');
      final xtreamStreams = await _xtreamClient!.getLiveStreams();
      debugPrint('[PlaylistChannelRepository] Got ${xtreamStreams.length} streams');
      _channels = xtreamStreams.map((s) {
        final streamUrl =
            _xtreamClient!.buildLiveStreamUrl(s.streamId, extension: 'm3u8');
        return Channel(
          id: s.streamId.toString(),
          name: s.name,
          streamUrl: streamUrl,
          categoryId: s.categoryId,
          categoryName: _getCategoryName(s.categoryId),
          logoUrl: s.streamIcon,
          epgChannelId: s.epgChannelId,
          channelNumber: s.num,
          isFavorite: _favorites.contains(s.streamId.toString()),
          isLocked: _locked.contains(s.streamId.toString()),
        );
      }).toList();

      // Update category counts
      _updateCategoryCounts();
      debugPrint('[PlaylistChannelRepository] Xtream load complete: ${_channels.length} channels');
    } catch (e) {
      debugPrint('[PlaylistChannelRepository] Xtream Error: $e');
      throw Exception('Failed to load from Xtream: $e');
    }
  }

  void _processM3uPlaylist(M3uPlaylist playlist) {
    // Extract categories from groups
    final groupSet = <String>{};
    for (final entry in playlist.entries) {
      if (entry.groupTitle != null && entry.groupTitle!.isNotEmpty) {
        groupSet.add(entry.groupTitle!);
      }
    }

    _categories = groupSet.map((group) {
      return ChannelCategory(
        id: group.toLowerCase().replaceAll(' ', '_'),
        name: group,
        type: CategoryType.live,
      );
    }).toList();

    // Convert entries to channels
    _channels = [];
    var channelNumber = 1;
    for (final entry in playlist.entries) {
      final categoryId = entry.groupTitle?.toLowerCase().replaceAll(' ', '_');
      _channels.add(Channel(
        id: 'ch_$channelNumber',
        name: entry.title,
        streamUrl: entry.url,
        categoryId: categoryId,
        categoryName: entry.groupTitle,
        logoUrl: entry.tvgLogo,
        epgChannelId: entry.tvgId ?? entry.tvgName,
        channelNumber: channelNumber,
        isFavorite: _favorites.contains('ch_$channelNumber'),
        isLocked: _locked.contains('ch_$channelNumber'),
      ));
      channelNumber++;
    }

    _updateCategoryCounts();
  }

  void _updateCategoryCounts() {
    final counts = <String, int>{};
    for (final channel in _channels) {
      if (channel.categoryId != null) {
        counts[channel.categoryId!] = (counts[channel.categoryId!] ?? 0) + 1;
      }
    }

    _categories = _categories.map((cat) {
      return cat.copyWith(channelCount: counts[cat.id] ?? 0);
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
  Future<List<ChannelCategory>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<ChannelCategory?> getCategory(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaginatedChannels> getChannels({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  }) async {
    var filteredChannels = categoryId != null
        ? _channels.where((c) => c.categoryId == categoryId).toList()
        : List<Channel>.from(_channels);

    final totalCount = filteredChannels.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    final pageChannels = startIndex < totalCount
        ? filteredChannels.sublist(startIndex, endIndex)
        : <Channel>[];

    return PaginatedChannels(
      channels: pageChannels,
      currentPage: page,
      totalPages: totalPages > 0 ? totalPages : 1,
      totalCount: totalCount,
      categoryId: categoryId,
    );
  }

  @override
  Future<Channel?> getChannel(String id) async {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Channel>> getChannelsByIds(List<String> ids) async {
    return _channels.where((c) => ids.contains(c.id)).toList();
  }

  @override
  Future<List<Channel>> searchChannels(String query, {int limit = 50}) async {
    final lowerQuery = query.toLowerCase();
    return _channels
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Channel>> getFavoriteChannels() async {
    // Use _favorites Set as source of truth (persisted to storage)
    return _channels.where((c) => _favorites.contains(c.id)).toList();
  }

  /// Returns the count of favorite channels.
  int get favoritesCount => _favorites.length;

  @override
  Future<void> setFavorite(String channelId, bool isFavorite) async {
    if (isFavorite) {
      _favorites.add(channelId);
    } else {
      _favorites.remove(channelId);
    }

    // Update the channel in the list
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      _channels[index] = _channels[index].copyWith(isFavorite: isFavorite);
    }

    // Persist to storage
    await _saveFavoritesToStorage();
  }

  /// Loads favorites from local storage.
  void _loadFavoritesFromStorage() {
    final savedFavorites = _localStorage.getStringList(_favoritesKey);
    if (savedFavorites != null) {
      _favorites = savedFavorites.toSet();
      debugPrint('[PlaylistChannelRepository] Loaded ${_favorites.length} favorites from storage');
    }
  }

  /// Saves favorites to local storage.
  Future<void> _saveFavoritesToStorage() async {
    await _localStorage.setStringList(_favoritesKey, _favorites.toList());
    debugPrint('[PlaylistChannelRepository] Saved ${_favorites.length} favorites to storage');
  }

  @override
  Future<void> setLocked(String channelId, bool isLocked) async {
    if (isLocked) {
      _locked.add(channelId);
    } else {
      _locked.remove(channelId);
    }

    // Update the channel in the list
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      _channels[index] = _channels[index].copyWith(isLocked: isLocked);
    }
  }

  @override
  Future<int> getChannelCount() async {
    return _channels.length;
  }

  @override
  Future<int> getCategoryChannelCount(String categoryId) async {
    return _channels.where((c) => c.categoryId == categoryId).length;
  }

  /// Disposes resources.
  void dispose() {
    _xtreamClient?.dispose();
    _m3uParser.dispose();
  }
}
