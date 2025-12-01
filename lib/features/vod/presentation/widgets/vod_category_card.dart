// Kylos IPTV Player - VOD Category Card

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_category.dart';

/// Card widget for displaying a VOD category.
class VodCategoryCard extends StatefulWidget {
  const VodCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.autofocus = false,
  });

  final VodCategory category;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  State<VodCategoryCard> createState() => _VodCategoryCardState();
}

class _VodCategoryCardState extends State<VodCategoryCard> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
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

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

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
                  ? Border.all(color: KylosColors.moviesGlow, width: 2)
                  : null,
            ),
            child: Row(
              children: [
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
                Text(
                  _formatCount(widget.category.movieCount),
                  style: const TextStyle(
                    color: KylosColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
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
}
