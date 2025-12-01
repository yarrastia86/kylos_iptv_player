// Kylos IPTV Player - Channel Row Widget
// Row widget for displaying a channel in the channel list.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

/// Row widget for displaying a channel in the list.
///
/// Shows channel number, logo, play icon, name, and favorite star.
/// Supports TV remote/D-pad navigation.
class ChannelRow extends StatefulWidget {
  const ChannelRow({
    super.key,
    required this.channel,
    required this.index,
    required this.onTap,
    required this.onFavoriteToggle,
    this.isSelected = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The channel to display.
  final Channel channel;

  /// Index of this channel in the list (for channel number display).
  final int index;

  /// Callback when the row is tapped/selected.
  final VoidCallback onTap;

  /// Callback to toggle favorite status.
  final VoidCallback onFavoriteToggle;

  /// Whether this channel is currently selected.
  final bool isSelected;

  /// Optional focus node for TV navigation.
  final FocusNode? focusNode;

  /// Whether this row should be focused initially.
  final bool autofocus;

  @override
  State<ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<ChannelRow> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

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

    // Enter/Select to play
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onTap();
      return KeyEventResult.handled;
    }

    // 'f' key to toggle favorite (for keyboards)
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      widget.onFavoriteToggle();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Only use isSelected for visual state - focus is separate for keyboard nav
    final isHighlighted = widget.isSelected;
    final channelNumber = widget.channel.channelNumber ?? (widget.index + 1);

    return RepaintBoundary(
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            curve: Curves.easeOutCubic,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? KylosColors.buttonFocused
                  : KylosColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(8),
              border: isHighlighted
                  ? Border.all(color: KylosColors.liveTvGlow, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Channel number
                SizedBox(
                  width: 36,
                  child: Text(
                    channelNumber.toString().padLeft(3, '0'),
                    style: TextStyle(
                      color: isHighlighted
                          ? KylosColors.textPrimary
                          : KylosColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                // Channel logo
                _buildLogo(),

                const SizedBox(width: 8),

                // Play icon (visible when selected)
                AnimatedOpacity(
                  duration: KylosDurations.fast,
                  opacity: isHighlighted ? 1.0 : 0.0,
                  child: const Icon(
                    Icons.play_circle_filled,
                    color: KylosColors.liveTvGlow,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 8),

                // Channel name
                Expanded(
                  child: Text(
                    widget.channel.name,
                    style: TextStyle(
                      color: isHighlighted
                          ? KylosColors.textPrimary
                          : KylosColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Favorite star
                GestureDetector(
                  onTap: widget.onFavoriteToggle,
                  child: AnimatedSwitcher(
                    duration: KylosDurations.fast,
                    child: Icon(
                      widget.channel.isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      key: ValueKey(widget.channel.isFavorite),
                      color: widget.channel.isFavorite
                          ? Colors.amber
                          : KylosColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final logoUrl = widget.channel.logoUrl;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: KylosColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: Icon(
                  Icons.tv,
                  color: KylosColors.textMuted,
                  size: 20,
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.tv,
                  color: KylosColors.textMuted,
                  size: 20,
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.tv,
                color: KylosColors.textMuted,
                size: 20,
              ),
            ),
    );
  }
}
