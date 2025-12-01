// Kylos IPTV Player - Video Player Service Interface
// Abstraction layer for video playback to decouple from specific implementations.

import 'dart:async';

/// Configuration options for initializing a stream.
class StreamConfig {
  const StreamConfig({
    required this.url,
    this.headers = const {},
    this.startPosition = Duration.zero,
    this.autoPlay = true,
  });

  /// URL of the stream to play.
  final String url;

  /// HTTP headers to send with the stream request.
  final Map<String, String> headers;

  /// Position to start playback from.
  final Duration startPosition;

  /// Whether to start playing immediately after initialization.
  final bool autoPlay;
}

/// Events emitted by the video player.
sealed class VideoPlayerEvent {
  const VideoPlayerEvent();
}

/// Player is initializing.
class VideoPlayerInitializing extends VideoPlayerEvent {
  const VideoPlayerInitializing();
}

/// Player initialized and ready.
class VideoPlayerReady extends VideoPlayerEvent {
  const VideoPlayerReady({
    this.duration,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
  });

  final Duration? duration;
  final List<VideoAudioTrack> audioTracks;
  final List<VideoSubtitleTrack> subtitleTracks;
}

/// Playback started.
class VideoPlayerPlaying extends VideoPlayerEvent {
  const VideoPlayerPlaying();
}

/// Playback paused.
class VideoPlayerPaused extends VideoPlayerEvent {
  const VideoPlayerPaused();
}

/// Buffering state changed.
class VideoPlayerBuffering extends VideoPlayerEvent {
  const VideoPlayerBuffering({required this.isBuffering});
  final bool isBuffering;
}

/// Position updated.
class VideoPlayerPositionChanged extends VideoPlayerEvent {
  const VideoPlayerPositionChanged({
    required this.position,
    this.bufferedPosition,
  });

  final Duration position;
  final Duration? bufferedPosition;
}

/// Playback completed.
class VideoPlayerCompleted extends VideoPlayerEvent {
  const VideoPlayerCompleted();
}

/// Playback error occurred.
class VideoPlayerError extends VideoPlayerEvent {
  const VideoPlayerError({
    required this.message,
    this.code,
    this.isRecoverable = true,
  });

  final String message;
  final String? code;
  final bool isRecoverable;
}

/// Audio track information.
class VideoAudioTrack {
  const VideoAudioTrack({
    required this.id,
    required this.label,
    this.language,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String? language;
  final bool isDefault;
}

/// Subtitle track information.
class VideoSubtitleTrack {
  const VideoSubtitleTrack({
    required this.id,
    required this.label,
    this.language,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String? language;
  final bool isDefault;
}

/// Abstract interface for video player implementations.
///
/// This abstraction allows swapping video player implementations
/// without changing business logic or UI code.
abstract class VideoPlayerService {
  /// Stream of player events.
  Stream<VideoPlayerEvent> get events;

  /// Current playback position.
  Duration get position;

  /// Total duration (null for live streams).
  Duration? get duration;

  /// Whether the player is currently playing.
  bool get isPlaying;

  /// Whether the player is currently buffering.
  bool get isBuffering;

  /// Current volume (0.0 to 1.0).
  double get volume;

  /// Whether audio is muted.
  bool get isMuted;

  /// Current playback speed.
  double get playbackSpeed;

  /// Available audio tracks.
  List<VideoAudioTrack> get audioTracks;

  /// Currently selected audio track.
  VideoAudioTrack? get selectedAudioTrack;

  /// Available subtitle tracks.
  List<VideoSubtitleTrack> get subtitleTracks;

  /// Currently selected subtitle track.
  VideoSubtitleTrack? get selectedSubtitleTrack;

  /// Initializes the player with a stream configuration.
  Future<void> initialize(StreamConfig config);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Seeks to a position.
  Future<void> seekTo(Duration position);

  /// Sets volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Mutes or unmutes audio.
  Future<void> setMuted(bool muted);

  /// Sets playback speed.
  Future<void> setPlaybackSpeed(double speed);

  /// Selects an audio track by ID.
  Future<void> selectAudioTrack(String trackId);

  /// Selects a subtitle track by ID (null to disable).
  Future<void> selectSubtitleTrack(String? trackId);

  /// Stops playback and releases resources.
  Future<void> stop();

  /// Disposes the player and releases all resources.
  Future<void> dispose();
}
