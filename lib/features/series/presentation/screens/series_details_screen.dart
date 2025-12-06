// Kylos IPTV Player - Series Details Screen
// Screen for displaying seasons and episodes of a series with TV-optimized layout.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/episode.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_info.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Series details screen with seasons and episodes.
class SeriesDetailsScreen extends ConsumerStatefulWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  ConsumerState<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends ConsumerState<SeriesDetailsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final FocusNode _screenFocusNode = FocusNode();
  bool _isFavorite = false;

  @override
  void dispose() {
    _tabController?.dispose();
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

  void _playEpisode(Episode episode, SeriesInfo seriesInfo) {
    final repository = ref.read(seriesRepositoryProvider);
    final streamUrl = repository.getEpisodeStreamUrl(
      episode.id,
      episode.containerExtension,
    );

    final content = PlayableContent(
      id: episode.id,
      title: '${seriesInfo.info.name} - ${episode.title}',
      streamUrl: streamUrl,
      type: ContentType.episode,
      logoUrl: seriesInfo.info.coverUrl,
    );

    ref.read(playbackNotifierProvider.notifier).play(content);
    context.push(Routes.player);
  }

  Future<void> _toggleFavorite() async {
    final repository = ref.read(playlistSeriesRepositoryProvider);
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    await repository.setFavorite(widget.seriesId, newValue);
  }

  @override
  Widget build(BuildContext context) {
    final seriesInfoAsync = ref.watch(seriesInfoProvider(widget.seriesId));

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
          child: seriesInfoAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: KylosColors.seriesGlow),
            ),
            error: (err, stack) => _buildErrorState(err.toString()),
            data: (seriesInfo) {
              // Initialize favorite state from series info
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isFavorite != seriesInfo.info.isFavorite) {
                  setState(() => _isFavorite = seriesInfo.info.isFavorite);
                }
              });
              return _buildContent(seriesInfo);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(null),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: KylosColors.textMuted,
                  ),
                  const SizedBox(height: KylosSpacing.m),
                  Text(
                    'Failed to load series',
                    style: KylosTvTextStyles.sectionHeader.copyWith(
                      color: KylosColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.xl),
                    child: Text(
                      error,
                      style: KylosTvTextStyles.body.copyWith(
                        color: KylosColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.xl),
                  _FocusableButton(
                    icon: Icons.arrow_back,
                    label: 'Go Back',
                    onPressed: _handleBack,
                    autofocus: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if series has any episodes across all seasons
  bool _hasAnyEpisodes(SeriesInfo seriesInfo) {
    return seriesInfo.seasons.any((season) => season.episodes.isNotEmpty);
  }

  Widget _buildContent(SeriesInfo seriesInfo) {
    // Check if series has no episodes at all
    if (!_hasAnyEpisodes(seriesInfo)) {
      return _buildEmptySeriesState(seriesInfo);
    }

    if (_tabController == null || _tabController!.length != seriesInfo.seasons.length) {
      _tabController?.dispose();
      if (seriesInfo.seasons.isNotEmpty) {
        _tabController = TabController(
          length: seriesInfo.seasons.length,
          vsync: this,
        );
      }
    }

    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(seriesInfo),
          _buildSeriesHeader(seriesInfo),
          if (seriesInfo.seasons.isNotEmpty) _buildSeasonTabs(seriesInfo),
          Expanded(
            child: _buildEpisodeList(seriesInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySeriesState(SeriesInfo seriesInfo) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(seriesInfo),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    size: 64,
                    color: KylosColors.textMuted,
                  ),
                  const SizedBox(height: KylosSpacing.m),
                  Text(
                    'No episodes available',
                    style: KylosTvTextStyles.sectionHeader.copyWith(
                      color: KylosColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.xs),
                  Text(
                    'This series has no episodes to watch.',
                    style: KylosTvTextStyles.body.copyWith(
                      color: KylosColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.xl),
                  _FocusableButton(
                    icon: Icons.arrow_back,
                    label: 'Go Back',
                    onPressed: _handleBack,
                    autofocus: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(SeriesInfo? seriesInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xl,
        vertical: KylosSpacing.m,
      ),
      child: Row(
        children: [
          _FocusableIconButton(
            icon: Icons.arrow_back,
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: KylosSpacing.m),
          Expanded(
            child: Text(
              seriesInfo?.info.name.toUpperCase() ?? 'SERIES',
              style: KylosTvTextStyles.screenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Favorite button
          _FocusableIconButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            isActive: _isFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesHeader(SeriesInfo seriesInfo) {
    final info = seriesInfo.info;
    final totalEpisodes = seriesInfo.seasons.fold<int>(
      0,
      (sum, season) => sum + season.episodes.length,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xl,
        vertical: KylosSpacing.s,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(KylosRadius.s),
              child: SizedBox(
                width: 80,
                height: 120,
                child: info.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: info.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildPosterPlaceholder(),
                        errorWidget: (_, __, ___) => _buildPosterPlaceholder(),
                      )
                    : _buildPosterPlaceholder(),
              ),
            ),
            const SizedBox(width: KylosSpacing.m),
            // Info - constrained to poster height, clipped to prevent overflow
            Expanded(
              child: SizedBox(
                height: 120,
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stats row - use Wrap to prevent horizontal overflow
                      Wrap(
                        spacing: KylosSpacing.xs,
                        runSpacing: KylosSpacing.xs,
                        children: [
                          _InfoBadge(
                            icon: Icons.video_library,
                            label: '${seriesInfo.seasons.length} S',
                          ),
                          _InfoBadge(
                            icon: Icons.play_circle_outline,
                            label: '$totalEpisodes Ep',
                          ),
                          if (info.releaseDate != null && info.releaseDate!.isNotEmpty)
                            _InfoBadge(
                              icon: Icons.calendar_today,
                              label: info.releaseDate!.split('-').first,
                            ),
                          if (info.rating != null && info.rating!.isNotEmpty)
                            _InfoBadge(
                              icon: Icons.star_rounded,
                              label: info.rating!,
                              iconColor: Colors.amber,
                            ),
                        ],
                      ),
                      // Genre
                      if (info.genre != null && info.genre!.isNotEmpty) ...[
                        const SizedBox(height: KylosSpacing.xs),
                        Text(
                          info.genre!,
                          style: KylosTvTextStyles.cardSubtitle.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Plot
                      if (info.plot != null && info.plot!.isNotEmpty) ...[
                        const SizedBox(height: KylosSpacing.xs),
                        Flexible(
                          child: Text(
                            info.plot!,
                            style: KylosTvTextStyles.body.copyWith(
                              color: KylosColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonTabs(SeriesInfo seriesInfo) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: KylosColors.buttonBorder, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: KylosColors.seriesGlow,
        indicatorWeight: 3,
        labelColor: KylosColors.seriesGlow,
        unselectedLabelColor: KylosColors.textMuted,
        labelStyle: KylosTvTextStyles.button.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: KylosTvTextStyles.button.copyWith(fontSize: 14),
        labelPadding: const EdgeInsets.symmetric(horizontal: KylosSpacing.m),
        tabs: seriesInfo.seasons.map((s) {
          return Tab(
            child: Text('S${s.seasonNumber} (${s.episodes.length})'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEpisodeList(SeriesInfo seriesInfo) {
    if (seriesInfo.seasons.isEmpty) {
      return const Center(
        child: Text('No seasons available', style: TextStyle(color: KylosColors.textMuted)),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: seriesInfo.seasons.map((season) {
        if (season.episodes.isEmpty) {
          return const Center(
            child: Text('No episodes in this season', style: TextStyle(color: KylosColors.textMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(KylosSpacing.m),
          itemCount: season.episodes.length,
          itemBuilder: (context, index) {
            final episode = season.episodes[index];
            return _EpisodeCard(
              episode: episode,
              seasonNumber: season.seasonNumber,
              episodeNumber: index + 1,
              autofocus: index == 0,
              onPlay: () => _playEpisode(episode, seriesInfo),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.tv_outlined, size: 32, color: KylosColors.textMuted),
      ),
    );
  }
}

/// Info badge widget
class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KylosColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(KylosRadius.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? KylosColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: KylosTvTextStyles.badge.copyWith(
              color: KylosColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Episode card widget with focus support.
class _EpisodeCard extends StatefulWidget {
  const _EpisodeCard({
    required this.episode,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.onPlay,
    this.autofocus = false,
  });

  final Episode episode;
  final int seasonNumber;
  final int episodeNumber;
  final VoidCallback onPlay;
  final bool autofocus;

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String get _episodeCode {
    final season = widget.seasonNumber.toString().padLeft(2, '0');
    final episode = (widget.episode.episodeNum ?? widget.episodeNumber).toString().padLeft(2, '0');
    return 'S${season}E$episode';
  }

  String? get _formattedDuration {
    final duration = widget.episode.duration;
    if (duration == null || duration.isEmpty) return null;
    final minutes = int.tryParse(duration.replaceAll(RegExp(r'[^\d]'), ''));
    if (minutes != null && minutes > 0) {
      if (minutes >= 60) {
        return '${minutes ~/ 60}h ${minutes % 60}m';
      }
      return '${minutes}m';
    }
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          margin: const EdgeInsets.only(bottom: KylosSpacing.s),
          padding: const EdgeInsets.all(KylosSpacing.m),
          decoration: BoxDecoration(
            color: _isFocused
                ? KylosColors.seriesGlow.withOpacity(0.15)
                : KylosColors.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: KylosColors.seriesGlow, width: 2)
                : Border.all(color: KylosColors.buttonBorder, width: 1),
            boxShadow: _isFocused
                ? [BoxShadow(color: KylosColors.seriesGlow.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)]
                : null,
          ),
          child: Row(
            children: [
              // Episode code badge
              Container(
                width: 64,
                height: 40,
                decoration: BoxDecoration(
                  color: _isFocused ? KylosColors.seriesGlow.withOpacity(0.3) : KylosColors.surfaceOverlay,
                  borderRadius: BorderRadius.circular(KylosRadius.s),
                ),
                child: Center(
                  child: Text(
                    _episodeCode,
                    style: KylosTvTextStyles.badge.copyWith(
                      color: _isFocused ? KylosColors.seriesGlow : KylosColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KylosSpacing.m),
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.episode.title,
                      style: KylosTvTextStyles.cardTitle.copyWith(
                        color: _isFocused ? KylosColors.seriesGlow : KylosColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: KylosSpacing.s,
                      runSpacing: 2,
                      children: [
                        if (_formattedDuration != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 12, color: KylosColors.textMuted),
                              const SizedBox(width: 4),
                              Text(_formattedDuration!, style: const TextStyle(fontSize: 11, color: KylosColors.textMuted)),
                            ],
                          ),
                        if (widget.episode.releaseDate != null && widget.episode.releaseDate!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: KylosColors.textMuted),
                              const SizedBox(width: 4),
                              Text(widget.episode.releaseDate!, style: const TextStyle(fontSize: 11, color: KylosColors.textMuted)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play icon
              Icon(
                Icons.play_circle_filled,
                color: _isFocused ? KylosColors.seriesGlow : KylosColors.textMuted,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusableIconButton extends StatefulWidget {
  const _FocusableIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isActive;

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
                  ? KylosColors.seriesGlow.withOpacity(0.2)
                  : widget.isActive
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.s),
              border: _isFocused
                  ? Border.all(color: KylosColors.seriesGlow, width: 2)
                  : null,
            ),
            child: Icon(
              widget.icon,
              color: _isFocused
                  ? KylosColors.seriesGlow
                  : widget.isActive
                      ? Colors.redAccent
                      : KylosColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusableButton extends StatefulWidget {
  const _FocusableButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
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
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.l, vertical: KylosSpacing.m),
          decoration: BoxDecoration(
            color: _isFocused ? KylosColors.seriesGlow : KylosColors.surfaceLight,
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: KylosColors.seriesGlow, width: 2)
                : Border.all(color: KylosColors.buttonBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: _isFocused ? Colors.white : KylosColors.textSecondary, size: 22),
              const SizedBox(width: KylosSpacing.s),
              Text(
                widget.label,
                style: KylosTvTextStyles.button.copyWith(
                  color: _isFocused ? Colors.white : KylosColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
