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
    this.width = 180,
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
      end: 1.1, // Slightly larger scale for TV visibility
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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

  /// Determine format badge (HD, 4K, SD) from container extension or name
  String? get _formatBadge {
    final ext = widget.movie.containerExtension?.toLowerCase();
    final name = widget.movie.name.toLowerCase();

    if (name.contains('4k') || name.contains('2160p') || name.contains('uhd')) {
      return '4K';
    }
    if (name.contains('1080p') || name.contains('fhd')) {
      return 'HD';
    }
    if (name.contains('720p')) {
      return 'HD';
    }
    if (ext == 'mkv' || ext == 'mp4') {
      return 'HD'; // Assume HD for common formats
    }
    return null;
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
                          color: KylosColors.tvAccent,
                          width: 4,
                        )
                      : widget.isPlaying
                          ? Border.all(
                              color: KylosColors.tvAccentAlt.withOpacity(0.7),
                              width: 3,
                            )
                          : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: KylosColors.tvAccent.withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _isFocused ? KylosRadius.m - 4 : KylosRadius.m,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Poster image
                      _buildPoster(),

                      // Bottom gradient overlay for text
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: height * 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                KylosColors.backgroundStart.withOpacity(0.8),
                                KylosColors.backgroundStart,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Title at bottom
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.movie.name,
                              style: KylosTvTextStyles.cardTitle.copyWith(
                                color: _isFocused
                                    ? KylosColors.tvAccent
                                    : KylosColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_year != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _year!,
                                style: KylosTvTextStyles.cardSubtitle,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Top badges row
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Favorite badge
                            if (widget.movie.isFavorite)
                              _Badge(
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                              ),

                            // Spacer when no favorite
                            if (!widget.movie.isFavorite)
                              const SizedBox.shrink(),

                            // Right side badges
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Format badge (HD, 4K)
                                if (_formatBadge != null) ...[
                                  _Badge(
                                    color: _formatBadge == '4K'
                                        ? Colors.amber.shade700
                                        : KylosColors.surfaceLight,
                                    child: Text(
                                      _formatBadge!,
                                      style: KylosTvTextStyles.badge,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                // Rating badge
                                if (widget.movie.rating != null &&
                                    widget.movie.rating!.isNotEmpty)
                                  _Badge(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.movie.rating!,
                                          style: KylosTvTextStyles.badge,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Playing indicator
                      if (widget.isPlaying)
                        Positioned(
                          top: 10,
                          left: widget.movie.isFavorite ? 40 : 10,
                          child: _Badge(
                            color: KylosColors.tvAccentAlt,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
          Icons.movie_outlined,
          size: widget.width * 0.25,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }
}

/// Small badge widget for overlays.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
