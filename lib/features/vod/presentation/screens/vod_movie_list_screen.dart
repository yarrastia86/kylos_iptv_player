// Kylos IPTV Player - VOD Movie List Screen
// Screen for displaying movies in a category with poster grid layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/features/vod/presentation/widgets/movie_poster_card.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for displaying movies in a category.
///
/// Features a lean-back TV-optimized layout with:
/// - LEFT: Horizontal scrolling rows of movie posters
/// - RIGHT: Focused movie info panel with actions
class VodMovieListScreen extends ConsumerStatefulWidget {
  const VodMovieListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  /// The ID of the category to display movies for.
  final String categoryId;

  /// Optional display name of the category.
  final String? categoryName;

  @override
  ConsumerState<VodMovieListScreen> createState() => _VodMovieListScreenState();
}

class _VodMovieListScreenState extends ConsumerState<VodMovieListScreen> {
  VodMovie? _focusedMovie;
  final ScrollController _scrollController = ScrollController();

  // Grid configuration
  static const _cardWidth = 150.0;
  static const _cardSpacing = 16.0;
  static const _rowHeight = 225.0 + 16.0; // Card height + padding

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    final notifier = ref.read(movieListNotifierProvider.notifier);
    await notifier.selectCategory(widget.categoryId);
  }

  void _handleBack() {
    context.go(Routes.vod);
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  void _handleMore() {
    // TODO: Implement options menu
  }

  void _onMovieSelect(VodMovie movie) {
    // Navigate to movie details screen
    context.push(Routes.movieDetailPath(movie.id));
  }

  void _onMovieFocus(VodMovie movie) {
    setState(() => _focusedMovie = movie);
  }

  void _onMovieFavoriteToggle(VodMovie movie) {
    ref.read(movieListNotifierProvider.notifier).toggleFavorite(movie.id);
  }

  void _playMovie(VodMovie movie) {
    // Navigate to detail screen which handles playback
    context.push(Routes.movieDetailPath(movie.id));
  }

  /// Calculate how many movies fit per row based on available width.
  int _calculateMoviesPerRow(double availableWidth) {
    final totalCardWidth = _cardWidth + _cardSpacing;
    return ((availableWidth - KylosSpacing.xxl * 2) / totalCardWidth).floor().clamp(4, 10);
  }

  /// Group movies into rows for horizontal scrolling.
  List<List<VodMovie>> _groupMoviesIntoRows(List<VodMovie> movies, int moviesPerRow) {
    final rows = <List<VodMovie>>[];
    for (var i = 0; i < movies.length; i += moviesPerRow) {
      final end = (i + moviesPerRow < movies.length) ? i + moviesPerRow : movies.length;
      rows.add(movies.sublist(i, end));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieListNotifierProvider);

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
              _buildTopBar(),
              Expanded(
                child: _buildContent(movieState),
              ),
              _buildBottomHints(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.m,
        vertical: KylosSpacing.s,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: KylosColors.textPrimary),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.categoryName?.toUpperCase() ?? 'MOVIES',
                style: const TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: KylosColors.textSecondary),
            onPressed: _handleSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: KylosColors.textSecondary),
            onPressed: _handleMore,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MovieListState movieState) {
    if (movieState.isLoading && movieState.movies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.moviesGlow,
        ),
      );
    }

    if (movieState.error != null) {
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
              'Failed to load movies',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            Text(
              movieState.error!,
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KylosSpacing.l),
            FilledButton.icon(
              onPressed: _loadMovies,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (movieState.movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: KylosColors.textMuted,
            ),
            SizedBox(height: KylosSpacing.m),
            Text(
              'No movies in this category',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Set initial focused movie if not set
    if (_focusedMovie == null && movieState.movies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _focusedMovie = movieState.movies.first);
        }
      });
    }

    return Row(
      children: [
        // Left: Movie poster grid (70%)
        Expanded(
          flex: 7,
          child: _buildMovieGrid(movieState),
        ),
        // Right: Movie info panel (30%)
        Expanded(
          flex: 3,
          child: _buildMovieInfoPanel(_focusedMovie),
        ),
      ],
    );
  }

  Widget _buildMovieGrid(MovieListState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final moviesPerRow = _calculateMoviesPerRow(constraints.maxWidth);
        final movieRows = _groupMoviesIntoRows(state.movies, moviesPerRow);

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 300) {
                ref.read(movieListNotifierProvider.notifier).loadNextPage();
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: KylosSpacing.s),
            itemCount: movieRows.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, rowIndex) {
              if (rowIndex >= movieRows.length) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: KylosColors.moviesGlow,
                    ),
                  ),
                );
              }

              final row = movieRows[rowIndex];
              return _buildMovieRow(row, rowIndex, rowIndex == 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildMovieRow(List<VodMovie> movies, int rowIndex, bool autofocusFirst) {
    return SizedBox(
      height: _rowHeight + KylosSpacing.m,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.xxl),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final isFirst = rowIndex == 0 && index == 0;

          return Padding(
            padding: EdgeInsets.only(
              right: index < movies.length - 1 ? _cardSpacing : 0,
            ),
            child: MoviePosterCard(
              movie: movie,
              width: _cardWidth,
              autofocus: autofocusFirst && isFirst,
              onSelect: () => _onMovieSelect(movie),
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _onMovieFocus(movie);
                }
              },
              onLongPress: () => _onMovieFavoriteToggle(movie),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieInfoPanel(VodMovie? movie) {
    if (movie == null) {
      return Container(
        margin: const EdgeInsets.all(KylosSpacing.m),
        padding: const EdgeInsets.all(KylosSpacing.m),
        decoration: BoxDecoration(
          color: KylosColors.surfaceDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(KylosRadius.m),
        ),
        child: const Center(
          child: Text(
            'Select a movie',
            style: TextStyle(color: KylosColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(KylosRadius.m),
      ),
      child: Column(
        children: [
          // Poster image (top 40%)
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(KylosRadius.m),
                topRight: Radius.circular(KylosRadius.m),
              ),
              child: _buildPosterImage(movie),
            ),
          ),
          // Info section (bottom 60%)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KylosSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.name,
                    style: const TextStyle(
                      color: KylosColors.moviesGlow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KylosSpacing.s),

                  // Metadata row
                  Wrap(
                    spacing: KylosSpacing.s,
                    runSpacing: KylosSpacing.xs,
                    children: [
                      if (movie.releaseDate != null)
                        _MetadataChip(
                          icon: Icons.calendar_today,
                          label: movie.releaseDate!.split('-').first,
                        ),
                      if (movie.rating != null)
                        _MetadataChip(
                          icon: Icons.star,
                          label: movie.rating!,
                          iconColor: Colors.amber,
                        ),
                      if (movie.duration != null)
                        _MetadataChip(
                          icon: Icons.timer,
                          label: movie.duration!,
                        ),
                    ],
                  ),

                  if (movie.genre != null) ...[
                    const SizedBox(height: KylosSpacing.s),
                    Text(
                      movie.genre!,
                      style: const TextStyle(
                        color: KylosColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  if (movie.plot != null) ...[
                    const SizedBox(height: KylosSpacing.m),
                    Text(
                      movie.plot!,
                      style: const TextStyle(
                        color: KylosColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: KylosSpacing.m),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.play_arrow,
                          label: 'Play',
                          isPrimary: true,
                          onPressed: () => _playMovie(movie),
                        ),
                      ),
                      const SizedBox(width: KylosSpacing.s),
                      _ActionButton(
                        icon: movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                        label: movie.isFavorite ? 'Saved' : 'Save',
                        iconColor: movie.isFavorite ? Colors.red : null,
                        onPressed: () => _onMovieFavoriteToggle(movie),
                      ),
                    ],
                  ),

                  if (movie.director != null || movie.cast != null) ...[
                    const SizedBox(height: KylosSpacing.m),
                    if (movie.director != null)
                      Text(
                        'Director: ${movie.director}',
                        style: const TextStyle(
                          color: KylosColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    if (movie.cast != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cast: ${movie.cast}',
                        style: const TextStyle(
                          color: KylosColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterImage(VodMovie movie) {
    final posterUrl = movie.posterUrl;
    if (posterUrl != null && posterUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => _buildPosterPlaceholder(),
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
          size: 48,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildBottomHints() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _HintChip(icon: Icons.arrow_back, label: 'Navigate'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.check, label: 'Select'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.keyboard_return, label: 'F = Favorite'),
        ],
      ),
    );
  }
}

/// Metadata chip for displaying movie info.
class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
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
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: KylosColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: iconColor ?? KylosColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: KylosColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for the info panel.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? iconColor;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isPrimary ? KylosColors.moviesGlow : KylosColors.buttonBackground;
    final focusedColor = widget.isPrimary
        ? KylosColors.moviesGlow.withOpacity(0.8)
        : KylosColors.moviesGlow.withOpacity(0.3);

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.m,
            vertical: KylosSpacing.s,
          ),
          decoration: BoxDecoration(
            color: _isFocused ? focusedColor : baseColor,
            borderRadius: BorderRadius.circular(KylosRadius.s),
            border: _isFocused
                ? Border.all(color: KylosColors.moviesGlow, width: 2)
                : widget.isPrimary
                    ? null
                    : Border.all(color: KylosColors.buttonBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.iconColor ??
                    (widget.isPrimary ? Colors.white : KylosColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? Colors.white : KylosColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hint chip for keyboard shortcuts.
class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: KylosColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: KylosColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
