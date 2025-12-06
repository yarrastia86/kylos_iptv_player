// Kylos IPTV Player - Search Screen
// Screen for searching content across the app (movies, series, and live TV).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Tab selection for search results.
enum SearchTab { liveTV, movies, series }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _screenFocusNode = FocusNode();
  late TabController _tabController;
  SearchTab _selectedTab = SearchTab.liveTV;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = SearchTab.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _playChannel(Channel channel) {
    // Create playable content
    final content = PlayableContent(
      id: channel.id,
      title: channel.name,
      streamUrl: channel.streamUrl,
      type: ContentType.liveChannel,
      logoUrl: channel.logoUrl,
      categoryName: channel.categoryName,
    );

    // Start playback
    ref.read(playbackNotifierProvider.notifier).play(content);

    // Navigate to player
    context.push(Routes.player);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;

    return Focus(
      focusNode: _screenFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
                // Search header
                _buildSearchHeader(),

                // Tab bar
                _buildTabBar(),

                // Results
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLiveTvResults(query),
                      _buildMovieResults(query),
                      _buildSeriesResults(query),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(KylosSpacing.m),
      child: Row(
        children: [
          _FocusableIconButton(
            icon: Icons.arrow_back,
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: KylosSpacing.m),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search movies, series, and channels...',
                hintStyle: const TextStyle(color: KylosColors.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: KylosColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: KylosColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: KylosColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: KylosTvTextStyles.body.copyWith(
                color: KylosColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: KylosColors.tvAccent.withOpacity(0.2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: KylosColors.tvAccent,
        unselectedLabelColor: KylosColors.textSecondary,
        dividerColor: Colors.transparent,
        labelStyle: KylosTvTextStyles.badge,
        tabs: const [
          Tab(
            icon: Icon(Icons.live_tv, size: 20),
            text: 'Live TV',
          ),
          Tab(
            icon: Icon(Icons.movie, size: 20),
            text: 'Movies',
          ),
          Tab(
            icon: Icon(Icons.tv, size: 20),
            text: 'Series',
          ),
        ],
      ),
    );
  }

  Widget _buildMovieResults(String query) {
    if (query.length < 2) {
      return _buildEmptyState('Enter at least 2 characters to search movies');
    }

    final moviesAsync = ref.watch(movieSearchProvider(query));

    return moviesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KylosColors.tvAccent),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error searching movies',
          style: KylosTvTextStyles.body.copyWith(color: KylosColors.textMuted),
        ),
      ),
      data: (movies) {
        if (movies.isEmpty) {
          return _buildEmptyState('No movies found for "$query"');
        }
        return _buildMovieList(movies);
      },
    );
  }

  Widget _buildSeriesResults(String query) {
    if (query.length < 2) {
      return _buildEmptyState('Enter at least 2 characters to search series');
    }

    final seriesAsync = ref.watch(seriesSearchProvider(query));

    return seriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KylosColors.tvAccent),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error searching series',
          style: KylosTvTextStyles.body.copyWith(color: KylosColors.textMuted),
        ),
      ),
      data: (series) {
        if (series.isEmpty) {
          return _buildEmptyState('No series found for "$query"');
        }
        return _buildSeriesList(series);
      },
    );
  }

  Widget _buildLiveTvResults(String query) {
    if (query.length < 2) {
      return _buildEmptyState('Enter at least 2 characters to search channels');
    }

    final channelsAsync = ref.watch(channelSearchProvider(query));

    return channelsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KylosColors.tvAccent),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error searching channels',
          style: KylosTvTextStyles.body.copyWith(color: KylosColors.textMuted),
        ),
      ),
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState('No channels found for "$query"');
        }
        return _buildChannelList(channels);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTab == SearchTab.liveTV
                ? Icons.live_tv
                : _selectedTab == SearchTab.movies
                    ? Icons.movie
                    : Icons.tv,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            message,
            style: KylosTvTextStyles.body.copyWith(
              color: KylosColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovieList(List<VodMovie> movies) {
    return ListView.builder(
      padding: const EdgeInsets.all(KylosSpacing.m),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _SearchResultCard(
          title: movie.name,
          subtitle: movie.categoryName ?? movie.genre,
          imageUrl: movie.posterUrl,
          rating: movie.rating,
          icon: Icons.movie,
          glowColor: KylosColors.moviesGlow,
          onTap: () => context.push(Routes.movieDetailPath(movie.id)),
        );
      },
    );
  }

  Widget _buildSeriesList(List<Series> series) {
    return ListView.builder(
      padding: const EdgeInsets.all(KylosSpacing.m),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final item = series[index];
        return _SearchResultCard(
          title: item.name,
          subtitle: item.categoryName ?? item.genre,
          imageUrl: item.coverUrl,
          rating: item.rating,
          icon: Icons.tv,
          glowColor: KylosColors.seriesGlow,
          onTap: () => context.push(Routes.seriesDetailPath(item.id)),
        );
      },
    );
  }

  Widget _buildChannelList(List<Channel> channels) {
    return ListView.builder(
      padding: const EdgeInsets.all(KylosSpacing.m),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return _SearchResultCard(
          title: channel.name,
          subtitle: channel.categoryName,
          imageUrl: channel.logoUrl,
          icon: Icons.live_tv,
          glowColor: KylosColors.liveTvGlow,
          isLive: true,
          onTap: () => _playChannel(channel),
        );
      },
    );
  }
}

/// Focusable icon button.
class _FocusableIconButton extends StatefulWidget {
  const _FocusableIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<_FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<_FocusableIconButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            padding: const EdgeInsets.all(KylosSpacing.s),
            decoration: BoxDecoration(
              color: _isFocused
                  ? KylosColors.tvAccent.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.s),
              border: _isFocused
                  ? Border.all(color: KylosColors.tvAccent, width: 2)
                  : null,
            ),
            child: Icon(
              widget.icon,
              color:
                  _isFocused ? KylosColors.tvAccent : KylosColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatefulWidget {
  const _SearchResultCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.rating,
    required this.icon,
    required this.glowColor,
    required this.onTap,
    this.isLive = false,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? rating;
  final IconData icon;
  final Color glowColor;
  final VoidCallback onTap;
  final bool isLive;

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onTap();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          margin: const EdgeInsets.only(bottom: KylosSpacing.s),
          padding: const EdgeInsets.all(KylosSpacing.s),
          decoration: BoxDecoration(
            color: _isFocused
                ? widget.glowColor.withOpacity(0.15)
                : KylosColors.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: widget.glowColor, width: 2)
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 90,
                  child: _buildImage(),
                ),
              ),
              const SizedBox(width: KylosSpacing.m),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with live badge
                    Row(
                      children: [
                        if (widget.isLive)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LIVE',
                              style: KylosTvTextStyles.badge.copyWith(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: KylosTvTextStyles.cardTitle.copyWith(
                              color: _isFocused
                                  ? widget.glowColor
                                  : KylosColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: KylosTvTextStyles.metadata.copyWith(
                          color: KylosColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.rating != null && widget.rating!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating!,
                            style: KylosTvTextStyles.badge.copyWith(
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow or play icon
              Icon(
                widget.isLive ? Icons.play_circle_filled : Icons.chevron_right,
                color: _isFocused ? widget.glowColor : KylosColors.textMuted,
                size: widget.isLive ? 32 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildPlaceholder(),
        placeholder: (_, __) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: Center(
        child: Icon(
          widget.icon,
          color: KylosColors.textMuted,
          size: 28,
        ),
      ),
    );
  }
}
