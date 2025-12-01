// Kylos IPTV Player - Live TV Category Card
// Card widget for displaying a category in the categories list.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';

/// Card widget for displaying a Live TV category.
///
/// Shows category name, channel count, and navigation indicator.
/// Supports both touch and D-pad/remote navigation.
class LiveTvCategoryCard extends StatefulWidget {
  const LiveTvCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  /// The category to display.
  final ChannelCategory category;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Optional focus node for TV navigation.
  final FocusNode? focusNode;

  /// Whether this card should be focused initially.
  final bool autofocus;

  @override
  State<LiveTvCategoryCard> createState() => _LiveTvCategoryCardState();
}

class _LiveTvCategoryCardState extends State<LiveTvCategoryCard> {
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
    return RepaintBoundary(
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isFocused
                  ? KylosColors.buttonFocused
                  : KylosColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(8),
              border: _isFocused
                  ? Border.all(color: KylosColors.liveTvGlow, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Category name
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: const TextStyle(
                      color: KylosColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Channel count
                Text(
                  _formatCount(widget.category.channelCount),
                  style: const TextStyle(
                    color: KylosColors.textMuted,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(width: 4),

                // Arrow icon
                const Icon(
                  Icons.chevron_right,
                  color: KylosColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
