// Kylos IPTV Player - TV Player Controls
// Overlay controls optimized for TV remote/D-pad navigation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/tv/focus_system.dart';

/// TV-optimized player controls overlay.
///
/// Designed for remote control navigation with:
/// - Clear focus indicators
/// - Large touch/focus targets
/// - Auto-hide functionality
/// - Media key support (play/pause, channel up/down)
class TVPlayerControls extends StatefulWidget {
  const TVPlayerControls({
    super.key,
    required this.playbackState,
    this.onPlayPause,
    this.onStop,
    this.onChannelUp,
    this.onChannelDown,
    this.onToggleInfo,
    this.onSeek,
    this.autoHideDelay = const Duration(seconds: 5),
  });

  /// Current playback state.
  final PlaybackState playbackState;

  /// Callback when play/pause is toggled.
  final VoidCallback? onPlayPause;

  /// Callback when stop is pressed.
  final VoidCallback? onStop;

  /// Callback when channel up is pressed.
  final VoidCallback? onChannelUp;

  /// Callback when channel down is pressed.
  final VoidCallback? onChannelDown;

  /// Callback when info overlay is toggled.
  final VoidCallback? onToggleInfo;

  /// Callback when seeking (for VOD content).
  final void Function(Duration)? onSeek;

  /// Delay before auto-hiding controls.
  final Duration autoHideDelay;

  @override
  State<TVPlayerControls> createState() => _TVPlayerControlsState();
}

class _TVPlayerControlsState extends State<TVPlayerControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;
  late Animation<double> _fadeAnimation;
  Timer? _hideTimer;
  bool _isVisible = true;
  bool _showInfo = false;

  final FocusNode _scopeFocusNode = FocusNode(debugLabel: 'TV Player Controls');

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0;

    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOut,
    );

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _visibilityController.dispose();
    _scopeFocusNode.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideDelay, _hideControls);
  }

  void _hideControls() {
    if (mounted && _isVisible) {
      _visibilityController.reverse().then((_) {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }
  }

  void _showControls() {
    if (mounted) {
      setState(() => _isVisible = true);
      _visibilityController.forward();
      _startHideTimer();
    }
  }

  void _resetHideTimer() {
    if (_isVisible) {
      _startHideTimer();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Show controls on any key press if hidden
    if (!_isVisible) {
      _showControls();
      return KeyEventResult.handled;
    }

    // Reset timer on interaction
    _resetHideTimer();

    // Handle specific keys
    final key = event.logicalKey;

    // Play/Pause
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      widget.onPlayPause?.call();
      return KeyEventResult.handled;
    }

    // Stop
    if (key == LogicalKeyboardKey.mediaStop ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      widget.onStop?.call();
      return KeyEventResult.handled;
    }

    // Channel up/down
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp) {
      widget.onChannelUp?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown) {
      widget.onChannelDown?.call();
      return KeyEventResult.handled;
    }

    // Info toggle
    if (key == LogicalKeyboardKey.info || key == LogicalKeyboardKey.f1) {
      setState(() => _showInfo = !_showInfo);
      widget.onToggleInfo?.call();
      return KeyEventResult.handled;
    }

    // Seek (for VOD)
    if (!widget.playbackState.isLive) {
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.mediaRewind) {
        final position = widget.playbackState.position ?? Duration.zero;
        final newPosition = position - const Duration(seconds: 10);
        widget.onSeek?.call(newPosition.isNegative ? Duration.zero : newPosition);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.mediaFastForward) {
        final position = widget.playbackState.position ?? Duration.zero;
        final duration = widget.playbackState.duration ?? Duration.zero;
        final newPosition = position + const Duration(seconds: 10);
        widget.onSeek?.call(newPosition > duration ? duration : newPosition);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _scopeFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          if (_isVisible) {
            _hideControls();
          } else {
            _showControls();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main controls overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildControlsOverlay(context),
            ),
            // Info overlay (separate from main controls)
            if (_showInfo) _buildInfoOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
            Colors.black87,
          ],
          stops: [0.0, 0.15, 0.85, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with channel info
            _buildTopBar(context),
            const Spacer(),
            // Center controls
            _buildCenterControls(context),
            const Spacer(),
            // Bottom bar with hints
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final content = widget.playbackState.content;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Channel logo placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.live_tv,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Channel info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content != null) ...[
                  Text(
                    content.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (content.categoryName != null)
                    Text(
                      content.categoryName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                ],
              ],
            ),
          ),
          // Live indicator
          if (widget.playbackState.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    final status = widget.playbackState.status;
    final isPlaying = status == PlaybackStatus.playing;
    final isPaused = status == PlaybackStatus.paused;

    if (!isPlaying && !isPaused) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind (VOD only)
        if (!widget.playbackState.isLive)
          _TVControlButton(
            icon: Icons.replay_10,
            label: '-10s',
            size: 48,
            onPressed: () {
              final position = widget.playbackState.position ?? Duration.zero;
              final newPosition = position - const Duration(seconds: 10);
              widget.onSeek?.call(
                newPosition.isNegative ? Duration.zero : newPosition,
              );
              _resetHideTimer();
            },
          ),

        const SizedBox(width: 32),

        // Play/Pause
        _TVControlButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          label: isPlaying ? 'Pause' : 'Play',
          size: 80,
          isPrimary: true,
          onPressed: () {
            widget.onPlayPause?.call();
            _resetHideTimer();
          },
        ),

        const SizedBox(width: 32),

        // Forward (VOD only)
        if (!widget.playbackState.isLive)
          _TVControlButton(
            icon: Icons.forward_10,
            label: '+10s',
            size: 48,
            onPressed: () {
              final position = widget.playbackState.position ?? Duration.zero;
              final duration = widget.playbackState.duration ?? Duration.zero;
              final newPosition = position + const Duration(seconds: 10);
              widget.onSeek?.call(newPosition > duration ? duration : newPosition);
              _resetHideTimer();
            },
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Key hints
          _buildKeyHint(context, 'OK', 'Play/Pause'),
          const SizedBox(width: 24),
          _buildKeyHint(context, 'CH+/-', 'Channel'),
          const SizedBox(width: 24),
          _buildKeyHint(context, 'INFO', 'Details'),
          const SizedBox(width: 24),
          _buildKeyHint(context, 'BACK', 'Exit'),
        ],
      ),
    );
  }

  Widget _buildKeyHint(BuildContext context, String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          action,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    final content = widget.playbackState.content;
    final theme = Theme.of(context);

    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Channel Info',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (content != null) ...[
              _buildInfoRow('Channel', content.title),
              if (content.categoryName != null)
                _buildInfoRow('Category', content.categoryName!),
              _buildInfoRow(
                'Status',
                widget.playbackState.isLive ? 'Live' : 'VOD',
              ),
              if (!widget.playbackState.isLive &&
                  widget.playbackState.duration != null)
                _buildInfoRow(
                  'Duration',
                  _formatDuration(widget.playbackState.duration!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Focusable control button for TV player.
class _TVControlButton extends StatefulWidget {
  const _TVControlButton({
    required this.icon,
    required this.label,
    this.size = 48,
    this.isPrimary = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final double size;
  final bool isPrimary;
  final VoidCallback? onPressed;

  @override
  State<_TVControlButton> createState() => _TVControlButtonState();
}

class _TVControlButtonState extends State<_TVControlButton> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onPressed?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.isPrimary ? widget.size + 16 : widget.size;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isFocused ? 1.15 : 1.0),
          transformAlignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isFocused
                      ? Colors.white
                      : widget.isPrimary
                          ? Colors.white24
                          : Colors.white12,
                  border: _isFocused
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: _isFocused ? Colors.black : Colors.white,
                  size: widget.size * 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple channel info banner for TV that shows briefly when changing channels.
class TVChannelBanner extends StatefulWidget {
  const TVChannelBanner({
    super.key,
    required this.channelName,
    this.channelNumber,
    this.categoryName,
    this.logoUrl,
    this.displayDuration = const Duration(seconds: 4),
    this.onDismiss,
  });

  final String channelName;
  final String? channelNumber;
  final String? categoryName;
  final String? logoUrl;
  final Duration displayDuration;
  final VoidCallback? onDismiss;

  @override
  State<TVChannelBanner> createState() => _TVChannelBannerState();
}

class _TVChannelBannerState extends State<TVChannelBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 24,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Channel logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.live_tv,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Channel info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.channelNumber != null)
                        Text(
                          'CH ${widget.channelNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      Text(
                        widget.channelName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.categoryName != null)
                        Text(
                          widget.categoryName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
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
