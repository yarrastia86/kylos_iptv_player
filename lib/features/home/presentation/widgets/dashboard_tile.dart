// Kylos IPTV Player - Dashboard Tile
// Large gradient tile for main dashboard navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A large gradient tile for the main dashboard.
///
/// Displays an icon and title with a gradient background.
/// Supports both touch and D-pad/remote navigation.
class DashboardTile extends StatefulWidget {
  const DashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  /// The title displayed on the tile.
  final String title;

  /// The icon displayed on the tile.
  final IconData icon;

  /// The gradient background colors.
  final List<Color> gradient;

  /// Callback when the tile is tapped or selected.
  final VoidCallback onTap;

  /// Optional focus node for TV navigation.
  final FocusNode? focusNode;

  /// Whether this tile should be focused initially.
  final bool autofocus;

  @override
  State<DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<DashboardTile>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
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
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              border: _isFocused
                  ? Border.all(
                      color: Colors.white,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first.withOpacity(_isFocused ? 0.6 : 0.3),
                  blurRadius: _isFocused ? 24 : 16,
                  offset: const Offset(0, 8),
                  spreadRadius: _isFocused ? 2 : 0,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 160;
                final iconSize = isSmall ? 48.0 : 64.0;
                final fontSize = isSmall ? 14.0 : 18.0;
                final padding = isSmall ? 12.0 : 24.0;
                final spacing = isSmall ? 8.0 : 16.0;

                return Stack(
                  children: [
                    // Subtle overlay pattern
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CustomPaint(
                          painter: _TilePatternPainter(),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                          SizedBox(height: spacing),
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for subtle tile pattern overlay.
class _TilePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal lines
    for (var i = -size.height; i < size.width + size.height; i += 40) {
      final path = Path()
        ..moveTo(i.toDouble(), 0)
        ..lineTo(i + size.height, size.height)
        ..lineTo(i + size.height + 2, size.height)
        ..lineTo(i + 2, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
