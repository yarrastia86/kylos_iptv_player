// Kylos IPTV Player - Live TV Channel List Screen
// Screen for displaying channels in a category with mini player and EPG.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/bottom_hints_row.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/channel_row.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/epg_info_panel.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Screen for displaying channels in a category.
///
/// Features a two-column layout with:
/// - LEFT: Scrollable channel list
/// - RIGHT TOP: Mini player placeholder
/// - RIGHT BOTTOM: EPG info panel
class LiveTvChannelListScreen extends ConsumerStatefulWidget {
  const LiveTvChannelListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  /// The ID of the category to display channels for.
  final String categoryId;

  /// Optional display name of the category.
  final String? categoryName;

  @override
  ConsumerState<LiveTvChannelListScreen> createState() =>
      _LiveTvChannelListScreenState();
}

class _LiveTvChannelListScreenState
    extends ConsumerState<LiveTvChannelListScreen> {
  late Timer _timer;
  late DateTime _currentTime;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    // Load channels for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChannels();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final notifier = ref.read(channelListNotifierProvider.notifier);
    // Pass the categoryId directly - selectCategory handles special categories
    await notifier.selectCategory(widget.categoryId);

    // Load EPG for visible channels
    final state = ref.read(channelListNotifierProvider);
    if (state.channels.isNotEmpty) {
      final visibleChannelIds =
          state.channels.take(20).map((c) => c.epgChannelId ?? c.id).toList();
      ref
          .read(channelEpgNotifierProvider.notifier)
          .loadEpgForChannels(visibleChannelIds);
    }
  }

  void _handleBack() {
    // Stop playback before navigating away
    ref.read(playbackNotifierProvider.notifier).stop();
    context.go(Routes.liveTV);
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  void _handleMore() {
    _showOptionsMenu();
  }

  void _showOptionsMenu() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Options',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.refresh, color: KylosColors.textSecondary),
              title: const Text(
                'Refresh',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleRefresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort, color: KylosColors.textSecondary),
              title: const Text(
                'Sort',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.settings, color: KylosColors.textSecondary),
              title: const Text(
                'Settings',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.settings);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: KylosColors.textSecondary),
              title: const Text(
                'Logout',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(channelListNotifierProvider.notifier).refresh();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Logout',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout? This will clear your active playlist.',
          style: TextStyle(color: KylosColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if ((shouldLogout ?? false) && mounted) {
      ref.read(activePlaylistNotifierProvider.notifier).clearActivePlaylist();
      context.go(Routes.onboarding);
    }
  }

  void _handleChannelSelect(Channel channel, int index) {
    setState(() => _selectedIndex = index);

    // Load EPG for selected channel
    final epgChannelId = channel.epgChannelId ?? channel.id;
    ref.read(channelEpgNotifierProvider.notifier).loadEpgForChannel(epgChannelId);

    // Auto-play the channel
    _playChannel(channel);
  }

  void _playChannel(Channel channel) {
    ref.read(playbackNotifierProvider.notifier).playChannel(channel);
  }

  void _handleFavoriteToggle(String channelId) {
    ref.read(channelListNotifierProvider.notifier).toggleFavorite(channelId);
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelListNotifierProvider);
    final epgState = ref.watch(channelEpgNotifierProvider);
    final playbackState = ref.watch(playbackNotifierProvider);
    final videoController = ref.watch(videoControllerProvider);

    final selectedChannel = channelState.channels.isNotEmpty &&
            _selectedIndex < channelState.channels.length
        ? channelState.channels[_selectedIndex]
        : null;

    final selectedEpg = selectedChannel != null
        ? epgState
            .getChannelEpg(selectedChannel.epgChannelId ?? selectedChannel.id)
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KylosColors.backgroundStart,
              KylosColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(),

              // Main content
              Expanded(
                child: _buildContent(
                  channelState,
                  selectedChannel,
                  selectedEpg,
                  epgState.isLoading,
                  playbackState,
                  videoController,
                ),
              ),

              // Bottom hints
              BottomHintsRow(
                showFavorite: true,
                isFavorite: selectedChannel?.isFavorite ?? false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.m,
        vertical: KylosSpacing.s,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: KylosColors.textPrimary),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),

          const SizedBox(width: 8),

          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: KylosColors.liveTvGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // "Live" label with dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.red, size: 8),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Time and date
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeFormat.format(_currentTime),
                style: const TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                dateFormat.format(_currentTime),
                style: const TextStyle(
                  color: KylosColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: KylosColors.textSecondary),
            onPressed: _handleSearch,
            tooltip: 'Search',
          ),

          // More button
          IconButton(
            icon: const Icon(Icons.more_vert, color: KylosColors.textSecondary),
            onPressed: _handleMore,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ChannelListState state,
    Channel? selectedChannel,
    ChannelEpg? selectedEpg,
    bool epgLoading,
    PlaybackState playbackState,
    VideoController? videoController,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.liveTvGlow,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: KylosColors.textMuted,
            ),
            const SizedBox(height: KylosSpacing.m),
            const Text(
              'Failed to load channels',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            Text(
              state.error!,
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KylosSpacing.l),
            FilledButton.icon(
              onPressed: _loadChannels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.tv_off,
              size: 64,
              color: KylosColors.textMuted,
            ),
            SizedBox(height: KylosSpacing.m),
            Text(
              'No channels available',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: KylosSpacing.xs),
            Text(
              'This category has no channels',
              style: TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Channel list
          Expanded(
            flex: 5,
            child: _buildChannelList(state),
          ),

          const SizedBox(width: 12),

          // RIGHT: Player and EPG
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Video player - tap to go fullscreen
                GestureDetector(
                  onTap: () {
                    if (playbackState.hasContent) {
                      context.push(Routes.player);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: playbackState.hasContent
                            ? _buildMiniPlayer(videoController, playbackState)
                            : _buildEmptyPlayerState(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // EPG panel
                Expanded(
                  child: EpgInfoPanel(
                    channelEpg: selectedEpg,
                    isLoading: epgLoading && selectedChannel != null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(
    VideoController? videoController,
    PlaybackState playbackState,
  ) {
    if (videoController == null) {
      return _buildLoadingIndicator();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video
        Video(
          controller: videoController,
          fit: BoxFit.contain,
          controls: (state) => const SizedBox.shrink(),
        ),

        // Loading/buffering overlay
        if (playbackState.status == PlaybackStatus.loading ||
            playbackState.status == PlaybackStatus.buffering)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: KylosColors.liveTvGlow,
                strokeWidth: 2,
              ),
            ),
          ),

        // Error overlay
        if (playbackState.status == PlaybackStatus.error)
          Container(
            color: Colors.black87,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.signal_wifi_off,
                      color: Colors.red.shade300,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unable to play',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(playbackNotifierProvider.notifier).retry(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Fullscreen hint overlay
        if (playbackState.status == PlaybackStatus.playing)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen, color: Colors.white70, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Tap for fullscreen',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: KylosColors.liveTvGlow,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildEmptyPlayerState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv,
            size: 48,
            color: KylosColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a channel to play',
            style: TextStyle(
              color: KylosColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(ChannelListState state) {
    // Format count for display (e.g., 11316 -> "11.3K")
    String formatCount(int count) {
      if (count >= 1000) {
        return '${(count / 1000).toStringAsFixed(1)}K';
      }
      return count.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Text(
                widget.categoryName?.toUpperCase() ?? 'CHANNELS',
                style: const TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${formatCount(state.totalCount)} channels',
                style: const TextStyle(
                  color: KylosColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Channel list with pagination
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Load more when near the end
              if (notification is ScrollEndNotification) {
                final metrics = notification.metrics;
                if (metrics.pixels >= metrics.maxScrollExtent - 500) {
                  // Load next page when within 500px of the end
                  ref.read(channelListNotifierProvider.notifier).loadNextPage();
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: state.channels.length + (state.hasMore ? 1 : 0),
              cacheExtent: 500,
              itemBuilder: (context, index) {
                // Show loading indicator at the end if loading more
                if (index >= state.channels.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: state.isLoadingMore
                          ? const CircularProgressIndicator(
                              color: KylosColors.liveTvGlow,
                              strokeWidth: 2,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final channel = state.channels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ChannelRow(
                    channel: channel,
                    index: index,
                    isSelected: index == _selectedIndex,
                    autofocus: index == 0,
                    onTap: () => _handleChannelSelect(channel, index),
                    onFavoriteToggle: () => _handleFavoriteToggle(channel.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
