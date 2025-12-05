// Kylos IPTV Player - Movie Details Screen
// Detailed view for a VOD movie with playback option.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

/// Screen showing detailed information about a movie.
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
  VodMovie? _movie;
  WatchProgress? _watchProgress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovie();
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
        _error = 'Failed to load movie: $e';
        _isLoading = false;
      });
    }
  }

  void _playMovie({bool fromBeginning = false}) {
    final movie = _movie;
    if (movie == null) return;

    // Create playable content
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

    // Start playback
    ref.read(playbackNotifierProvider.notifier).play(content);

    // Navigate to player
    context.push(Routes.player);
  }

  Duration? _parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;

    // Try parsing various formats: "01:30:00", "90", "90 min"
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

  @override
  Widget build(BuildContext context) {
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KylosColors.moviesGlow),
      );
    }

    if (_error != null) {
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
            Text(
              _error!,
              style: const TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: KylosSpacing.l),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    final movie = _movie!;
    return _buildMovieDetails(movie);
  }

  Widget _buildMovieDetails(VodMovie movie) {
    return CustomScrollView(
      slivers: [
        // App bar with poster background
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: KylosColors.surfaceDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: movie.isFavorite ? Colors.red : KylosColors.textSecondary,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Poster image
                if (movie.posterUrl != null && movie.posterUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildPosterPlaceholder(movie),
                  )
                else
                  _buildPosterPlaceholder(movie),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        KylosColors.backgroundStart.withOpacity(0.8),
                        KylosColors.backgroundStart,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Movie info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KylosSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  movie.name,
                  style: const TextStyle(
                    color: KylosColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KylosSpacing.s),

                // Metadata row
                _buildMetadataRow(movie),
                const SizedBox(height: KylosSpacing.m),

                // Play buttons
                _buildPlayButtons(),
                const SizedBox(height: KylosSpacing.l),

                // Plot
                if (movie.plot != null && movie.plot!.isNotEmpty) ...[
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      color: KylosColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.s),
                  Text(
                    movie.plot!,
                    style: const TextStyle(
                      color: KylosColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: KylosSpacing.l),
                ],

                // Additional info
                _buildInfoSection(movie),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterPlaceholder(VodMovie movie) {
    return Container(
      color: KylosColors.surfaceDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie,
              size: 64,
              color: KylosColors.textMuted,
            ),
            const SizedBox(height: KylosSpacing.s),
            Text(
              movie.name,
              style: const TextStyle(
                color: KylosColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(VodMovie movie) {
    final items = <Widget>[];

    if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty) {
      // Extract year
      final year = movie.releaseDate!.length >= 4
          ? movie.releaseDate!.substring(0, 4)
          : movie.releaseDate;
      items.add(_buildMetadataChip(year!));
    }

    if (movie.duration != null && movie.duration!.isNotEmpty) {
      items.add(_buildMetadataChip(movie.duration!));
    }

    if (movie.rating != null && movie.rating!.isNotEmpty) {
      items.add(_buildRatingChip(movie.rating!));
    }

    if (movie.genre != null && movie.genre!.isNotEmpty) {
      items.add(_buildMetadataChip(movie.genre!));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: KylosSpacing.s,
      runSpacing: KylosSpacing.xs,
      children: items,
    );
  }

  Widget _buildMetadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.s,
        vertical: KylosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: KylosColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRatingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.s,
        vertical: KylosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButtons() {
    final hasProgress = _watchProgress != null && _watchProgress!.canResume;

    return Row(
      children: [
        // Main play button
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () => _playMovie(fromBeginning: !hasProgress),
            style: FilledButton.styleFrom(
              backgroundColor: KylosColors.moviesGlow,
              padding: const EdgeInsets.symmetric(vertical: KylosSpacing.m),
            ),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: Text(
              hasProgress ? 'Resume' : 'Play',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Play from beginning (if has progress)
        if (hasProgress) ...[
          const SizedBox(width: KylosSpacing.s),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _playMovie(fromBeginning: true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: KylosSpacing.m),
                side: BorderSide(
                  color: KylosColors.textSecondary.withOpacity(0.5),
                ),
              ),
              child: const Text(
                'Restart',
                style: TextStyle(
                  color: KylosColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(VodMovie movie) {
    final infoItems = <Widget>[];

    if (movie.director != null && movie.director!.isNotEmpty) {
      infoItems.add(_buildInfoRow('Director', movie.director!));
    }

    if (movie.cast != null && movie.cast!.isNotEmpty) {
      infoItems.add(_buildInfoRow('Cast', movie.cast!));
    }

    if (movie.categoryName != null && movie.categoryName!.isNotEmpty) {
      infoItems.add(_buildInfoRow('Category', movie.categoryName!));
    }

    if (infoItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            color: KylosColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: KylosSpacing.s),
        ...infoItems,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KylosSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: KylosColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
