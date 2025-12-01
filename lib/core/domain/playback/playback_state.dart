// Kylos IPTV Player - Playback State
// Domain model for unified playback state across all content types.

/// Status of the playback engine.
enum PlaybackStatus {
  /// Player is idle, no content loaded.
  idle,

  /// Content is being loaded/initialized.
  loading,

  /// Content is buffering.
  buffering,

  /// Content is actively playing.
  playing,

  /// Playback is paused.
  paused,

  /// An error occurred.
  error,

  /// Playback has ended.
  ended,
}

/// Type of content being played.
enum ContentType {
  /// Live TV channel.
  liveChannel,

  /// Video on demand (movie).
  vod,

  /// Series episode.
  episode,
}

/// Error that occurred during playback.
class PlaybackError {
  const PlaybackError({
    required this.code,
    required this.message,
    this.isRecoverable = false,
  });

  /// Error code for categorization.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Whether the error can be recovered from (e.g., retry).
  final bool isRecoverable;

  /// Network connectivity error.
  factory PlaybackError.network() {
    return const PlaybackError(
      code: 'network_error',
      message: 'Unable to connect. Please check your internet connection.',
      isRecoverable: true,
    );
  }

  /// Stream unavailable error.
  factory PlaybackError.streamUnavailable() {
    return const PlaybackError(
      code: 'stream_unavailable',
      message: 'This content is currently unavailable.',
      isRecoverable: true,
    );
  }

  /// Format not supported error.
  factory PlaybackError.unsupportedFormat() {
    return const PlaybackError(
      code: 'unsupported_format',
      message: 'This stream format is not supported.',
      isRecoverable: false,
    );
  }

  /// Authentication/subscription error.
  factory PlaybackError.unauthorized() {
    return const PlaybackError(
      code: 'unauthorized',
      message: 'You do not have access to this content.',
      isRecoverable: false,
    );
  }

  /// Generic playback error.
  factory PlaybackError.unknown([String? details]) {
    return const PlaybackError(
      code: 'unknown',
      message: 'Unable to play this channel. Please try again.',
      isRecoverable: true,
    );
  }

  @override
  String toString() => 'PlaybackError($code: $message)';
}

/// Represents content that can be played.
class PlayableContent {
  const PlayableContent({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.type,
    this.logoUrl,
    this.categoryName,
    this.duration,
    this.resumePosition,
  });

  /// Unique identifier of the content.
  final String id;

  /// Display title.
  final String title;

  /// URL of the stream.
  final String streamUrl;

  /// Type of content.
  final ContentType type;

  /// Logo or poster URL.
  final String? logoUrl;

  /// Category name for display.
  final String? categoryName;

  /// Duration for VOD content.
  final Duration? duration;

  /// Position to resume from.
  final Duration? resumePosition;

  /// Whether this is live content.
  bool get isLive => type == ContentType.liveChannel;

  /// Creates a PlayableContent from a channel.
  factory PlayableContent.fromChannel({
    required String id,
    required String name,
    required String streamUrl,
    String? logoUrl,
    String? categoryName,
  }) {
    return PlayableContent(
      id: id,
      title: name,
      streamUrl: streamUrl,
      type: ContentType.liveChannel,
      logoUrl: logoUrl,
      categoryName: categoryName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayableContent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() => 'PlayableContent($id, $title, $type)';
}

/// Audio track information.
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.label,
    this.language,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String? language;
  final bool isDefault;

  @override
  String toString() => 'AudioTrack($id, $label)';
}

/// Subtitle track information.
class SubtitleTrack {
  const SubtitleTrack({
    required this.id,
    required this.label,
    this.language,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String? language;
  final bool isDefault;

  @override
  String toString() => 'SubtitleTrack($id, $label)';
}

/// Unified playback state for all content types.
///
/// Represents the current state of the video player including:
/// - What is playing
/// - Current playback status
/// - Position and duration
/// - Available tracks
/// - Error state
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.content,
    this.position,
    this.duration,
    this.bufferedPosition,
    this.playbackSpeed = 1.0,
    this.audioTracks = const [],
    this.selectedAudioTrack,
    this.subtitleTracks = const [],
    this.selectedSubtitleTrack,
    this.error,
  });

  /// Current playback status.
  final PlaybackStatus status;

  /// Content currently loaded.
  final PlayableContent? content;

  /// Current playback position.
  final Duration? position;

  /// Total duration of the content (null for live).
  final Duration? duration;

  /// Amount of content buffered.
  final Duration? bufferedPosition;

  /// Current playback speed (1.0 = normal).
  final double playbackSpeed;

  /// Available audio tracks.
  final List<AudioTrack> audioTracks;

  /// Currently selected audio track.
  final AudioTrack? selectedAudioTrack;

  /// Available subtitle tracks.
  final List<SubtitleTrack> subtitleTracks;

  /// Currently selected subtitle track (null = off).
  final SubtitleTrack? selectedSubtitleTrack;

  /// Error if status is error.
  final PlaybackError? error;

  /// Whether any content is loaded.
  bool get hasContent => content != null;

  /// Whether playback is active (playing or buffering).
  bool get isActive =>
      status == PlaybackStatus.playing || status == PlaybackStatus.buffering;

  /// Whether content is live (no seeking).
  bool get isLive => content?.isLive ?? false;

  /// Progress percentage (0.0 to 1.0) for VOD content.
  double get progress {
    if (position == null || duration == null || duration!.inSeconds == 0) {
      return 0.0;
    }
    return position!.inSeconds / duration!.inSeconds;
  }

  /// Buffer progress percentage (0.0 to 1.0).
  double get bufferProgress {
    if (bufferedPosition == null ||
        duration == null ||
        duration!.inSeconds == 0) {
      return 0.0;
    }
    return bufferedPosition!.inSeconds / duration!.inSeconds;
  }

  /// Creates an initial idle state.
  factory PlaybackState.initial() {
    return const PlaybackState();
  }

  /// Creates a loading state for content.
  factory PlaybackState.loading(PlayableContent content) {
    return PlaybackState(
      status: PlaybackStatus.loading,
      content: content,
    );
  }

  /// Creates an error state.
  factory PlaybackState.withError(PlaybackError error) {
    return PlaybackState(
      status: PlaybackStatus.error,
      error: error,
    );
  }

  /// Creates a copy with the given fields replaced.
  PlaybackState copyWith({
    PlaybackStatus? status,
    PlayableContent? content,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? playbackSpeed,
    List<AudioTrack>? audioTracks,
    AudioTrack? selectedAudioTrack,
    List<SubtitleTrack>? subtitleTracks,
    SubtitleTrack? selectedSubtitleTrack,
    PlaybackError? error,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      content: content ?? this.content,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      audioTracks: audioTracks ?? this.audioTracks,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      selectedSubtitleTrack:
          selectedSubtitleTrack ?? this.selectedSubtitleTrack,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'PlaybackState($status, ${content?.title ?? 'no content'})';
}
