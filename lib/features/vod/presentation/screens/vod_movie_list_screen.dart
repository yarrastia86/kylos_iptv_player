// Kylos IPTV Player - VOD Movie List Screen
// Screen for displaying movies in a category with mini player.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/iptv_player_view.dart'
    show NoVideoControls;
import 'package:media_kit_video/media_kit_video.dart' hide NoVideoControls;

/// Screen for displaying movies in a category.
///
/// Features a two-column layout with:
/// - LEFT: Scrollable movie list
/// - RIGHT TOP: Mini player
/// - RIGHT BOTTOM: Movie info panel
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
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load movies for this category
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
    // Pass the categoryId directly - selectCategory handles special categories
    await notifier.selectCategory(widget.categoryId);
  }

  void _handleBack() {
    // Stop playback before navigating away
    ref.read(playbackNotifierProvider.notifier).stop();
    context.go(Routes.vod);
  }

  void _handleSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search - Coming Soon')),
    );
  }

  void _handleMore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Options - Coming Soon')),
    );
  }

  void _playMovie(VodMovie movie) {
    // Start playback with PlayableContent
    final content = PlayableContent(
      id: movie.id,
      title: movie.name,
      streamUrl: movie.streamUrl,
      type: ContentType.vod,
      logoUrl: movie.posterUrl,
      categoryName: movie.categoryName,
    );
    ref.read(playbackNotifierProvider.notifier).play(content);
  }

  void _goFullscreen() {
    context.push(Routes.player);
  }

  void _onMovieSelected(int index, VodMovie movie) {
    setState(() => _selectedIndex = index);
    _playMovie(movie);
  }

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieListNotifierProvider);
    final playbackState = ref.watch(playbackNotifierProvider);
    final videoController = ref.watch(videoControllerProvider);

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
                child: _buildContent(
                  movieState,
                  playbackState,
                  videoController,
                ),
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

  Widget _buildContent(
    MovieListState movieState,
    PlaybackState playbackState,
    VideoController? videoController,
  ) {
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

    return Row(
      children: [
        // Left: Movie list (60%)
        Expanded(
          flex: 6,
          child: _buildMovieList(movieState),
        ),
        // Right: Player + Info (40%)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // Mini player
              Expanded(
                flex: 5,
                child: _buildMiniPlayer(
                  playbackState,
                  videoController,
                  movieState.movies.isNotEmpty && _selectedIndex < movieState.movies.length
                      ? movieState.movies[_selectedIndex]
                      : null,
                ),
              ),
              // Movie info
              Expanded(
                flex: 5,
                child: _buildMovieInfo(
                  movieState.movies.isNotEmpty && _selectedIndex < movieState.movies.length
                      ? movieState.movies[_selectedIndex]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieList(MovieListState state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            ref.read(movieListNotifierProvider.notifier).loadNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: state.movies.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.movies.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: KylosColors.moviesGlow,
                ),
              ),
            );
          }

          final movie = state.movies[index];
          final isSelected = index == _selectedIndex;

          return _buildMovieRow(movie, index, isSelected);
        },
      ),
    );
  }

  Widget _buildMovieRow(VodMovie movie, int index, bool isSelected) {
    return InkWell(
      onTap: () => _onMovieSelected(index, movie),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KylosColors.moviesGlow.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: KylosColors.moviesGlow, width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 50,
                height: 70,
                child: movie.posterUrl != null
                    ? Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: KylosColors.surfaceDark,
                          child: const Icon(
                            Icons.movie,
                            color: KylosColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        color: KylosColors.surfaceDark,
                        child: const Icon(
                          Icons.movie,
                          color: KylosColors.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    style: TextStyle(
                      color: isSelected
                          ? KylosColors.moviesGlow
                          : KylosColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (movie.releaseDate != null || movie.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (movie.releaseDate != null) ...[
                          Text(
                            movie.releaseDate!.split('-').first,
                            style: const TextStyle(
                              color: KylosColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (movie.rating != null) const SizedBox(width: 8),
                        ],
                        if (movie.rating != null) ...[
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            movie.rating!,
                            style: const TextStyle(
                              color: KylosColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Favorite button
            IconButton(
              icon: Icon(
                movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: movie.isFavorite ? Colors.red : KylosColors.textMuted,
              ),
              onPressed: () {
                ref.read(movieListNotifierProvider.notifier).toggleFavorite(movie.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(
    PlaybackState playbackState,
    VideoController? videoController,
    VodMovie? selectedMovie,
  ) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoController != null &&
                playbackState.status != PlaybackStatus.idle)
              Video(
                controller: videoController,
                controls: NoVideoControls,
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(
                    Icons.movie,
                    size: 48,
                    color: KylosColors.textMuted,
                  ),
                ),
              ),
            // Loading indicator
            if (playbackState.status == PlaybackStatus.buffering)
              const Center(
                child: CircularProgressIndicator(
                  color: KylosColors.moviesGlow,
                ),
              ),
            // Fullscreen button
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white70,
                ),
                onPressed: _goFullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo(VodMovie? movie) {
    if (movie == null) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KylosColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
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
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movie.name,
              style: const TextStyle(
                color: KylosColors.moviesGlow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (movie.releaseDate != null) ...[
                  const Icon(Icons.calendar_today, size: 14, color: KylosColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    movie.releaseDate!.split('-').first,
                    style: const TextStyle(color: KylosColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (movie.rating != null) ...[
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    movie.rating!,
                    style: const TextStyle(color: KylosColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (movie.duration != null) ...[
                  const Icon(Icons.timer, size: 14, color: KylosColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    movie.duration!,
                    style: const TextStyle(color: KylosColors.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
            if (movie.genre != null) ...[
              const SizedBox(height: 8),
              Text(
                movie.genre!,
                style: const TextStyle(
                  color: KylosColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (movie.plot != null) ...[
              const SizedBox(height: 12),
              Text(
                movie.plot!,
                style: const TextStyle(
                  color: KylosColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (movie.director != null) ...[
              const SizedBox(height: 8),
              Text(
                'Director: ${movie.director}',
                style: const TextStyle(
                  color: KylosColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
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
          _HintChip(icon: Icons.arrow_upward, label: 'Navigate'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.check, label: 'Play'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.favorite, label: 'Favorite'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.fullscreen, label: 'Fullscreen'),
        ],
      ),
    );
  }
}

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
