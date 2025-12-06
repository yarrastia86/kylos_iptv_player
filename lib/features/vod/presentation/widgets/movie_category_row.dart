// Kylos IPTV Player - Movie Category Row
// Horizontal scrolling row of movie poster cards with automatic scroll on focus.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/widgets/movie_poster_card.dart';

/// A horizontal row of movie poster cards with automatic scrolling on focus.
///
/// Used to display movies in a category with Netflix-style horizontal scrolling.
/// Optimized for both TV (D-pad) and mobile (touch) navigation.
class MovieCategoryRow extends StatefulWidget {
  const MovieCategoryRow({
    super.key,
    required this.title,
    required this.movies,
    this.currentMovieId,
    this.autofocusFirst = false,
    this.onMovieSelect,
    this.onMovieFocus,
    this.onMovieFavoriteToggle,
    this.onSeeAll,
    this.showSeeAll = true,
    this.cardWidth = 150,
  });

  /// Title of the row (e.g., "Action", "Comedy").
  final String title;

  /// List of movies to display.
  final List<VodMovie> movies;

  /// ID of the currently playing movie.
  final String? currentMovieId;

  /// Whether to auto-focus the first movie.
  final bool autofocusFirst;

  /// Callback when a movie is selected.
  final void Function(VodMovie movie)? onMovieSelect;

  /// Callback when a movie receives focus.
  final void Function(VodMovie movie)? onMovieFocus;

  /// Callback when favorite is toggled (long press or F key).
  final void Function(VodMovie movie)? onMovieFavoriteToggle;

  /// Callback when "See All" is pressed.
  final VoidCallback? onSeeAll;

  /// Whether to show the "See All" button.
  final bool showSeeAll;

  /// Width of each card.
  final double cardWidth;

  @override
  State<MovieCategoryRow> createState() => _MovieCategoryRowState();
}

class _MovieCategoryRowState extends State<MovieCategoryRow> {
  final ScrollController _scrollController = ScrollController();
  static const _cardSpacing = 16.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final cardWidth = widget.cardWidth;
    final offset = index * (cardWidth + _cardSpacing);
    final screenWidth = MediaQuery.of(context).size.width - 100; // Account for padding
    final targetOffset = offset - (screenWidth / 2) + (cardWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: KylosDurations.normal,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardHeight = widget.cardWidth * 1.5; // 2:3 aspect ratio

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row header with title and "See All" button
        Padding(
          padding: const EdgeInsets.only(
            left: KylosSpacing.xxl,
            right: KylosSpacing.m,
            bottom: KylosSpacing.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: KylosColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showSeeAll && widget.onSeeAll != null)
                _SeeAllButton(onPressed: widget.onSeeAll!),
            ],
          ),
        ),

        // Horizontal movie cards
        SizedBox(
          height: cardHeight + KylosSpacing.s, // Extra space for focus scale
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.xxl),
            itemCount: widget.movies.length,
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              final isPlaying = movie.id == widget.currentMovieId;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.movies.length - 1 ? _cardSpacing : 0,
                ),
                child: MoviePosterCard(
                  movie: movie,
                  width: widget.cardWidth,
                  isPlaying: isPlaying,
                  autofocus: widget.autofocusFirst && index == 0,
                  onSelect: () => widget.onMovieSelect?.call(movie),
                  onLongPress: () => widget.onMovieFavoriteToggle?.call(movie),
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _scrollToIndex(index);
                      widget.onMovieFocus?.call(movie);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A focusable "See All" button for the category row.
class _SeeAllButton extends StatefulWidget {
  const _SeeAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SeeAllButton> createState() => _SeeAllButtonState();
}

class _SeeAllButtonState extends State<_SeeAllButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.s,
            vertical: KylosSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isFocused
                ? KylosColors.moviesGlow.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(KylosRadius.s),
            border: _isFocused
                ? Border.all(color: KylosColors.moviesGlow, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See All',
                style: TextStyle(
                  color: _isFocused
                      ? KylosColors.moviesGlow
                      : KylosColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: _isFocused
                    ? KylosColors.moviesGlow
                    : KylosColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
