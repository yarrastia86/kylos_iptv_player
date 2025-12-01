// Kylos IPTV Player - Secondary Action Button
// Pill-shaped button for secondary dashboard actions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// A pill-shaped secondary action button for the dashboard.
///
/// Used for EPG, Multi-screen, Catch Up, etc.
/// Features subtle animations for focus and hover states.
class KylosSecondaryButton extends StatefulWidget {
  const KylosSecondaryButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.focusNode,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  State<KylosSecondaryButton> createState() => _KylosSecondaryButtonState();
}

class _KylosSecondaryButtonState extends State<KylosSecondaryButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
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

  bool get _isActive => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _isActive ? 1.02 : 1.0),
            duration: KylosDurations.fast,
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: _isPressed ? 0.97 : scale,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: KylosDurations.fast,
              curve: Curves.easeOutCubic,
              height: KylosDimensions.secondaryButtonHeight,
              padding: EdgeInsets.symmetric(
                horizontal: KylosSpacing.l,
                vertical: KylosSpacing.s,
              ),
              decoration: BoxDecoration(
                color: _isActive
                    ? KylosColors.buttonFocused
                    : _isPressed
                        ? KylosColors.surfaceLight
                        : KylosColors.buttonBackground,
                borderRadius: BorderRadius.circular(KylosRadius.xxl),
                border: Border.all(
                  color: _isActive
                      ? Colors.white.withOpacity(0.5)
                      : KylosColors.buttonBorder,
                  width: _isFocused ? 2 : 1,
                ),
                boxShadow: _isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: KylosDurations.fast,
                    child: Icon(
                      widget.icon,
                      color: _isActive
                          ? KylosColors.textPrimary
                          : KylosColors.textSecondary,
                      size: KylosDimensions.secondaryIconSize,
                    ),
                  ),
                  SizedBox(width: KylosSpacing.s),
                  AnimatedDefaultTextStyle(
                    duration: KylosDurations.fast,
                    style: KylosTextStyles.secondaryLabel.copyWith(
                      color: _isActive
                          ? KylosColors.textPrimary
                          : KylosColors.textSecondary,
                    ),
                    child: Text(widget.title),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
