// Kylos IPTV Player - Mock Channel Repository
// Mock implementation for testing and development.

import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/channel_repository.dart';

/// Mock implementation of ChannelRepository for testing and development.
///
/// This provides sample data without requiring an actual IPTV source.
class MockChannelRepository implements ChannelRepository {
  final List<ChannelCategory> _categories = [
    const ChannelCategory(id: 'news', name: 'News', channelCount: 5),
    const ChannelCategory(id: 'sports', name: 'Sports', channelCount: 4),
    const ChannelCategory(id: 'entertainment', name: 'Entertainment', channelCount: 6),
    const ChannelCategory(id: 'movies', name: 'Movies', channelCount: 3),
    const ChannelCategory(id: 'kids', name: 'Kids', channelCount: 4),
  ];

  final List<Channel> _channels = [
    // News channels
    const Channel(
      id: 'ch1',
      name: 'News 24',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'news',
      channelNumber: 1,
    ),
    const Channel(
      id: 'ch2',
      name: 'World News',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'news',
      channelNumber: 2,
    ),
    const Channel(
      id: 'ch3',
      name: 'Business Today',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'news',
      channelNumber: 3,
    ),
    const Channel(
      id: 'ch4',
      name: 'Tech News',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'news',
      channelNumber: 4,
    ),
    const Channel(
      id: 'ch5',
      name: 'Local News',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'news',
      channelNumber: 5,
    ),

    // Sports channels
    const Channel(
      id: 'ch6',
      name: 'Sports Central',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'sports',
      channelNumber: 10,
    ),
    const Channel(
      id: 'ch7',
      name: 'Football HD',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'sports',
      channelNumber: 11,
    ),
    const Channel(
      id: 'ch8',
      name: 'Basketball TV',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'sports',
      channelNumber: 12,
    ),
    const Channel(
      id: 'ch9',
      name: 'Tennis Network',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'sports',
      channelNumber: 13,
    ),

    // Entertainment channels
    const Channel(
      id: 'ch10',
      name: 'Entertainment Tonight',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 20,
    ),
    const Channel(
      id: 'ch11',
      name: 'Comedy Central',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 21,
    ),
    const Channel(
      id: 'ch12',
      name: 'Drama Plus',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 22,
    ),
    const Channel(
      id: 'ch13',
      name: 'Reality TV',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 23,
    ),
    const Channel(
      id: 'ch14',
      name: 'Music Video',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 24,
    ),
    const Channel(
      id: 'ch15',
      name: 'Talk Shows',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'entertainment',
      channelNumber: 25,
    ),

    // Movie channels
    const Channel(
      id: 'ch16',
      name: 'Movie Max',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'movies',
      channelNumber: 30,
    ),
    const Channel(
      id: 'ch17',
      name: 'Action Cinema',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'movies',
      channelNumber: 31,
    ),
    const Channel(
      id: 'ch18',
      name: 'Classic Films',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'movies',
      channelNumber: 32,
    ),

    // Kids channels
    const Channel(
      id: 'ch19',
      name: 'Kids Zone',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'kids',
      channelNumber: 40,
    ),
    const Channel(
      id: 'ch20',
      name: 'Cartoon Network',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'kids',
      channelNumber: 41,
    ),
    const Channel(
      id: 'ch21',
      name: 'Animation Station',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'kids',
      channelNumber: 42,
    ),
    const Channel(
      id: 'ch22',
      name: 'Learning TV',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      categoryId: 'kids',
      channelNumber: 43,
    ),
  ];

  final Set<String> _favorites = {};
  final Set<String> _locked = {};

  @override
  Future<List<ChannelCategory>> getCategories() async {
    await _simulateDelay();
    return List.from(_categories);
  }

  @override
  Future<ChannelCategory?> getCategory(String id) async {
    await _simulateDelay();
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
    await _simulateDelay();

    var filteredChannels = categoryId != null
        ? _channels.where((c) => c.categoryId == categoryId).toList()
        : List<Channel>.from(_channels);

    // Apply favorites and locked status
    filteredChannels = filteredChannels.map((c) {
      return c.copyWith(
        isFavorite: _favorites.contains(c.id),
        isLocked: _locked.contains(c.id),
      );
    }).toList();

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
      totalPages: totalPages,
      totalCount: totalCount,
      categoryId: categoryId,
    );
  }

  @override
  Future<Channel?> getChannel(String id) async {
    await _simulateDelay();
    try {
      final channel = _channels.firstWhere((c) => c.id == id);
      return channel.copyWith(
        isFavorite: _favorites.contains(channel.id),
        isLocked: _locked.contains(channel.id),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Channel>> getChannelsByIds(List<String> ids) async {
    await _simulateDelay();
    return _channels
        .where((c) => ids.contains(c.id))
        .map((c) => c.copyWith(
              isFavorite: _favorites.contains(c.id),
              isLocked: _locked.contains(c.id),
            ))
        .toList();
  }

  @override
  Future<List<Channel>> searchChannels(String query, {int limit = 50}) async {
    await _simulateDelay();
    final lowerQuery = query.toLowerCase();
    return _channels
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .take(limit)
        .map((c) => c.copyWith(
              isFavorite: _favorites.contains(c.id),
              isLocked: _locked.contains(c.id),
            ))
        .toList();
  }

  @override
  Future<List<Channel>> getFavoriteChannels() async {
    await _simulateDelay();
    return _channels
        .where((c) => _favorites.contains(c.id))
        .map((c) => c.copyWith(isFavorite: true))
        .toList();
  }

  @override
  Future<void> setFavorite(String channelId, bool isFavorite) async {
    await _simulateDelay();
    if (isFavorite) {
      _favorites.add(channelId);
    } else {
      _favorites.remove(channelId);
    }
  }

  @override
  Future<void> setLocked(String channelId, bool isLocked) async {
    await _simulateDelay();
    if (isLocked) {
      _locked.add(channelId);
    } else {
      _locked.remove(channelId);
    }
  }

  @override
  Future<void> refresh() async {
    await _simulateDelay(milliseconds: 500);
    // In a real implementation, this would reload from source
  }

  @override
  Future<int> getChannelCount() async {
    return _channels.length;
  }

  @override
  Future<int> getCategoryChannelCount(String categoryId) async {
    return _channels.where((c) => c.categoryId == categoryId).length;
  }

  Future<void> _simulateDelay({int milliseconds = 100}) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
  }
}
