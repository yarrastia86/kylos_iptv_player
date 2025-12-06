// Kylos IPTV Player - Series Poster Card
// Focusable series poster card optimized for TV/D-pad and touch navigation.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';

/// A focusable series poster card for grid layouts.
///
/// Provides clear visual feedback when focused and handles D-pad select events.
/// Optimized for both TV (D-pad) and mobile (touch) navigation.
class SeriesPosterCard extends StatefulWidget {
  const SeriesPosterCard({
    super.key,
    required this.series,
    this.width = 180,
    this.autofocus = false,
    this.onSelect,
    this.onFocusChange,
    this.onLongPress,
    this.focusNode,
  });

  /// The series to display.
  final Series series;

  /// Width of the card. Height is calculated based on 2:3 aspect ratio.
  final double width;

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
  State<SeriesPosterCard> createState() => _SeriesPosterCardState();
}

class _SeriesPosterCardState extends State<SeriesPosterCard>
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
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(SeriesPosterCard oldWidget) {
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

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      widget.onLongPress?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String? get _year {
    final date = widget.series.releaseDate;
    if (date == null || date.isEmpty) return null;
    if (date.contains('-')) return date.split('-').first;
    if (date.length >= 4) return date.substring(0, 4);
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.5;

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
                          color: KylosColors.seriesGlow,
                          width: 4,
                        )
                      : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: KylosColors.seriesGlow.withOpacity(0.5),
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
                      _buildPoster(),
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
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.series.name,
                              style: KylosTvTextStyles.cardTitle.copyWith(
                                color: _isFocused
                                    ? KylosColors.seriesGlow
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
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.series.isFavorite)
                              _Badge(
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            if (widget.series.rating != null &&
                                widget.series.rating!.isNotEmpty)
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
                                      widget.series.rating!,
                                      style: KylosTvTextStyles.badge,
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
    final coverUrl = widget.series.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
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
          Icons.tv_outlined,
          size: widget.width * 0.25,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }
}

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
