// Kylos IPTV Player - Playback Providers
// Riverpod providers for playback state management.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Notifier for playback state.
///
/// Manages the video player state and provides a unified interface
/// for playing different content types. Integrates with media_kit
/// for actual video playback.
class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(PlaybackState.initial()) {
    _initializePlayer();
  }

  media_kit.Player? _player;
  VideoController? _videoController;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _bufferSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<media_kit.Tracks>? _tracksSubscription;

  /// The video controller for rendering.
  VideoController? get videoController => _videoController;

  void _initializePlayer() {
    _player = media_kit.Player();
    _videoController = VideoController(_player!);
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    final player = _player;
    if (player == null) return;

    _playingSubscription = player.stream.playing.listen((playing) {
      if (playing && state.status != PlaybackStatus.playing) {
        state = state.copyWith(status: PlaybackStatus.playing);
        WakelockPlus.enable();
      } else if (!playing &&
          state.status == PlaybackStatus.playing &&
          state.hasContent) {
        state = state.copyWith(status: PlaybackStatus.paused);
      }
    });

    _positionSubscription = player.stream.position.listen((position) {
      state = state.copyWith(position: position);
    });

    _bufferSubscription = player.stream.buffer.listen((buffer) {
      state = state.copyWith(bufferedPosition: buffer);
    });

    _bufferingSubscription = player.stream.buffering.listen((buffering) {
      if (buffering && state.status == PlaybackStatus.playing) {
        state = state.copyWith(status: PlaybackStatus.buffering);
      } else if (!buffering && state.status == PlaybackStatus.buffering) {
        state = state.copyWith(status: PlaybackStatus.playing);
      }
    });

    _completedSubscription = player.stream.completed.listen((completed) {
      if (completed) {
        state = state.copyWith(status: PlaybackStatus.ended);
        WakelockPlus.disable();
      }
    });

    _errorSubscription = player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        state = state.copyWith(
          status: PlaybackStatus.error,
          error: _parseError(error),
        );
        WakelockPlus.disable();
      }
    });

    _tracksSubscription = player.stream.tracks.listen((tracks) {
      _updateTracks(tracks);
    });

    // Listen for duration changes
    player.stream.duration.listen((duration) {
      // For live streams, duration is 0 or very large
      if (duration != Duration.zero && duration.inHours < 24) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  void _updateTracks(media_kit.Tracks tracks) {
    final audioTracks = tracks.audio.map((track) {
      return AudioTrack(
        id: track.id,
        label: track.title ?? track.language ?? 'Track ${track.id}',
        language: track.language,
      );
    }).toList();

    final subtitleTracks = tracks.subtitle.map((track) {
      return SubtitleTrack(
        id: track.id,
        label: track.title ?? track.language ?? 'Subtitle ${track.id}',
        language: track.language,
      );
    }).toList();

    state = state.copyWith(
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
    );
  }

  PlaybackError _parseError(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('unreachable')) {
      return PlaybackError.network();
    }

    if (lowerError.contains('404') || lowerError.contains('not found')) {
      return PlaybackError.streamUnavailable();
    }

    if (lowerError.contains('403') ||
        lowerError.contains('forbidden') ||
        lowerError.contains('401') ||
        lowerError.contains('unauthorized')) {
      return PlaybackError.unauthorized();
    }

    if (lowerError.contains('format') || lowerError.contains('codec')) {
      return PlaybackError.unsupportedFormat();
    }

    if (lowerError.contains('failed to open') ||
        lowerError.contains('could not open') ||
        lowerError.contains('unable to open')) {
      return PlaybackError.streamUnavailable();
    }

    if (lowerError.contains('eof') || lowerError.contains('end of file')) {
      return PlaybackError.streamUnavailable();
    }

    if (lowerError.contains('ssl') || lowerError.contains('certificate')) {
      return PlaybackError.network();
    }

    if (lowerError.contains('dns') || lowerError.contains('resolve')) {
      return PlaybackError.network();
    }

    // Default - no technical details exposed
    return PlaybackError.unknown();
  }

  /// Plays a channel.
  Future<void> playChannel(Channel channel) async {
    final content = PlayableContent.fromChannel(
      id: channel.id,
      name: channel.name,
      streamUrl: channel.streamUrl,
      logoUrl: channel.logoUrl,
    );

    await play(content);
  }

  /// Plays content.
  Future<void> play(PlayableContent content) async {
    state = PlaybackState.loading(content);

    try {
      final player = _player;
      if (player == null) {
        _initializePlayer();
      }

      await _player!.open(
        media_kit.Media(content.streamUrl),
        play: true,
      );

      // Resume from position if specified
      if (content.resumePosition != null &&
          content.resumePosition! > Duration.zero) {
        await _player!.seek(content.resumePosition!);
      }
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        error: _parseError(e.toString()),
      );
    }
  }

  /// Retries playback of the current content.
  Future<void> retry() async {
    final content = state.content;
    if (content != null) {
      await play(content);
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (state.status == PlaybackStatus.playing) {
      await _player?.pause();
    }
  }

  /// Resumes playback.
  Future<void> resume() async {
    if (state.status == PlaybackStatus.paused) {
      await _player?.play();
    }
  }

  /// Toggles play/pause.
  Future<void> togglePlayPause() async {
    if (state.status == PlaybackStatus.playing) {
      await pause();
    } else if (state.status == PlaybackStatus.paused) {
      await resume();
    }
  }

  /// Stops playback and returns to idle.
  Future<void> stop() async {
    await _player?.stop();
    state = PlaybackState.initial();
    WakelockPlus.disable();
  }

  /// Seeks to a position (VOD only).
  Future<void> seek(Duration position) async {
    if (state.isLive) return;

    await _player?.seek(position);
  }

  /// Sets volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume.clamp(0.0, 1.0) * 100);
  }

  /// Toggles mute.
  Future<void> toggleMute() async {
    final player = _player;
    if (player == null) return;

    if (player.state.volume > 0) {
      await player.setVolume(0);
    } else {
      await player.setVolume(100);
    }
  }

  /// Sets playback speed.
  Future<void> setPlaybackSpeed(double speed) async {
    await _player?.setRate(speed.clamp(0.25, 4.0));
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Selects an audio track.
  Future<void> selectAudioTrack(AudioTrack track) async {
    final audioTrack = _player?.state.tracks.audio.cast<media_kit.AudioTrack?>().firstWhere(
          (t) => t?.id == track.id,
          orElse: () => null,
        );
    if (audioTrack != null) {
      await _player?.setAudioTrack(audioTrack);
      state = state.copyWith(selectedAudioTrack: track);
    }
  }

  /// Selects a subtitle track (null to disable).
  Future<void> selectSubtitleTrack(SubtitleTrack? track) async {
    if (track == null) {
      await _player?.setSubtitleTrack(media_kit.SubtitleTrack.no());
      state = state.copyWith(selectedSubtitleTrack: null);
      return;
    }

    final subtitleTrack =
        _player?.state.tracks.subtitle.cast<media_kit.SubtitleTrack?>().firstWhere(
              (t) => t?.id == track.id,
              orElse: () => null,
            );
    if (subtitleTrack != null) {
      await _player?.setSubtitleTrack(subtitleTrack);
      state = state.copyWith(selectedSubtitleTrack: track);
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _bufferSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _tracksSubscription?.cancel();
    _player?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}

/// Provider for the playback notifier.
final playbackNotifierProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final notifier = PlaybackNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Provider for the video controller.
final videoControllerProvider = Provider<VideoController?>((ref) {
  return ref.watch(playbackNotifierProvider.notifier).videoController;
});

/// Convenience provider for current playback status.
final playbackStatusProvider = Provider<PlaybackStatus>((ref) {
  return ref.watch(playbackNotifierProvider).status;
});

/// Convenience provider for currently playing content.
final currentContentProvider = Provider<PlayableContent?>((ref) {
  return ref.watch(playbackNotifierProvider).content;
});

/// Convenience provider to check if something is playing.
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackNotifierProvider).isActive;
});

/// Provider for the currently playing channel ID (if any).
final currentChannelIdProvider = Provider<String?>((ref) {
  final state = ref.watch(playbackNotifierProvider);
  if (state.content?.type == ContentType.liveChannel) {
    return state.content?.id;
  }
  return null;
});
