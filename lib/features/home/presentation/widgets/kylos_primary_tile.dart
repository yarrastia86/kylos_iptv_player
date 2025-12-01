// Kylos IPTV Player - Primary Dashboard Tile
// Large gradient tile for main navigation (Live TV, Movies, Series).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// A large gradient tile for the main dashboard navigation.
///
/// Features smooth animations for focus, hover, and press states.
/// Supports both touch and D-pad/remote navigation.
class KylosPrimaryTile extends StatefulWidget {
  const KylosPrimaryTile({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool compact;

  @override
  State<KylosPrimaryTile> createState() => _KylosPrimaryTileState();
}

class _KylosPrimaryTileState extends State<KylosPrimaryTile>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  bool _isFocused = false;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _pressController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onTap();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  bool get _isActive => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    final width = widget.compact
        ? KylosDimensions.tileWidthCompact
        : KylosDimensions.tileWidth;
    final height = widget.compact
        ? KylosDimensions.tileHeightCompact
        : KylosDimensions.tileHeight;
    final iconSize = widget.compact
        ? KylosDimensions.tileIconSizeCompact
        : KylosDimensions.tileIconSize;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: _pressAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _pressAnimation.value : 1.0,
                child: child,
              );
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: _isActive ? 1.04 : 1.0),
              duration: KylosDurations.normal,
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: SizedBox(
                width: width,
                height: height,
                child: _buildTileContent(iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent(double iconSize) {
    return AnimatedContainer(
      duration: KylosDurations.normal,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradient,
        ),
        borderRadius: BorderRadius.circular(KylosRadius.xxl),
        border: _isActive
            ? Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2,
              )
            : null,
        boxShadow: [
          // Base shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          // Glow effect
          BoxShadow(
            color: widget.glowColor.withOpacity(_isActive ? 0.5 : 0.25),
            blurRadius: _isActive ? 32 : 20,
            spreadRadius: _isActive ? 2 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KylosRadius.xxl),
              child: CustomPaint(
                painter: _TilePatternPainter(opacity: _isActive ? 0.08 : 0.04),
              ),
            ),
          ),
          // Inner highlight (top edge)
          Positioned(
            top: 0,
            left: KylosSpacing.xl,
            right: KylosSpacing.xl,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: KylosDurations.normal,
                  child: Icon(
                    widget.icon,
                    size: iconSize,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.compact ? KylosSpacing.s : KylosSpacing.m),
                Text(
                  widget.title,
                  style: KylosTextStyles.tileLabel.copyWith(
                    fontSize: widget.compact ? 14 : 18,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for subtle diagonal pattern overlay.
class _TilePatternPainter extends CustomPainter {
  _TilePatternPainter({this.opacity = 0.05});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal lines
    const spacing = 30.0;
    for (var i = -size.height; i < size.width + size.height; i += spacing) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + size.height, size.height)
        ..lineTo(i + size.height + 1.5, size.height)
        ..lineTo(i + 1.5, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TilePatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
