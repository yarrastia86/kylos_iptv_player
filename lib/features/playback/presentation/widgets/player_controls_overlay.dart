// Kylos IPTV Player - Player Controls Overlay
// Overlay controls for the video player.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';

/// Overlay controls for the video player.
///
/// This widget provides basic playback controls that can be themed
/// or replaced with a custom implementation.
class PlayerControlsOverlay extends StatelessWidget {
  const PlayerControlsOverlay({
    super.key,
    required this.playbackState,
    this.onPlayPause,
    this.onMuteToggle,
    this.onBack,
    this.onFullscreen,
    this.onSeek,
  });

  /// Current playback state.
  final PlaybackState playbackState;

  /// Callback when play/pause is toggled.
  final VoidCallback? onPlayPause;

  /// Callback when mute is toggled.
  final VoidCallback? onMuteToggle;

  /// Callback when back is pressed.
  final VoidCallback? onBack;

  /// Callback when fullscreen is toggled.
  final VoidCallback? onFullscreen;

  /// Callback when seeking.
  final void Function(Duration)? onSeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.transparent,
            Colors.black54,
          ],
          stops: [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),

            // Center controls
            const Spacer(),
            _buildCenterControls(context),
            const Spacer(),

            // Bottom bar with progress
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final content = playbackState.content;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),

          const SizedBox(width: 8),

          // Channel info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (content != null) ...[
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (content.categoryName != null)
                    Text(
                      content.categoryName!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Live indicator
          if (playbackState.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
    final status = playbackState.status;
    final isPlaying = status == PlaybackStatus.playing;
    final isPaused = status == PlaybackStatus.paused;
    final showPlayPause = isPlaying || isPaused;

    if (!showPlayPause) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind (for VOD only)
        if (!playbackState.isLive)
          _ControlButton(
            icon: Icons.replay_10,
            size: 48,
            onPressed: () {
              final newPosition = playbackState.position! -
                  const Duration(seconds: 10);
              onSeek?.call(
                newPosition.isNegative ? Duration.zero : newPosition,
              );
            },
          ),

        const SizedBox(width: 32),

        // Play/Pause
        _ControlButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          size: 72,
          isPrimary: true,
          onPressed: onPlayPause,
        ),

        const SizedBox(width: 32),

        // Forward (for VOD only)
        if (!playbackState.isLive)
          _ControlButton(
            icon: Icons.forward_10,
            size: 48,
            onPressed: () {
              final newPosition = playbackState.position! +
                  const Duration(seconds: 10);
              final duration = playbackState.duration;
              if (duration != null && newPosition > duration) {
                onSeek?.call(duration);
              } else {
                onSeek?.call(newPosition);
              }
            },
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar (VOD only)
          if (!playbackState.isLive && playbackState.duration != null)
            _buildProgressBar(context),

          const SizedBox(height: 8),

          // Bottom controls
          Row(
            children: [
              // Position/Duration
              if (!playbackState.isLive && playbackState.position != null)
                Text(
                  '${_formatDuration(playbackState.position!)} / ${_formatDuration(playbackState.duration!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),

              const Spacer(),

              // Mute button
              if (onMuteToggle != null)
                IconButton(
                  icon: Icon(
                    playbackState.playbackSpeed == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: onMuteToggle,
                ),

              // Fullscreen button
              if (onFullscreen != null)
                IconButton(
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: onFullscreen,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final position = playbackState.position ?? Duration.zero;
    final duration = playbackState.duration ?? const Duration(seconds: 1);
    final buffered = playbackState.bufferedPosition ?? Duration.zero;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Theme.of(context).colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
      ),
      child: Stack(
        children: [
          // Buffered progress
          LinearProgressIndicator(
            value: buffered.inMilliseconds / duration.inMilliseconds,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation(Colors.white38),
          ),
          // Seek slider
          Slider(
            value: position.inMilliseconds.toDouble().clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              onSeek?.call(Duration(milliseconds: value.toInt()));
            },
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

/// Control button widget for the player.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    this.size = 48,
    this.isPrimary = false,
    this.onPressed,
  });

  final IconData icon;
  final double size;
  final bool isPrimary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? Colors.white24 : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(isPrimary ? 16 : 8),
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}
