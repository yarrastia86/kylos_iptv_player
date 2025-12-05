// Kylos IPTV Player - Movie Poster Card
// Focusable movie poster card optimized for TV/D-pad and touch navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';

/// A focusable movie poster card for grid layouts.
///
/// Provides clear visual feedback when focused and handles D-pad select events.
/// Optimized for both TV (D-pad) and mobile (touch) navigation.
class MoviePosterCard extends StatefulWidget {
  const MoviePosterCard({
    super.key,
    required this.movie,
    this.width = 150,
    this.isPlaying = false,
    this.autofocus = false,
    this.onSelect,
    this.onFocusChange,
    this.onLongPress,
    this.focusNode,
  });

  /// The movie to display.
  final VodMovie movie;

  /// Width of the card. Height is calculated based on 2:3 aspect ratio.
  final double width;

  /// Whether this movie is currently playing.
  final bool isPlaying;

  /// Whether this card should auto-focus on build.
  final bool autofocus;

  /// Callback when the card is selected (enter/OK pressed or tapped).
  final VoidCallback? onSelect;

  /// Callback when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Callback for long press (e.g., toggle favorite).
  final VoidCallback? onLongPress;

  /// Optional external focus node.
  final FocusNode? focusNode;

  @override
  State<MoviePosterCard> createState() => _MoviePosterCardState();
}

class _MoviePosterCardState extends State<MoviePosterCard>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: KylosDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(MoviePosterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsNode) {
        _focusNode.dispose();
      }
      _ownsNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() => _isFocused = hasFocus);
      widget.onFocusChange?.call(hasFocus);

      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle select/enter for primary action
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }

    // Handle F key for favorite toggle
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      widget.onLongPress?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Extract year from release date string (e.g., "2024-05-15" -> "2024")
  String? get _year {
    final date = widget.movie.releaseDate;
    if (date == null || date.isEmpty) return null;
    if (date.contains('-')) return date.split('-').first;
    if (date.length >= 4) return date.substring(0, 4);
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.5; // 2:3 aspect ratio

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: KylosDurations.fast,
                width: widget.width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KylosRadius.m),
                  border: _isFocused
                      ? Border.all(
                          color: KylosColors.moviesGlow,
                          width: 3,
                        )
                      : widget.isPlaying
                          ? Border.all(
                              color: KylosColors.moviesGlow.withOpacity(0.6),
                              width: 2,
                            )
                          : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: KylosColors.moviesGlow.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _isFocused ? KylosRadius.m - 3 : KylosRadius.m,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Poster image
                      _buildPoster(),

                      // Bottom gradient overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: height * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                KylosColors.backgroundStart.withOpacity(0.7),
                                KylosColors.backgroundStart.withOpacity(0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Title and year at bottom
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.movie.name,
                              style: TextStyle(
                                color: _isFocused
                                    ? KylosColors.moviesGlow
                                    : KylosColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_year != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _year!,
                                style: TextStyle(
                                  color: KylosColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Favorite heart icon (top-left)
                      if (widget.movie.isFavorite)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 14,
                            ),
                          ),
                        ),

                      // Rating badge (top-right)
                      if (widget.movie.rating != null &&
                          widget.movie.rating!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.movie.rating!,
                                  style: const TextStyle(
                                    color: KylosColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Playing indicator
                      if (widget.isPlaying)
                        Positioned(
                          top: 8,
                          left: widget.movie.isFavorite ? 34 : 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: KylosColors.moviesGlow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'PLAYING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.movie.posterUrl;
    if (posterUrl != null && posterUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: Center(
        child: Icon(
          Icons.movie,
          size: widget.width * 0.3,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }
}
