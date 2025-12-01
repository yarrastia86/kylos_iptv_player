// Kylos IPTV Player - Channel Repository Interface
// Domain layer interface for channel data operations.

import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';

/// Result of loading channels with pagination support.
class PaginatedChannels {
  const PaginatedChannels({
    required this.channels,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.categoryId,
  });

  /// List of channels for the current page.
  final List<Channel> channels;

  /// Current page number (0-indexed).
  final int currentPage;

  /// Total number of pages available.
  final int totalPages;

  /// Total number of channels.
  final int totalCount;

  /// Category ID if filtered.
  final String? categoryId;

  /// Whether there are more pages to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether this is an empty result.
  bool get isEmpty => channels.isEmpty;

  /// Creates an empty result.
  factory PaginatedChannels.empty() {
    return const PaginatedChannels(
      channels: [],
      currentPage: 0,
      totalPages: 0,
      totalCount: 0,
    );
  }

  /// Merges another page of results into this one.
  PaginatedChannels merge(PaginatedChannels other) {
    return PaginatedChannels(
      channels: [...channels, ...other.channels],
      currentPage: other.currentPage,
      totalPages: other.totalPages,
      totalCount: other.totalCount,
      categoryId: categoryId,
    );
  }
}

/// Repository interface for channel operations.
///
/// Defines the contract for accessing channel data from any source
/// (M3U playlist, Xtream API, local cache, etc.).
abstract class ChannelRepository {
  /// Gets all categories for the active playlist.
  Future<List<ChannelCategory>> getCategories();

  /// Gets a single category by ID.
  Future<ChannelCategory?> getCategory(String id);

  /// Gets channels with pagination support.
  ///
  /// [page] - Zero-indexed page number.
  /// [pageSize] - Number of channels per page.
  /// [categoryId] - Optional category filter.
  Future<PaginatedChannels> getChannels({
    int page = 0,
    int pageSize = 50,
    String? categoryId,
  });

  /// Gets a single channel by ID.
  Future<Channel?> getChannel(String id);

  /// Gets channels by a list of IDs.
  Future<List<Channel>> getChannelsByIds(List<String> ids);

  /// Searches channels by name.
  ///
  /// [query] - Search query string.
  /// [limit] - Maximum number of results.
  Future<List<Channel>> searchChannels(String query, {int limit = 50});

  /// Gets favorite channels.
  Future<List<Channel>> getFavoriteChannels();

  /// Sets a channel as favorite.
  Future<void> setFavorite(String channelId, bool isFavorite);

  /// Sets a channel as locked (parental control).
  Future<void> setLocked(String channelId, bool isLocked);

  /// Refreshes channel data from the source.
  Future<void> refresh();

  /// Gets the total count of channels.
  Future<int> getChannelCount();

  /// Gets the total count of channels in a category.
  Future<int> getCategoryChannelCount(String categoryId);
}
