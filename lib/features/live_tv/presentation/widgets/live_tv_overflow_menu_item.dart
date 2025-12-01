// Kylos IPTV Player - Live TV Overflow Menu Item
// Reusable menu item widget for the overflow menu.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// A single menu item for the Live TV overflow menu.
///
/// Displays an icon and label with focus/hover animations.
/// Designed for TV/remote navigation with D-pad support.
class LiveTvOverflowMenuItem extends StatefulWidget {
  const LiveTvOverflowMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
    this.focusNode,
  });

  /// Icon displayed on the left side of the menu item.
  final IconData icon;

  /// Text label for the menu item.
  final String label;

  /// Callback when the item is tapped or selected.
  final VoidCallback onTap;

  /// Whether this item should autofocus when the menu opens.
  final bool autofocus;

  /// Optional focus node for external control.
  final FocusNode? focusNode;

  @override
  State<LiveTvOverflowMenuItem> createState() => _LiveTvOverflowMenuItemState();
}

class _LiveTvOverflowMenuItemState extends State<LiveTvOverflowMenuItem> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isHighlighted => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        // Handle Enter/Select key
        if (event is KeyDownEvent) {
          if (event.logicalKey.keyLabel == 'Enter' ||
              event.logicalKey.keyLabel == 'Select') {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: KylosSpacing.m,
              vertical: KylosSpacing.s,
            ),
            decoration: BoxDecoration(
              color: _isHighlighted
                  ? KylosColors.buttonFocused
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.m),
              border: _isFocused
                  ? Border.all(
                      color: KylosColors.liveTvGlow.withOpacity(0.6),
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: KylosDurations.fast,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isHighlighted
                        ? KylosColors.liveTvGlow.withOpacity(0.2)
                        : KylosColors.surfaceOverlay,
                    borderRadius: BorderRadius.circular(KylosRadius.s),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHighlighted
                        ? KylosColors.liveTvGlow
                        : KylosColors.textSecondary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: KylosSpacing.m),

                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _isHighlighted
                          ? KylosColors.textPrimary
                          : KylosColors.textSecondary,
                      fontSize: 15,
                      fontWeight:
                          _isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Arrow indicator when focused
                AnimatedOpacity(
                  duration: KylosDurations.fast,
                  opacity: _isHighlighted ? 1.0 : 0.0,
                  child: Icon(
                    Icons.chevron_right,
                    color: KylosColors.liveTvGlow,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
