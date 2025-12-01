// Kylos IPTV Player - Advanced Player Controls
// Full-featured player controls overlay with VLC-style gestures.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/playback/domain/player_settings.dart';
import 'package:kylos_iptv_player/features/playback/presentation/providers/player_settings_provider.dart';

/// Advanced player controls with VLC-style gestures.
///
/// Gestures:
/// - Vertical swipe on RIGHT side: Volume control
/// - Vertical swipe on LEFT side: Brightness control
/// - Horizontal swipe ANYWHERE: Seek forward/backward
/// - Double tap LEFT: Rewind 10s
/// - Double tap RIGHT: Forward 10s
/// - Single tap: Show/hide controls
class AdvancedPlayerControls extends ConsumerStatefulWidget {
  const AdvancedPlayerControls({
    required this.onBack,
    super.key,
    this.autoHide = true,
    this.hideDelay = const Duration(seconds: 4),
  });

  final VoidCallback onBack;
  final bool autoHide;
  final Duration hideDelay;

  @override
  ConsumerState<AdvancedPlayerControls> createState() =>
      _AdvancedPlayerControlsState();
}

class _AdvancedPlayerControlsState
    extends ConsumerState<AdvancedPlayerControls> {
  bool _controlsVisible = true;
  bool _locked = false;
  Timer? _hideTimer;

  // Gesture tracking
  bool _isDragging = false;
  _DragType _dragType = _DragType.none;
  double _dragStartValue = 0;
  Offset _dragStartPosition = Offset.zero;

  // Seek gesture state
  Duration _seekStartPosition = Duration.zero;
  Duration _seekTargetPosition = Duration.zero;
  bool _isSeekGesture = false;

  // Volume slider visibility
  bool _showVolumeSlider = false;
  Timer? _volumeSliderTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _volumeSliderTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (widget.autoHide && !_locked && !_isDragging) {
      _hideTimer = Timer(widget.hideDelay, () {
        if (mounted) {
          setState(() => _controlsVisible = false);
        }
      });
    }
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _startHideTimer();
  }

  void _toggleLock() {
    setState(() => _locked = !_locked);
    if (!_locked) {
      _startHideTimer();
    }
  }

  void _handleTap() {
    if (_locked) {
      _showControls();
      return;
    }
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _handleDoubleTapLeft() {
    if (_locked) return;
    final state = ref.read(playbackNotifierProvider);
    if (state.isLive) return;

    final pos = state.position ?? Duration.zero;
    ref.read(playbackNotifierProvider.notifier).seek(
          pos - const Duration(seconds: 10),
        );
    _showControls();
    HapticFeedback.lightImpact();
  }

  void _handleDoubleTapRight() {
    if (_locked) return;
    final state = ref.read(playbackNotifierProvider);
    if (state.isLive) return;

    final pos = state.position ?? Duration.zero;
    final duration = state.duration ?? Duration.zero;
    final newPos = pos + const Duration(seconds: 10);
    if (newPos < duration) {
      ref.read(playbackNotifierProvider.notifier).seek(newPos);
    }
    _showControls();
    HapticFeedback.lightImpact();
  }

  void _onPanStart(DragStartDetails details) {
    if (_locked) return;

    _dragStartPosition = details.localPosition;
    _isDragging = true;
    _dragType = _DragType.none;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.localPosition.dx < screenWidth * 0.4;
    final isRightSide = details.localPosition.dx > screenWidth * 0.6;

    // Store initial values
    final settings = ref.read(playerSettingsProvider);
    final playback = ref.read(playbackNotifierProvider);

    if (isLeftSide) {
      _dragStartValue = settings.brightness;
    } else if (isRightSide) {
      _dragStartValue = settings.volume;
    }

    _seekStartPosition = playback.position ?? Duration.zero;
    _seekTargetPosition = _seekStartPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_locked || !_isDragging) return;

    final dx = details.localPosition.dx - _dragStartPosition.dx;
    final dy = details.localPosition.dy - _dragStartPosition.dy;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine drag type if not set yet
    if (_dragType == _DragType.none) {
      if (dx.abs() > 20 || dy.abs() > 20) {
        if (dx.abs() > dy.abs()) {
          // Horizontal - seek
          final playback = ref.read(playbackNotifierProvider);
          if (!playback.isLive) {
            _dragType = _DragType.seek;
            _isSeekGesture = true;
          }
        } else {
          // Vertical - volume or brightness
          final isLeftSide = _dragStartPosition.dx < screenWidth * 0.4;
          final isRightSide = _dragStartPosition.dx > screenWidth * 0.6;

          if (isLeftSide) {
            _dragType = _DragType.brightness;
          } else if (isRightSide) {
            _dragType = _DragType.volume;
          }
        }
        setState(() {});
      }
      return;
    }

    // Apply the gesture
    switch (_dragType) {
      case _DragType.volume:
        final delta = -dy / (screenHeight * 0.5);
        final newVolume = (_dragStartValue + delta).clamp(0.0, 1.0);
        ref.read(playerSettingsProvider.notifier).setVolume(newVolume);
        // Apply to actual player
        ref.read(playbackNotifierProvider.notifier).setVolume(newVolume);
        setState(() {});
        break;

      case _DragType.brightness:
        final delta = -dy / (screenHeight * 0.5);
        final newBrightness = (_dragStartValue + delta).clamp(0.0, 1.0);
        ref.read(playerSettingsProvider.notifier).setBrightness(newBrightness);
        setState(() {});
        break;

      case _DragType.seek:
        final playback = ref.read(playbackNotifierProvider);
        final duration = playback.duration ?? const Duration(seconds: 1);
        // 1 full swipe = 2 minutes of seek
        final seekDelta = Duration(
          milliseconds: (dx / screenWidth * 120000).toInt(),
        );
        _seekTargetPosition = Duration(
          milliseconds: (_seekStartPosition + seekDelta)
              .inMilliseconds
              .clamp(0, duration.inMilliseconds),
        );
        setState(() {});
        break;

      case _DragType.none:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragType == _DragType.seek && _isSeekGesture) {
      ref.read(playbackNotifierProvider.notifier).seek(_seekTargetPosition);
    }

    setState(() {
      _isDragging = false;
      _dragType = _DragType.none;
      _isSeekGesture = false;
    });
    _startHideTimer();
  }

  void _showVolumeSliderTemporarily() {
    _volumeSliderTimer?.cancel();
    setState(() => _showVolumeSlider = true);
    _volumeSliderTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showVolumeSlider = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(playerSettingsProvider);

    return GestureDetector(
      onTap: _handleTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Double tap zones
          Row(
            children: [
              // Left zone - rewind
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _handleDoubleTapLeft,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              // Right zone - forward
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _handleDoubleTapRight,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

          // Gesture indicator overlay
          if (_isDragging && _dragType != _DragType.none)
            _buildGestureIndicator(settings, playbackState),

          // Controls overlay
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: _buildControlsOverlay(playbackState, settings),
            ),
          ),

          // Locked indicator
          if (_locked && _controlsVisible) _buildLockedIndicator(),
        ],
      ),
    );
  }

  Widget _buildGestureIndicator(
    PlayerSettings settings,
    PlaybackState playbackState,
  ) {
    IconData icon;
    String label;
    double? value;

    switch (_dragType) {
      case _DragType.volume:
        final vol = settings.volume;
        icon = vol > 0.5
            ? Icons.volume_up
            : vol > 0
                ? Icons.volume_down
                : Icons.volume_off;
        label = '${(vol * 100).round()}%';
        value = vol;
        break;

      case _DragType.brightness:
        final bright = settings.brightness;
        icon = bright > 0.5 ? Icons.brightness_high : Icons.brightness_low;
        label = '${(bright * 100).round()}%';
        value = bright;
        break;

      case _DragType.seek:
        final diff = _seekTargetPosition - _seekStartPosition;
        final isForward = diff.isNegative == false;
        icon = isForward ? Icons.fast_forward : Icons.fast_rewind;
        final diffStr = _formatDuration(diff.abs());
        label =
            '${isForward ? '+' : '-'}$diffStr\n${_formatDuration(_seekTargetPosition)}';
        value = null;
        break;

      case _DragType.none:
        return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            if (value != null) ...[
              LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Pantalla Bloqueada',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleLock,
                child: const Text(
                  'Desbloquear',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    PlaybackState playbackState,
    PlayerSettings settings,
  ) {
    if (_locked) return const SizedBox.shrink();

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
          stops: [0.0, 0.25, 0.75, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(playbackState, settings),
            const Spacer(),
            _buildCenterControls(playbackState),
            const Spacer(),
            if (!playbackState.isLive) _buildProgressBar(playbackState),
            _buildBottomBar(playbackState, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PlaybackState state, PlayerSettings settings) {
    final content = state.content;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
          if (state.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                  SizedBox(width: 4),
                  Text('EN VIVO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              _locked ? Icons.lock : Icons.lock_open,
              color: Colors.white,
            ),
            onPressed: _toggleLock,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            color: const Color(0xFF1A1A2E),
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                  'speed', Icons.speed, 'Velocidad: ${settings.playbackSpeed.label}'),
              _buildPopupMenuItem(
                  'aspect', Icons.aspect_ratio, 'Aspecto: ${settings.aspectRatio.label}'),
              _buildPopupMenuItem('subtitles', Icons.subtitles, 'Subtítulos'),
              _buildPopupMenuItem('audio', Icons.audiotrack, 'Audio'),
            ],
            onSelected: (value) => _handleSettingsSelection(value, state),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _handleSettingsSelection(String selection, PlaybackState state) {
    switch (selection) {
      case 'speed':
        _showSpeedDialog();
      case 'aspect':
        _showAspectRatioDialog();
      case 'subtitles':
        _showSubtitlesDialog(state);
      case 'audio':
        _showAudioDialog(state);
    }
  }

  Widget _buildCenterControls(PlaybackState state) {
    final isPlaying = state.status == PlaybackStatus.playing;
    final isLive = state.isLive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        if (!isLive)
          _ControlButton(
            icon: Icons.replay_10,
            size: 36,
            onPressed: () {
              final pos = state.position ?? Duration.zero;
              ref.read(playbackNotifierProvider.notifier).seek(
                    pos - const Duration(seconds: 10),
                  );
            },
          ),

        if (!isLive) const SizedBox(width: 32),

        // Play/Pause
        _ControlButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          size: 56,
          isPrimary: true,
          onPressed: () {
            ref.read(playbackNotifierProvider.notifier).togglePlayPause();
          },
        ),

        if (!isLive) const SizedBox(width: 32),

        // Forward 10s
        if (!isLive)
          _ControlButton(
            icon: Icons.forward_10,
            size: 36,
            onPressed: () {
              final pos = state.position ?? Duration.zero;
              final duration = state.duration ?? Duration.zero;
              final newPos = pos + const Duration(seconds: 10);
              if (newPos < duration) {
                ref.read(playbackNotifierProvider.notifier).seek(newPos);
              }
            },
          ),
      ],
    );
  }

  Widget _buildProgressBar(PlaybackState state) {
    final position = state.position ?? Duration.zero;
    final duration = state.duration ?? const Duration(seconds: 1);
    final buffered = state.bufferedPosition ?? Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Time display
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress slider
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Buffer indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: duration.inMilliseconds > 0
                        ? buffered.inMilliseconds / duration.inMilliseconds
                        : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white38),
                    minHeight: 4,
                  ),
                ),
                // Seek slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.amber,
                    overlayColor: Colors.amber.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    value: position.inMilliseconds
                        .toDouble()
                        .clamp(0, duration.inMilliseconds.toDouble()),
                    max: duration.inMilliseconds.toDouble(),
                    onChangeStart: (_) {
                      _hideTimer?.cancel();
                    },
                    onChanged: (value) {
                      ref.read(playbackNotifierProvider.notifier).seek(
                            Duration(milliseconds: value.toInt()),
                          );
                    },
                    onChangeEnd: (_) {
                      _startHideTimer();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PlaybackState state, PlayerSettings settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          // Volume control with slider
          _buildVolumeControl(settings),

          const Spacer(),

          // Audio Track Selection
          if (state.audioTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.audiotrack, color: Colors.white),
              onPressed: () => _showAudioDialog(state),
              tooltip: 'Pista de audio',
            ),

          // Subtitles
          if (state.subtitleTracks.isNotEmpty)
            IconButton(
              icon: Icon(
                state.selectedSubtitleTrack != null
                    ? Icons.subtitles
                    : Icons.subtitles_off,
                color: Colors.white,
              ),
              onPressed: () => _showSubtitlesDialog(state),
              tooltip: 'Subtítulos',
            ),

          // Aspect ratio
          IconButton(
            icon: const Icon(Icons.aspect_ratio, color: Colors.white),
            onPressed: () {
              ref.read(playerSettingsProvider.notifier).cycleAspectRatio();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Aspecto: ${ref.read(playerSettingsProvider).aspectRatio.label}'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Relación de aspecto',
          ),

          // Speed (VOD only)
          if (!state.isLive)
            TextButton(
              onPressed: _showSpeedDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Text(
                settings.playbackSpeed.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(PlayerSettings settings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mute button - toggles mute on/off
        IconButton(
          icon: Icon(
            settings.isMuted || settings.volume == 0
                ? Icons.volume_off
                : Icons.volume_mute,
            color: settings.isMuted ? Colors.red : Colors.white,
          ),
          onPressed: () {
            ref.read(playerSettingsProvider.notifier).toggleMute();
            final isMuted = ref.read(playerSettingsProvider).isMuted;
            ref.read(playbackNotifierProvider.notifier).setVolume(
                  isMuted ? 0 : ref.read(playerSettingsProvider).volume,
                );
          },
          tooltip: settings.isMuted ? 'Unmute' : 'Mute',
        ),
        // Volume button - shows/hides volume slider (does NOT toggle mute)
        IconButton(
          icon: Icon(
            settings.volume < 0.5 ? Icons.volume_down : Icons.volume_up,
            color: _showVolumeSlider ? Colors.amber : Colors.white,
          ),
          onPressed: _showVolumeSliderTemporarily,
          tooltip: 'Volume',
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _showVolumeSlider ? 120 : 0,
          child: _showVolumeSlider
              ? SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.amber,
                  ),
                  child: Slider(
                    value: settings.isMuted ? 0 : settings.volume,
                    onChanged: (value) {
                      ref.read(playerSettingsProvider.notifier).setVolume(value);
                      ref.read(playerSettingsProvider.notifier).setMuted(false);
                      ref.read(playbackNotifierProvider.notifier).setVolume(value);
                      _showVolumeSliderTemporarily();
                    },
                  ),
                )
              : null,
        ),
        // Always show volume percentage when slider is visible
        if (_showVolumeSlider)
          Text(
            '${(settings.volume * 100).round()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }

  void _showSpeedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Velocidad', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PlaybackSpeed.values.map((speed) {
            final isSelected =
                ref.read(playerSettingsProvider).playbackSpeed == speed;
            return ListTile(
              title: Text(
                speed.label,
                style: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing:
                  isSelected ? const Icon(Icons.check, color: Colors.amber) : null,
              onTap: () {
                ref.read(playerSettingsProvider.notifier).setPlaybackSpeed(speed);
                ref
                    .read(playbackNotifierProvider.notifier)
                    .setPlaybackSpeed(speed.speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAspectRatioDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('Relación de Aspecto', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: VideoAspectRatio.values.map((ratio) {
            final isSelected =
                ref.read(playerSettingsProvider).aspectRatio == ratio;
            return ListTile(
              title: Text(
                ratio.label,
                style: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing:
                  isSelected ? const Icon(Icons.check, color: Colors.amber) : null,
              onTap: () {
                ref.read(playerSettingsProvider.notifier).setAspectRatio(ratio);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubtitlesDialog(PlaybackState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => _SubtitleSettingsSheet(
        tracks: state.subtitleTracks,
        selectedTrack: state.selectedSubtitleTrack,
      ),
    );
  }

  void _showAudioDialog(PlaybackState state) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Pista de Audio', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: state.audioTracks.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay pistas de audio disponibles',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ]
              : state.audioTracks.map((track) {
                  final isSelected = state.selectedAudioTrack?.id == track.id;
                  return ListTile(
                    title: Text(
                      track.label,
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: track.language != null
                        ? Text(track.language!,
                            style: const TextStyle(color: Colors.white54))
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.amber)
                        : null,
                    onTap: () {
                      ref
                          .read(playbackNotifierProvider.notifier)
                          .selectAudioTrack(track);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

enum _DragType { none, volume, brightness, seek }

/// Control button widget.
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
      color: isPrimary ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(isPrimary ? 16 : 8),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

/// Subtitle settings bottom sheet.
class _SubtitleSettingsSheet extends ConsumerStatefulWidget {
  const _SubtitleSettingsSheet({
    required this.tracks,
    this.selectedTrack,
  });

  final List<SubtitleTrack> tracks;
  final SubtitleTrack? selectedTrack;

  @override
  ConsumerState<_SubtitleSettingsSheet> createState() =>
      _SubtitleSettingsSheetState();
}

class _SubtitleSettingsSheetState extends ConsumerState<_SubtitleSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerSettingsProvider);
    final availableHeight = MediaQuery.of(context).size.height * 0.8;
    final contentHeight = availableHeight.clamp(240.0, 600.0);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: contentHeight + 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.amber,
              tabs: const [Tab(text: 'Pista'), Tab(text: 'Estilo')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTrackSelection(),
                  _buildStyleSettings(settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackSelection() {
    return ListView(
      children: [
        ListTile(
          title: const Text('Desactivado', style: TextStyle(color: Colors.white)),
          trailing: widget.selectedTrack == null
              ? const Icon(Icons.check, color: Colors.amber)
              : null,
          onTap: () {
            ref.read(playbackNotifierProvider.notifier).selectSubtitleTrack(null);
            Navigator.pop(context);
          },
        ),
        const Divider(color: Colors.white24),
        ...widget.tracks.map((track) {
          final isSelected = widget.selectedTrack?.id == track.id;
          return ListTile(
            title: Text(
              track.label,
              style: TextStyle(color: isSelected ? Colors.amber : Colors.white),
            ),
            subtitle: track.language != null
                ? Text(track.language!, style: const TextStyle(color: Colors.white54))
                : null,
            trailing:
                isSelected ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              ref.read(playbackNotifierProvider.notifier).selectSubtitleTrack(track);
              Navigator.pop(context);
            },
          );
        }),
      ],
    );
  }

  Widget _buildStyleSettings(PlayerSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Tamaño', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: SubtitleStyle.availableSizes.map((size) {
            final isSelected = settings.subtitleStyle.fontSize == size;
            return ChoiceChip(
              label: Text('${size.toInt()}'),
              selected: isSelected,
              selectedColor: Colors.amber,
              labelStyle:
                  TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12),
              backgroundColor: Colors.white12,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                ref.read(playerSettingsProvider.notifier).setSubtitleFontSize(size);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: SubtitleStyle.availableColors.map((color) {
            final isSelected = settings.subtitleStyle.fontColor == color;
            return GestureDetector(
              onTap: () {
                ref.read(playerSettingsProvider.notifier).setSubtitleFontColor(color);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.amber, width: 3)
                      : Border.all(color: Colors.white24),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('Sincronización', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () {
                ref.read(playerSettingsProvider.notifier).decreaseSubtitleDelay();
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${settings.subtitleDelay.inMilliseconds > 0 ? '+' : ''}${settings.subtitleDelay.inMilliseconds}ms',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                ref.read(playerSettingsProvider.notifier).increaseSubtitleDelay();
              },
            ),
            TextButton(
              onPressed: () {
                ref.read(playerSettingsProvider.notifier).resetSubtitleDelay();
              },
              child: const Text('Reset', style: TextStyle(color: Colors.amber, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
