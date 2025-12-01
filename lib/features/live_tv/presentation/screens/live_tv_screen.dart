// Kylos IPTV Player - Live TV Screen
// Main screen for browsing and watching live TV channels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/channel_list_tile.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/category_chips.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/tv_channel_card.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/iptv_player_view.dart';
import 'package:kylos_iptv_player/shared/providers/platform_providers.dart';

/// Main Live TV screen.
///
/// Displays categories and channels from the user's playlists.
/// Supports both touch navigation (mobile) and D-pad navigation (TV).
class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  @override
  void initState() {
    super.initState();
    // Load channels when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelListNotifierProvider.notifier).loadChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTV = ref.watch(isTvProvider);

    if (isTV) {
      return const _TVLiveTvScreen();
    }

    return const _MobileLiveTvScreen();
  }
}

/// Mobile version of Live TV screen with vertical list layout.
class _MobileLiveTvScreen extends ConsumerWidget {
  const _MobileLiveTvScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelListNotifierProvider);
    final playbackState = ref.watch(playbackNotifierProvider);
    final videoController = ref.watch(videoControllerProvider);
    final isPlaying = playbackState.hasContent;

    // Use horizontal layout for landscape mode
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Left side: Channel list with categories
            Expanded(
              flex: isPlaying ? 1 : 2,
              child: Column(
                children: [
                  // Header with title and actions
                  _buildHeader(context, ref, isPlaying),

                  // Category filter
                  if (channelState.categories.isNotEmpty)
                    CategoryChips(
                      categories: channelState.categories,
                      selectedCategoryId: channelState.selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        ref
                            .read(channelListNotifierProvider.notifier)
                            .selectCategory(categoryId);
                      },
                    ),

                  // Channel list
                  Expanded(
                    child: _buildChannelList(context, ref, channelState),
                  ),
                ],
              ),
            ),

            // Right side: Player area (shows when playing)
            if (isPlaying)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: IptvPlayerView(
                      videoController: videoController,
                      playbackState: playbackState,
                      callbacks: IptvPlayerCallbacks(
                        onPlayPause: () => ref
                            .read(playbackNotifierProvider.notifier)
                            .togglePlayPause(),
                        onMuteToggle: () =>
                            ref.read(playbackNotifierProvider.notifier).toggleMute(),
                        onRetry: () =>
                            ref.read(playbackNotifierProvider.notifier).retry(),
                        onBack: () =>
                            ref.read(playbackNotifierProvider.notifier).stop(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button to return to dashboard
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Dashboard',
            onPressed: () => context.go(Routes.dashboard),
          ),
          const SizedBox(width: 8),
          Text(
            'Live TV',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(channelListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(
    BuildContext context,
    WidgetRef ref,
    ChannelListState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.read(channelListNotifierProvider.notifier).loadChannels();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!state.hasChannels) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No channels available',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Add a playlist to start watching',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final currentChannelId = ref.watch(currentChannelIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(channelListNotifierProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.channels.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index >= state.channels.length) {
            if (!state.isLoadingMore) {
              ref.read(channelListNotifierProvider.notifier).loadNextPage();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final channel = state.channels[index];
          final isCurrentlyPlaying = channel.id == currentChannelId;

          return ChannelListTile(
            channel: channel,
            isPlaying: isCurrentlyPlaying,
            onTap: () {
              ref.read(playbackNotifierProvider.notifier).playChannel(channel);
            },
            onFavoriteToggle: () {
              ref
                  .read(channelListNotifierProvider.notifier)
                  .toggleFavorite(channel.id);
            },
          );
        },
      ),
    );
  }
}

/// TV version of Live TV screen with horizontal card rows and D-pad navigation.
class _TVLiveTvScreen extends ConsumerStatefulWidget {
  const _TVLiveTvScreen();

  @override
  ConsumerState<_TVLiveTvScreen> createState() => _TVLiveTvScreenState();
}

class _TVLiveTvScreenState extends ConsumerState<_TVLiveTvScreen> {
  Channel? _focusedChannel;

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelListNotifierProvider);
    final playbackState = ref.watch(playbackNotifierProvider);
    final currentChannelId = ref.watch(currentChannelIdProvider);
    final isPlaying = playbackState.hasContent;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Main content area with channel rows
            Expanded(
              flex: isPlaying ? 1 : 2,
              child: _buildTVContent(context, channelState, currentChannelId),
            ),
            // Player panel (shows when playing)
            if (isPlaying)
              Expanded(
                flex: 1,
                child: _buildPlayerPanel(context, playbackState),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTVContent(
    BuildContext context,
    ChannelListState state,
    String? currentChannelId,
  ) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load channels',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(channelListNotifierProvider.notifier).loadChannels();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!state.hasChannels) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No channels available',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a playlist to start watching',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group channels by category for TV display
    final favoriteChannels =
        state.channels.where((c) => c.isFavorite).toList();
    final categoryGroups = _groupChannelsByCategory(state);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 32, 48, 16),
            child: Row(
              children: [
                Text(
                  'Live TV',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Focused channel info
                if (_focusedChannel != null)
                  _buildFocusedChannelInfo(context, _focusedChannel!),
              ],
            ),
          ),
        ),

        // Favorites row (if any)
        if (favoriteChannels.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TVChannelRow(
                title: 'Favorites',
                channels: favoriteChannels,
                currentChannelId: currentChannelId,
                autofocusFirst: true,
                onChannelSelect: _onChannelSelect,
                onChannelFocus: (channel) {
                  setState(() => _focusedChannel = channel);
                },
              ),
            ),
          ),

        // Category rows
        ...categoryGroups.entries.map((entry) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TVChannelRow(
                title: entry.key,
                channels: entry.value,
                currentChannelId: currentChannelId,
                autofocusFirst: favoriteChannels.isEmpty &&
                    entry.key == categoryGroups.keys.first,
                onChannelSelect: _onChannelSelect,
                onChannelFocus: (channel) {
                  setState(() => _focusedChannel = channel);
                },
              ),
            ),
          );
        }),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 48),
        ),
      ],
    );
  }

  Widget _buildFocusedChannelInfo(BuildContext context, Channel channel) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                channel.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (channel.channelNumber != null)
                Text(
                  'Channel ${channel.channelNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel(
    BuildContext context,
    PlaybackState playbackState,
  ) {
    final theme = Theme.of(context);
    final videoController = ref.watch(videoControllerProvider);

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IptvPlayerView(
          videoController: videoController,
          playbackState: playbackState,
          callbacks: IptvPlayerCallbacks(
            onPlayPause: () =>
                ref.read(playbackNotifierProvider.notifier).togglePlayPause(),
            onMuteToggle: () =>
                ref.read(playbackNotifierProvider.notifier).toggleMute(),
            onRetry: () => ref.read(playbackNotifierProvider.notifier).retry(),
            onBack: () => ref.read(playbackNotifierProvider.notifier).stop(),
          ),
        ),
      ),
    );
  }

  Map<String, List<Channel>> _groupChannelsByCategory(ChannelListState state) {
    final groups = <String, List<Channel>>{};

    for (final channel in state.channels) {
      final categoryName = channel.categoryName ?? 'Uncategorized';
      groups.putIfAbsent(categoryName, () => []).add(channel);
    }

    return groups;
  }

  void _onChannelSelect(Channel channel) {
    ref.read(playbackNotifierProvider.notifier).playChannel(channel);
  }
}
