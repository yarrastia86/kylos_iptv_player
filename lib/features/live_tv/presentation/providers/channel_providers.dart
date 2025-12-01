// Kylos IPTV Player - Channel Providers
// Riverpod providers for channel state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/live_tv/data/repositories/playlist_channel_repository.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/channel_repository.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/epg_repository.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';

/// State for the channel list.
class ChannelListState {
  const ChannelListState({
    this.channels = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalCount = 0,
    this.allChannelsCount = 0,
    this.favoritesCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// List of loaded channels.
  final List<Channel> channels;

  /// Available categories.
  final List<ChannelCategory> categories;

  /// Currently selected category filter.
  final String? selectedCategoryId;

  /// Current page number.
  final int currentPage;

  /// Total pages available.
  final int totalPages;

  /// Total channel count for current filter.
  final int totalCount;

  /// Total count of ALL channels (not affected by category filter).
  final int allChannelsCount;

  /// Total count of favorite channels (from storage).
  final int favoritesCount;

  /// Whether initial load is in progress.
  final bool isLoading;

  /// Whether loading more channels.
  final bool isLoadingMore;

  /// Error message if loading failed.
  final String? error;

  /// Whether there are more channels to load.
  bool get hasMore => currentPage < totalPages - 1;

  /// Whether channels are available.
  bool get hasChannels => channels.isNotEmpty;

  /// Creates a loading state.
  factory ChannelListState.loading() {
    return const ChannelListState(isLoading: true);
  }

  /// Creates a copy with the given fields replaced.
  ChannelListState copyWith({
    List<Channel>? channels,
    List<ChannelCategory>? categories,
    String? selectedCategoryId,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    int? allChannelsCount,
    int? favoritesCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return ChannelListState(
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      allChannelsCount: allChannelsCount ?? this.allChannelsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Notifier for the channel list.
///
/// Manages loading and filtering of channels from the active playlist.
class ChannelListNotifier extends StateNotifier<ChannelListState> {
  ChannelListNotifier({
    required this.playlistChannelRepository,
    required this.ref,
  }) : super(const ChannelListState());

  final PlaylistChannelRepository playlistChannelRepository;
  final Ref ref;

  static const _pageSize = 50;

  /// Loads channels for the active playlist.
  Future<void> loadChannels() async {
    // Check if there's an active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      state = state.copyWith(channels: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Set the playlist source on the repository (will refresh data if changed)
      await playlistChannelRepository.setPlaylistSource(activePlaylist);

      // Load categories first
      final categories = await playlistChannelRepository.getCategories();

      // Load first page of channels (no filter to get total count)
      final result = await playlistChannelRepository.getChannels(
        page: 0,
        pageSize: _pageSize,
        categoryId: null, // No filter to get ALL channels count
      );

      state = state.copyWith(
        channels: result.channels,
        categories: categories,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        allChannelsCount: result.totalCount, // Store total count of ALL channels
        favoritesCount: playlistChannelRepository.favoritesCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load channels: $e',
      );
    }
  }

  /// Loads the next page of channels.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    // No pagination for favorites - all are loaded at once
    if (state.selectedCategoryId == 'favorites') return;

    state = state.copyWith(isLoadingMore: true);

    try {
      // Handle "all" category as null (no filter)
      final effectiveCategoryId =
          state.selectedCategoryId == 'all' ? null : state.selectedCategoryId;

      final result = await playlistChannelRepository.getChannels(
        page: state.currentPage + 1,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        channels: [...state.channels, ...result.channels],
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Filters channels by category.
  Future<void> selectCategory(String? categoryId) async {
    if (categoryId == state.selectedCategoryId) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      channels: [],
      currentPage: 0,
      isLoading: true,
    );

    try {
      // Handle special "favorites" category
      if (categoryId == 'favorites') {
        final favorites = await playlistChannelRepository.getFavoriteChannels();
        state = state.copyWith(
          channels: favorites,
          currentPage: 0,
          totalPages: 1,
          totalCount: favorites.length,
          isLoading: false,
        );
        return;
      }

      // Handle "all" category as null (no filter)
      final effectiveCategoryId = categoryId == 'all' ? null : categoryId;

      final result = await playlistChannelRepository.getChannels(
        page: 0,
        pageSize: _pageSize,
        categoryId: effectiveCategoryId,
      );

      state = state.copyWith(
        channels: result.channels,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to filter channels: $e',
      );
    }
  }

  /// Toggles favorite status for a channel.
  Future<void> toggleFavorite(String channelId) async {
    final channelIndex =
        state.channels.indexWhere((c) => c.id == channelId);
    if (channelIndex == -1) return;

    final channel = state.channels[channelIndex];
    final newFavorite = !channel.isFavorite;
    final isViewingFavorites = state.selectedCategoryId == 'favorites';

    // Optimistic update
    List<Channel> updatedChannels;
    if (isViewingFavorites && !newFavorite) {
      // Remove channel from list when unfavoriting while viewing favorites
      updatedChannels = [...state.channels];
      updatedChannels.removeAt(channelIndex);
    } else {
      updatedChannels = [...state.channels];
      updatedChannels[channelIndex] = channel.copyWith(isFavorite: newFavorite);
    }

    final newFavoritesCount = state.favoritesCount + (newFavorite ? 1 : -1);
    state = state.copyWith(
      channels: updatedChannels,
      favoritesCount: newFavoritesCount,
      totalCount: isViewingFavorites ? updatedChannels.length : state.totalCount,
    );

    try {
      await playlistChannelRepository.setFavorite(channelId, newFavorite);
    } catch (e) {
      // Revert on error
      if (isViewingFavorites && !newFavorite) {
        // Re-insert channel at original position
        updatedChannels.insert(channelIndex, channel);
      } else {
        updatedChannels[channelIndex] = channel;
      }
      state = state.copyWith(
        channels: updatedChannels,
        favoritesCount: state.favoritesCount + (newFavorite ? -1 : 1),
        totalCount: isViewingFavorites ? updatedChannels.length : state.totalCount,
      );
    }
  }

  /// Refreshes channel data from source.
  Future<void> refresh() async {
    // Get the active playlist
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Force refresh by clearing and reloading
      await playlistChannelRepository.setPlaylistSource(null);
      await playlistChannelRepository.setPlaylistSource(activePlaylist);

      // Load categories and channels
      final categories = await playlistChannelRepository.getCategories();
      final result = await playlistChannelRepository.getChannels(
        page: 0,
        pageSize: _pageSize,
        categoryId: state.selectedCategoryId,
      );

      state = state.copyWith(
        channels: result.channels,
        categories: categories,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh channels: $e',
      );
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the channel list notifier.
final channelListNotifierProvider =
    StateNotifierProvider<ChannelListNotifier, ChannelListState>((ref) {
  final playlistChannelRepository = ref.watch(playlistChannelRepositoryProvider);
  return ChannelListNotifier(
    playlistChannelRepository: playlistChannelRepository,
    ref: ref,
  );
});

/// State for channel EPG data.
class ChannelEpgState {
  const ChannelEpgState({
    this.epgData = const {},
    this.isLoading = false,
  });

  /// EPG data keyed by channel ID.
  final Map<String, ChannelEpg> epgData;

  /// Whether EPG is being loaded.
  final bool isLoading;

  /// Gets EPG for a specific channel.
  ChannelEpg? getChannelEpg(String channelId) => epgData[channelId];

  /// Creates a copy with the given fields replaced.
  ChannelEpgState copyWith({
    Map<String, ChannelEpg>? epgData,
    bool? isLoading,
  }) {
    return ChannelEpgState(
      epgData: epgData ?? this.epgData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for EPG data.
class ChannelEpgNotifier extends StateNotifier<ChannelEpgState> {
  ChannelEpgNotifier({
    required this.epgRepository,
  }) : super(const ChannelEpgState());

  final EpgRepository epgRepository;

  /// Loads EPG for a list of channels.
  Future<void> loadEpgForChannels(List<String> channelIds) async {
    if (channelIds.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final epgData = await epgRepository.getCurrentEpgBatch(channelIds);
      state = state.copyWith(
        epgData: {...state.epgData, ...epgData},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Loads EPG for a single channel.
  Future<ChannelEpg?> loadEpgForChannel(String channelId) async {
    try {
      final epg = await epgRepository.getCurrentEpg(channelId);
      state = state.copyWith(
        epgData: {...state.epgData, channelId: epg},
      );
      return epg;
    } catch (e) {
      return null;
    }
  }

  /// Refreshes all EPG data.
  Future<void> refresh() async {
    await epgRepository.refresh();
    // Reload EPG for currently loaded channels
    if (state.epgData.isNotEmpty) {
      await loadEpgForChannels(state.epgData.keys.toList());
    }
  }

  /// Clears all cached EPG data.
  void clearCache() {
    state = const ChannelEpgState();
  }
}

/// Provider for the EPG notifier.
final channelEpgNotifierProvider =
    StateNotifierProvider<ChannelEpgNotifier, ChannelEpgState>((ref) {
  final epgRepository = ref.watch(epgRepositoryProvider);
  return ChannelEpgNotifier(epgRepository: epgRepository);
});

/// Provider to get EPG for a specific channel.
final channelEpgProvider =
    Provider.family<ChannelEpg?, String>((ref, channelId) {
  return ref.watch(channelEpgNotifierProvider).getChannelEpg(channelId);
});

/// Provider to search channels.
final channelSearchProvider =
    FutureProvider.family<List<Channel>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repository = ref.watch(channelRepositoryProvider);
  return repository.searchChannels(query);
});

/// Provider for favorite channels.
final favoriteChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repository = ref.watch(channelRepositoryProvider);
  return repository.getFavoriteChannels();
});

/// Placeholder for the playlist channel repository provider - should be overridden.
/// This provides access to the concrete implementation with setPlaylistSource().
final playlistChannelRepositoryProvider =
    Provider<PlaylistChannelRepository>((ref) {
  throw UnimplementedError(
    'playlistChannelRepositoryProvider must be overridden with an implementation',
  );
});

/// Provider for the base channel repository interface.
/// Delegates to playlistChannelRepositoryProvider.
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ref.watch(playlistChannelRepositoryProvider);
});

/// Placeholder for the EPG repository provider - should be overridden.
final epgRepositoryProvider = Provider<EpgRepository>((ref) {
  throw UnimplementedError(
    'epgRepositoryProvider must be overridden with an implementation',
  );
});
