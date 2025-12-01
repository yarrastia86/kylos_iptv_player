// Kylos IPTV Player - IPTV Player View
// Reusable video player widget for IPTV streams.

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_controls_overlay.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_error_view.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_loading_view.dart';

/// Configuration for the IPTV player view.
class IptvPlayerConfig {
  const IptvPlayerConfig({
    this.showControls = true,
    this.autoHideControls = true,
    this.controlsHideDelay = const Duration(seconds: 3),
    this.aspectRatio,
    this.backgroundColor = Colors.black,
    this.showBufferingIndicator = true,
  });

  /// Whether to show playback controls.
  final bool showControls;

  /// Whether to auto-hide controls after inactivity.
  final bool autoHideControls;

  /// Delay before hiding controls.
  final Duration controlsHideDelay;

  /// Aspect ratio for the video. Null means fill available space.
  final double? aspectRatio;

  /// Background color when no video is displayed.
  final Color backgroundColor;

  /// Whether to show buffering indicator.
  final bool showBufferingIndicator;
}

/// Callbacks for player events.
class IptvPlayerCallbacks {
  const IptvPlayerCallbacks({
    this.onPlayPause,
    this.onMuteToggle,
    this.onRetry,
    this.onBack,
    this.onFullscreen,
  });

  /// Called when play/pause is toggled.
  final VoidCallback? onPlayPause;

  /// Called when mute is toggled.
  final VoidCallback? onMuteToggle;

  /// Called when retry is requested after an error.
  final VoidCallback? onRetry;

  /// Called when back/exit is requested.
  final VoidCallback? onBack;

  /// Called when fullscreen toggle is requested.
  final VoidCallback? onFullscreen;
}

/// Reusable IPTV player view widget.
///
/// This widget displays a video player with controls and handles various
/// playback states including loading, buffering, playing, and errors.
///
/// Usage:
/// ```dart
/// IptvPlayerView(
///   videoController: videoController,
///   playbackState: playbackState,
///   callbacks: IptvPlayerCallbacks(
///     onPlayPause: () => ref.read(playbackNotifierProvider.notifier).togglePlayPause(),
///     onRetry: () => ref.read(playbackNotifierProvider.notifier).retry(),
///   ),
/// )
/// ```
class IptvPlayerView extends StatefulWidget {
  const IptvPlayerView({
    super.key,
    required this.videoController,
    required this.playbackState,
    this.config = const IptvPlayerConfig(),
    this.callbacks = const IptvPlayerCallbacks(),
  });

  /// The video controller from media_kit.
  final VideoController? videoController;

  /// Current playback state.
  final PlaybackState playbackState;

  /// Player configuration.
  final IptvPlayerConfig config;

  /// Event callbacks.
  final IptvPlayerCallbacks callbacks;

  @override
  State<IptvPlayerView> createState() => _IptvPlayerViewState();
}

class _IptvPlayerViewState extends State<IptvPlayerView> {
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.config.autoHideControls) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    Future.delayed(widget.config.controlsHideDelay, () {
      if (mounted && widget.playbackState.status == PlaybackStatus.playing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    if (widget.config.autoHideControls) {
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showControls,
      child: Container(
        color: widget.config.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video layer
            _buildVideoLayer(),

            // Loading indicator
            if (widget.config.showBufferingIndicator) _buildLoadingLayer(),

            // Error view
            _buildErrorLayer(),

            // Controls overlay
            if (widget.config.showControls) _buildControlsLayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    final controller = widget.videoController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    Widget videoWidget = Video(
      controller: controller,
      fit: BoxFit.contain,
      controls: NoVideoControls,
    );

    if (widget.config.aspectRatio != null) {
      videoWidget = AspectRatio(
        aspectRatio: widget.config.aspectRatio!,
        child: videoWidget,
      );
    }

    return Center(child: videoWidget);
  }

  Widget _buildLoadingLayer() {
    final status = widget.playbackState.status;
    final isLoading = status == PlaybackStatus.loading ||
        status == PlaybackStatus.buffering;

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return PlayerLoadingView(
      message: status == PlaybackStatus.loading ? 'Loading...' : 'Buffering...',
      channelName: widget.playbackState.content?.title,
      channelLogo: widget.playbackState.content?.logoUrl,
    );
  }

  Widget _buildErrorLayer() {
    if (widget.playbackState.status != PlaybackStatus.error) {
      return const SizedBox.shrink();
    }

    final error = widget.playbackState.error;
    return PlayerErrorView(
      message: error?.message ?? 'An error occurred',
      isRecoverable: error?.isRecoverable ?? true,
      onRetry: widget.callbacks.onRetry,
      onBack: widget.callbacks.onBack,
    );
  }

  Widget _buildControlsLayer() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: PlayerControlsOverlay(
          playbackState: widget.playbackState,
          onPlayPause: widget.callbacks.onPlayPause,
          onMuteToggle: widget.callbacks.onMuteToggle,
          onBack: widget.callbacks.onBack,
          onFullscreen: widget.callbacks.onFullscreen,
        ),
      ),
    );
  }
}

/// Empty controls for media_kit Video widget.
Widget NoVideoControls(VideoState state) {
  return const SizedBox.shrink();
}
