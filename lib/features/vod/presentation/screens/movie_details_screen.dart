// Kylos IPTV Player - Movie Details Screen
// Responsive movie details view optimized for TV, tablet, and phone.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_providers.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Responsive movie details screen.
///
/// Adapts layout based on screen size:
/// - TV/Desktop (>1200px): Side-by-side poster and info
/// - Tablet (600-1200px): Compact side-by-side layout
/// - Phone (<600px): Stacked vertical layout
///
/// All layouts feature:
/// - Play button prominently visible without scrolling
/// - Rich movie information display (plot, cast, director, genre, etc.)
/// - No overflow issues - everything fits within safe area
/// - Clear focus states for D-pad navigation
class MovieDetailsScreen extends ConsumerStatefulWidget {
  const MovieDetailsScreen({
    super.key,
    required this.movieId,
  });

  final String movieId;

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  VodMovie? _movie;
  WatchProgress? _watchProgress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMovie() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(vodRepositoryProvider);
      final movie = await repository.getMovie(widget.movieId);

      if (movie == null) {
        setState(() {
          _error = 'Movie not found';
          _isLoading = false;
        });
        return;
      }

      // Load watch progress
      final watchHistoryRepo = ref.read(watchHistoryRepositoryProvider);
      final progress = await watchHistoryRepo.getProgress(widget.movieId);

      setState(() {
        _movie = movie;
        _watchProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load movie';
        _isLoading = false;
      });
    }
  }

  void _playMovie({bool fromBeginning = false}) {
    final movie = _movie;
    if (movie == null) return;

    final content = PlayableContent(
      id: movie.id,
      title: movie.name,
      streamUrl: movie.streamUrl,
      type: ContentType.vod,
      logoUrl: movie.posterUrl,
      categoryName: movie.categoryName,
      duration: _parseDuration(movie.duration),
      resumePosition: fromBeginning ? null : _watchProgress?.position,
    );

    ref.read(playbackNotifierProvider.notifier).play(content);
    context.push(Routes.player);
  }

  Duration? _parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;

    if (durationStr.contains(':')) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: int.tryParse(parts[2]) ?? 0,
        );
      }
      if (parts.length == 2) {
        return Duration(
          minutes: int.tryParse(parts[0]) ?? 0,
          seconds: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final numericPart = RegExp(r'\d+').firstMatch(durationStr)?.group(0);
    if (numericPart != null) {
      final minutes = int.tryParse(numericPart) ?? 0;
      return Duration(minutes: minutes);
    }

    return null;
  }

  void _toggleFavorite() async {
    final movie = _movie;
    if (movie == null) return;

    await ref
        .read(movieListNotifierProvider.notifier)
        .toggleFavorite(movie.id);

    setState(() {
      _movie = movie.copyWith(isFavorite: !movie.isFavorite);
    });
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

  @override
  Widget build(BuildContext context) {
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
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KylosColors.tvAccent),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return _buildMovieDetails(_movie!);
  }

  Widget _buildErrorState() {
    return SafeArea(
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
              _error!,
              style: KylosTvTextStyles.sectionHeader.copyWith(
                color: KylosColors.textPrimary,
              ),
            ),
            const SizedBox(height: KylosSpacing.l),
            _ActionButton(
              icon: Icons.arrow_back,
              label: 'Go Back',
              onPressed: _handleBack,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieDetails(VodMovie movie) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Responsive breakpoints
        if (screenWidth >= 1200) {
          return _buildTvLayout(movie, constraints);
        } else if (screenWidth >= 600) {
          return _buildTabletLayout(movie, constraints);
        } else {
          return _buildPhoneLayout(movie, constraints);
        }
      },
    );
  }

  /// TV/Desktop layout: Side-by-side with poster background
  Widget _buildTvLayout(VodMovie movie, BoxConstraints constraints) {
    final hasProgress = _watchProgress != null && _watchProgress!.canResume;
    final progress = hasProgress ? _watchProgress!.progress : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background poster (right side)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: constraints.maxWidth * 0.55,
          child: _buildPosterImage(movie),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                KylosColors.backgroundStart,
                KylosColors.backgroundStart.withOpacity(0.98),
                KylosColors.backgroundStart.withOpacity(0.85),
                KylosColors.backgroundStart.withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.4, 0.6, 0.85],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KylosSpacing.xl),
            child: Row(
              children: [
                // Left side: Info (50%)
                Expanded(
                  flex: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(movie),
                      const SizedBox(height: KylosSpacing.l),

                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                movie.name,
                                style: KylosTvTextStyles.screenTitle.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: KylosSpacing.m),

                              // Metadata chips
                              _buildMetadataRow(movie),
                              const SizedBox(height: KylosSpacing.l),

                              // Progress indicator (if resumable)
                              if (hasProgress) ...[
                                _buildProgressIndicator(progress),
                                const SizedBox(height: KylosSpacing.l),
                              ],

                              // Action buttons
                              _buildActionButtons(hasProgress),
                              const SizedBox(height: KylosSpacing.xl),

                              // Movie Information Section
                              _buildMovieInfoSection(movie),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side: Space for poster
                const Expanded(flex: 50, child: SizedBox()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tablet layout: Compact side-by-side
  Widget _buildTabletLayout(VodMovie movie, BoxConstraints constraints) {
    final hasProgress = _watchProgress != null && _watchProgress!.canResume;
    final progress = hasProgress ? _watchProgress!.progress : 0.0;

    return SafeArea(
      child: Row(
        children: [
          // Left: Poster
          SizedBox(
            width: constraints.maxWidth * 0.35,
            child: Padding(
              padding: const EdgeInsets.all(KylosSpacing.l),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _IconButton(
                      icon: Icons.arrow_back,
                      onPressed: _handleBack,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.m),

                  // Poster
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(KylosRadius.l),
                      child: _buildPosterImage(movie),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KylosSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.name,
                          style: KylosTvTextStyles.screenTitle.copyWith(
                            fontSize: 28,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KylosSpacing.m),
                      _IconButton(
                        icon: movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                        onPressed: _toggleFavorite,
                        color: movie.isFavorite ? Colors.redAccent : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: KylosSpacing.m),

                  // Metadata
                  _buildMetadataRow(movie),
                  const SizedBox(height: KylosSpacing.l),

                  // Progress
                  if (hasProgress) ...[
                    _buildProgressIndicator(progress),
                    const SizedBox(height: KylosSpacing.l),
                  ],

                  // Actions
                  _buildActionButtons(hasProgress),
                  const SizedBox(height: KylosSpacing.xl),

                  // Movie Information
                  _buildMovieInfoSection(movie),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phone layout: Vertical stacked
  Widget _buildPhoneLayout(VodMovie movie, BoxConstraints constraints) {
    final hasProgress = _watchProgress != null && _watchProgress!.canResume;
    final progress = hasProgress ? _watchProgress!.progress : 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with poster
            Stack(
              children: [
                // Poster background
                SizedBox(
                  height: constraints.maxHeight * 0.4,
                  width: double.infinity,
                  child: _buildPosterImage(movie),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          KylosColors.backgroundStart.withOpacity(0.5),
                          KylosColors.backgroundStart,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top bar
                Positioned(
                  top: KylosSpacing.m,
                  left: KylosSpacing.m,
                  right: KylosSpacing.m,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconButton(
                        icon: Icons.arrow_back,
                        onPressed: _handleBack,
                      ),
                      _IconButton(
                        icon: movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                        onPressed: _toggleFavorite,
                        color: movie.isFavorite ? Colors.redAccent : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(KylosSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.name,
                    style: KylosTvTextStyles.sectionHeader.copyWith(
                      fontSize: 24,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KylosSpacing.m),

                  // Metadata
                  _buildMetadataRow(movie),
                  const SizedBox(height: KylosSpacing.l),

                  // Progress
                  if (hasProgress) ...[
                    _buildProgressIndicator(progress),
                    const SizedBox(height: KylosSpacing.l),
                  ],

                  // Actions
                  _buildActionButtons(hasProgress, compact: true),
                  const SizedBox(height: KylosSpacing.xl),

                  // Movie Information
                  _buildMovieInfoSection(movie),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterImage(VodMovie movie) {
    if (movie.posterUrl != null && movie.posterUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: movie.posterUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildPosterPlaceholder(),
      );
    }
    return _buildPosterPlaceholder();
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: const Center(
        child: Icon(
          Icons.movie,
          size: 80,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildTopBar(VodMovie movie) {
    return Row(
      children: [
        _IconButton(
          icon: Icons.arrow_back,
          onPressed: _handleBack,
        ),
        const Spacer(),
        _IconButton(
          icon: movie.isFavorite ? Icons.favorite : Icons.favorite_border,
          onPressed: _toggleFavorite,
          color: movie.isFavorite ? Colors.redAccent : null,
        ),
      ],
    );
  }

  Widget _buildMetadataRow(VodMovie movie) {
    final items = <Widget>[];

    // Year
    if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty) {
      final year = movie.releaseDate!.length >= 4
          ? movie.releaseDate!.substring(0, 4)
          : movie.releaseDate;
      items.add(_MetadataChip(text: year!, icon: Icons.calendar_today));
    }

    // Rating
    if (movie.rating != null && movie.rating!.isNotEmpty) {
      items.add(_RatingChip(rating: movie.rating!));
    }

    // Duration
    if (movie.duration != null && movie.duration!.isNotEmpty) {
      items.add(_MetadataChip(text: movie.duration!, icon: Icons.schedule));
    }

    // Genre
    if (movie.genre != null && movie.genre!.isNotEmpty) {
      // Split genres and show first 2
      final genres = movie.genre!.split(',').map((g) => g.trim()).take(2);
      for (final genre in genres) {
        if (genre.isNotEmpty) {
          items.add(_MetadataChip(text: genre));
        }
      }
    }

    // Format badge
    final format = _getFormatBadge(movie.name);
    if (format != null) {
      items.add(_FormatChip(format: format));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: KylosSpacing.s,
      runSpacing: KylosSpacing.xs,
      children: items,
    );
  }

  String? _getFormatBadge(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('4k') || lower.contains('2160p') || lower.contains('uhd')) {
      return '4K';
    }
    if (lower.contains('1080p') || lower.contains('fhd') || lower.contains('720p')) {
      return 'HD';
    }
    return null;
  }

  Widget _buildProgressIndicator(double progress) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: Border.all(color: KylosColors.tvAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 18,
                color: KylosColors.tvAccent,
              ),
              const SizedBox(width: KylosSpacing.xs),
              Text(
                'Continue watching • $percent% complete',
                style: KylosTvTextStyles.metadata.copyWith(
                  color: KylosColors.tvAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: KylosSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: KylosColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(KylosColors.tvAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool hasProgress, {bool compact = false}) {
    if (compact) {
      // Stacked layout for phone
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlayButton(
            label: hasProgress ? 'Resume' : 'Play',
            onPressed: () => _playMovie(fromBeginning: !hasProgress),
            autofocus: true,
          ),
          if (hasProgress) ...[
            const SizedBox(height: KylosSpacing.s),
            _ActionButton(
              icon: Icons.replay,
              label: 'Start Over',
              onPressed: () => _playMovie(fromBeginning: true),
            ),
          ],
        ],
      );
    }

    // Horizontal layout for TV/tablet
    return Row(
      children: [
        Expanded(
          flex: hasProgress ? 2 : 1,
          child: _PlayButton(
            label: hasProgress ? 'Resume' : 'Play',
            onPressed: () => _playMovie(fromBeginning: !hasProgress),
            autofocus: true,
          ),
        ),
        if (hasProgress) ...[
          const SizedBox(width: KylosSpacing.m),
          Expanded(
            child: _ActionButton(
              icon: Icons.replay,
              label: 'Start Over',
              onPressed: () => _playMovie(fromBeginning: true),
            ),
          ),
        ],
      ],
    );
  }

  /// Build the comprehensive movie information section
  Widget _buildMovieInfoSection(VodMovie movie) {
    final hasPlot = movie.plot != null && movie.plot!.isNotEmpty;
    final hasDirector = movie.director != null && movie.director!.isNotEmpty;
    final hasCast = movie.cast != null && movie.cast!.isNotEmpty;
    final hasGenre = movie.genre != null && movie.genre!.isNotEmpty;
    final hasCategory = movie.categoryName != null && movie.categoryName!.isNotEmpty;

    // Check if any info is available
    if (!hasPlot && !hasDirector && !hasCast && !hasGenre && !hasCategory) {
      return _buildNoInfoAvailable();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plot / Synopsis
        if (hasPlot) ...[
          _SectionHeader(title: 'Synopsis', icon: Icons.description),
          const SizedBox(height: KylosSpacing.s),
          Container(
            padding: const EdgeInsets.all(KylosSpacing.m),
            decoration: BoxDecoration(
              color: KylosColors.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(KylosRadius.m),
            ),
            child: Text(
              movie.plot!,
              style: KylosTvTextStyles.body.copyWith(
                height: 1.7,
                color: KylosColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: KylosSpacing.xl),
        ],

        // Cast & Crew Section
        if (hasDirector || hasCast) ...[
          _SectionHeader(title: 'Cast & Crew', icon: Icons.people),
          const SizedBox(height: KylosSpacing.s),
          Container(
            padding: const EdgeInsets.all(KylosSpacing.m),
            decoration: BoxDecoration(
              color: KylosColors.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(KylosRadius.m),
            ),
            child: Column(
              children: [
                if (hasDirector) ...[
                  _DetailRow(
                    icon: Icons.movie_creation,
                    label: 'Director',
                    value: movie.director!,
                  ),
                  if (hasCast) const SizedBox(height: KylosSpacing.m),
                ],
                if (hasCast)
                  _DetailRow(
                    icon: Icons.group,
                    label: 'Cast',
                    value: movie.cast!,
                    multiLine: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: KylosSpacing.xl),
        ],

        // Additional Details Section
        if (hasGenre || hasCategory || movie.containerExtension != null) ...[
          _SectionHeader(title: 'Details', icon: Icons.info_outline),
          const SizedBox(height: KylosSpacing.s),
          Container(
            padding: const EdgeInsets.all(KylosSpacing.m),
            decoration: BoxDecoration(
              color: KylosColors.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(KylosRadius.m),
            ),
            child: Column(
              children: [
                if (hasGenre) ...[
                  _DetailRow(
                    icon: Icons.category,
                    label: 'Genre',
                    value: movie.genre!,
                  ),
                  if (hasCategory || movie.containerExtension != null)
                    const SizedBox(height: KylosSpacing.m),
                ],
                if (hasCategory) ...[
                  _DetailRow(
                    icon: Icons.folder,
                    label: 'Category',
                    value: movie.categoryName!,
                  ),
                  if (movie.containerExtension != null)
                    const SizedBox(height: KylosSpacing.m),
                ],
                if (movie.containerExtension != null)
                  _DetailRow(
                    icon: Icons.video_file,
                    label: 'Format',
                    value: movie.containerExtension!.toUpperCase(),
                  ),
              ],
            ),
          ),
        ],

        // Bottom spacing
        const SizedBox(height: KylosSpacing.xl),
      ],
    );
  }

  Widget _buildNoInfoAvailable() {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.xl),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: Border.all(color: KylosColors.buttonBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            'No additional information available',
            style: KylosTvTextStyles.body.copyWith(
              color: KylosColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KylosSpacing.xs),
          Text(
            'Press play to start watching',
            style: KylosTvTextStyles.metadata.copyWith(
              color: KylosColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable Widgets
// =============================================================================

/// Section header with icon and title
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: KylosColors.tvAccent,
        ),
        const SizedBox(width: KylosSpacing.s),
        Text(
          title,
          style: KylosTvTextStyles.sectionHeader.copyWith(
            fontSize: 18,
            color: KylosColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Detail row with icon, label, and value
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: KylosColors.surfaceOverlay,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: KylosColors.tvAccent.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: KylosSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: KylosTvTextStyles.metadata.copyWith(
                  color: KylosColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: KylosTvTextStyles.body.copyWith(
                  color: KylosColors.textPrimary,
                  fontSize: 15,
                  height: multiLine ? 1.5 : 1.2,
                ),
                maxLines: multiLine ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary play button with prominent styling.
class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: KylosDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (hasFocus) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: KylosSpacing.xl,
              vertical: KylosSpacing.m,
            ),
            decoration: BoxDecoration(
              color: KylosColors.tvAccent,
              borderRadius: BorderRadius.circular(KylosRadius.m),
              border: _isFocused
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: KylosColors.tvAccent.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: KylosSpacing.s),
                Text(
                  widget.label,
                  style: KylosTvTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.l,
            vertical: KylosSpacing.m,
          ),
          decoration: BoxDecoration(
            color: _isFocused
                ? KylosColors.surfaceLight
                : KylosColors.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: Border.all(
              color: _isFocused ? KylosColors.tvAccent : KylosColors.buttonBorder,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isFocused ? KylosColors.tvAccent : KylosColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: KylosSpacing.s),
              Text(
                widget.label,
                style: KylosTvTextStyles.button.copyWith(
                  color: _isFocused ? KylosColors.tvAccent : KylosColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon button.
class _IconButton extends StatefulWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
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
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.all(KylosSpacing.s),
          decoration: BoxDecoration(
            color: _isFocused
                ? KylosColors.tvAccent.withOpacity(0.3)
                : Colors.black38,
            borderRadius: BorderRadius.circular(KylosRadius.s),
            border: _isFocused
                ? Border.all(color: KylosColors.tvAccent, width: 2)
                : null,
          ),
          child: Icon(
            widget.icon,
            color: _isFocused
                ? KylosColors.tvAccent
                : widget.color ?? KylosColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Metadata chip with optional icon.
class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.s,
        vertical: KylosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(KylosRadius.s),
        border: Border.all(color: KylosColors.buttonBorder.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: KylosColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: KylosTvTextStyles.metadata.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Rating chip with star.
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.s,
        vertical: KylosSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.3),
            Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(KylosRadius.s),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            rating,
            style: KylosTvTextStyles.metadata.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Format chip (4K, HD).
class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.format});

  final String format;

  @override
  Widget build(BuildContext context) {
    final is4K = format == '4K';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.s,
        vertical: KylosSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: is4K
            ? LinearGradient(
                colors: [Colors.amber.shade700, Colors.orange.shade700],
              )
            : null,
        color: is4K ? null : KylosColors.surfaceLight,
        borderRadius: BorderRadius.circular(KylosRadius.s),
      ),
      child: Text(
        format,
        style: KylosTvTextStyles.badge.copyWith(
          color: is4K ? Colors.white : KylosColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
