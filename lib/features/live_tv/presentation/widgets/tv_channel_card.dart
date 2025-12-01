// Kylos IPTV Player - TV Channel Card
// Focusable channel card optimized for TV/D-pad navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

/// A focusable channel card for TV grid layouts.
///
/// Provides clear visual feedback when focused and handles D-pad select events.
class TVChannelCard extends StatefulWidget {
  const TVChannelCard({
    super.key,
    required this.channel,
    this.epgTitle,
    this.epgTime,
    this.isPlaying = false,
    this.autofocus = false,
    this.onSelect,
    this.onFocusChange,
    this.focusNode,
  });

  /// The channel to display.
  final Channel channel;

  /// Current program title from EPG.
  final String? epgTitle;

  /// Current program time from EPG.
  final String? epgTime;

  /// Whether this channel is currently playing.
  final bool isPlaying;

  /// Whether this card should auto-focus on build.
  final bool autofocus;

  /// Callback when the card is selected (enter/OK pressed).
  final VoidCallback? onSelect;

  /// Callback when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Optional external focus node.
  final FocusNode? focusNode;

  @override
  State<TVChannelCard> createState() => _TVChannelCardState();
}

class _TVChannelCardState extends State<TVChannelCard>
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
      duration: const Duration(milliseconds: 150),
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
  void didUpdateWidget(TVChannelCard oldWidget) {
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

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 200,
                decoration: BoxDecoration(
                  color: _isFocused
                      ? colorScheme.primaryContainer
                      : widget.isPlaying
                          ? colorScheme.secondaryContainer
                          : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: _isFocused
                      ? Border.all(
                          color: colorScheme.primary,
                          width: 3,
                        )
                      : widget.isPlaying
                          ? Border.all(
                              color: colorScheme.secondary,
                              width: 2,
                            )
                          : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Channel logo / thumbnail
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildLogo(context),
                            // Live indicator
                            if (widget.isPlaying)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fiber_manual_record,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE',
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
                            // Favorite indicator
                            if (widget.channel.isFavorite)
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
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Channel info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Channel name
                          Text(
                            widget.channel.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isFocused
                                  ? colorScheme.onPrimaryContainer
                                  : widget.isPlaying
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // EPG info or channel number
                          if (widget.epgTitle != null)
                            Text(
                              widget.epgTitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isFocused
                                    ? colorScheme.onPrimaryContainer
                                        .withOpacity(0.8)
                                    : colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (widget.channel.channelNumber != null)
                            Text(
                              'Ch. ${widget.channel.channelNumber}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isFocused
                                    ? colorScheme.onPrimaryContainer
                                        .withOpacity(0.8)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (widget.epgTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.epgTime!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _isFocused
                                    ? colorScheme.onPrimaryContainer
                                        .withOpacity(0.6)
                                    : colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (widget.channel.logoUrl != null &&
        widget.channel.logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.channel.logoUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => _buildPlaceholder(context),
        errorWidget: (_, __, ___) => _buildPlaceholder(context),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.live_tv,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A horizontal row of TV channel cards with automatic scrolling on focus.
class TVChannelRow extends StatefulWidget {
  const TVChannelRow({
    super.key,
    required this.title,
    required this.channels,
    this.currentChannelId,
    this.autofocusFirst = false,
    this.onChannelSelect,
    this.onChannelFocus,
  });

  /// Title of the row (e.g., "Favorites", "Sports").
  final String title;

  /// List of channels to display.
  final List<Channel> channels;

  /// ID of the currently playing channel.
  final String? currentChannelId;

  /// Whether to auto-focus the first channel.
  final bool autofocusFirst;

  /// Callback when a channel is selected.
  final void Function(Channel channel)? onChannelSelect;

  /// Callback when a channel receives focus.
  final void Function(Channel channel)? onChannelFocus;

  @override
  State<TVChannelRow> createState() => _TVChannelRowState();
}

class _TVChannelRowState extends State<TVChannelRow> {
  final ScrollController _scrollController = ScrollController();
  static const _cardWidth = 200.0;
  static const _cardSpacing = 16.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final offset = index * (_cardWidth + _cardSpacing);
    final screenWidth = MediaQuery.of(context).size.width - 100; // Account for rail
    final targetOffset = offset - (screenWidth / 2) + (_cardWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row title
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 16),
          child: Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Channel cards
        SizedBox(
          height: 200,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            itemCount: widget.channels.length,
            itemBuilder: (context, index) {
              final channel = widget.channels[index];
              final isPlaying = channel.id == widget.currentChannelId;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.channels.length - 1 ? _cardSpacing : 0,
                ),
                child: TVChannelCard(
                  channel: channel,
                  isPlaying: isPlaying,
                  autofocus: widget.autofocusFirst && index == 0,
                  onSelect: () => widget.onChannelSelect?.call(channel),
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _scrollToIndex(index);
                      widget.onChannelFocus?.call(channel);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
