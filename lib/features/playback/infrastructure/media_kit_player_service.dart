// Kylos IPTV Player - Media Kit Player Service
// Implementation of VideoPlayerService using media_kit.

import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:kylos_iptv_player/features/playback/domain/video_player_service.dart';

/// Implementation of VideoPlayerService using media_kit.
///
/// This class wraps the media_kit Player and provides a clean interface
/// that can be easily tested and swapped if needed.
class MediaKitPlayerService implements VideoPlayerService {
  MediaKitPlayerService() : _player = Player();

  final Player _player;
  final StreamController<VideoPlayerEvent> _eventController =
      StreamController<VideoPlayerEvent>.broadcast();

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Tracks>? _tracksSubscription;

  bool _isInitialized = false;
  List<VideoAudioTrack> _audioTracks = [];
  List<VideoSubtitleTrack> _subtitleTracks = [];
  VideoAudioTrack? _selectedAudioTrack;
  VideoSubtitleTrack? _selectedSubtitleTrack;

  @override
  Stream<VideoPlayerEvent> get events => _eventController.stream;

  @override
  Duration get position => _player.state.position;

  @override
  Duration? get duration {
    final d = _player.state.duration;
    // Return null for live streams (duration is 0 or very large)
    if (d == Duration.zero || d.inHours > 24) {
      return null;
    }
    return d;
  }

  @override
  bool get isPlaying => _player.state.playing;

  @override
  bool get isBuffering => _player.state.buffering;

  @override
  double get volume => _player.state.volume / 100.0;

  @override
  bool get isMuted => _player.state.volume == 0;

  @override
  double get playbackSpeed => _player.state.rate;

  @override
  List<VideoAudioTrack> get audioTracks => _audioTracks;

  @override
  VideoAudioTrack? get selectedAudioTrack => _selectedAudioTrack;

  @override
  List<VideoSubtitleTrack> get subtitleTracks => _subtitleTracks;

  @override
  VideoSubtitleTrack? get selectedSubtitleTrack => _selectedSubtitleTrack;

  @override
  Future<void> initialize(StreamConfig config) async {
    _eventController.add(const VideoPlayerInitializing());

    try {
      // Set up event subscriptions
      _setupSubscriptions();

      // Open the media with optional headers
      final media = Media(
        config.url,
        httpHeaders: config.headers,
        start: config.startPosition,
        extras: const {
          // =================================================================
          // IPTV/HLS Stable Playback Configuration
          // =================================================================
          // This configuration prioritizes STABILITY and A/V SYNC over
          // ultra-low latency. The aggressive "low-latency" profile and
          // minimal "hls-live-edge" settings cause slideshow-like playback
          // and desync on real devices because:
          //   1. IPTV streams often have variable bitrates and segment timing
          //   2. Network jitter requires buffering headroom
          //   3. Device decoders need time to process frames smoothly
          //
          // These settings are tuned for typical IPTV/HLS streams and work
          // well across Android, iOS, and TV devices.
          // =================================================================

          // --- Hardware Decoding ---
          // Use hardware acceleration when safely available. "auto-safe" tries
          // hw decoding but falls back to software if the codec is unsupported,
          // preventing crashes on edge-case streams.
          'hwdec': 'auto-safe',

          // --- Caching & Buffering ---
          // Enable cache for smoother playback on variable network conditions.
          'cache': 'yes',
          // Buffer up to 30 seconds of content. This provides enough headroom
          // for network hiccups without excessive memory usage.
          'cache-secs': '30',
          // Allow the demuxer to read ahead 10 seconds. This helps with streams
          // that have irregular segment delivery times.
          'demuxer-readahead-secs': '10',

          // --- Timestamp Correction ---
          // Fixes A/V desync caused by streams with inaccurate timestamps,
          // which is common in re-encoded or poorly muxed IPTV content.
          'correct-pts': 'yes',

          // --- Audio/Video Synchronization ---
          // "audio" sync mode: video frames are dropped or repeated to match
          // the audio clock. This is more stable than "display-sync" which
          // tries to match the display refresh rate and can cause judder or
          // desync on mobile devices with variable refresh rates.
          'video-sync': 'audio',

          // =================================================================
          // REMOVED aggressive options that caused issues:
          // - 'profile': 'low-latency' -> causes excessive frame drops
          // - 'hls-live-edge': '3' -> too close to live edge, causes buffering
          // =================================================================
        },
      );

      await _player.open(media, play: config.autoPlay);
      _isInitialized = true;

      // Emit ready event after a short delay to allow tracks to load
      await Future<void>.delayed(const Duration(milliseconds: 500));

      _eventController.add(VideoPlayerReady(
        duration: duration,
        audioTracks: _audioTracks,
        subtitleTracks: _subtitleTracks,
      ));
    } catch (e) {
      _eventController.add(VideoPlayerError(
        message: _parseErrorMessage(e.toString()),
        isRecoverable: _isRecoverableError(e.toString()),
      ));
    }
  }

  void _setupSubscriptions() {
    _playingSubscription = _player.stream.playing.listen((playing) {
      if (playing) {
        _eventController.add(const VideoPlayerPlaying());
      } else if (_isInitialized) {
        _eventController.add(const VideoPlayerPaused());
      }
    });

    _positionSubscription = _player.stream.position.listen((position) {
      _eventController.add(VideoPlayerPositionChanged(
        position: position,
        bufferedPosition: _player.state.buffer,
      ));
    });

    _durationSubscription = _player.stream.duration.listen((duration) {
      // Duration changed, update ready state if needed
    });

    _bufferSubscription = _player.stream.buffer.listen((buffer) {
      _eventController.add(VideoPlayerPositionChanged(
        position: position,
        bufferedPosition: buffer,
      ));
    });

    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      _eventController.add(VideoPlayerBuffering(isBuffering: buffering));
    });

    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed) {
        _eventController.add(const VideoPlayerCompleted());
      }
    });

    _errorSubscription = _player.stream.error.listen((error) {
      if (error.isNotEmpty && !_isIgnorableError(error)) {
        _eventController.add(VideoPlayerError(
          message: _parseErrorMessage(error),
          isRecoverable: _isRecoverableError(error),
        ));
      }
    });

    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      _updateTracks(tracks);
    });
  }

  bool _isIgnorableError(String error) {
    final lowerError = error.toLowerCase();
    // Ignore common non-fatal mpv warnings that shouldn't be shown to the user
    // as a fatal error.
    const ignorableErrors = [
      'format not supported in overlay', // A common Android fallback warning. Video still plays.
    ];

    for (final ignorable in ignorableErrors) {
      if (lowerError.contains(ignorable)) {
        // It's a known non-fatal warning, so we can ignore it.
        return true;
      }
    }
    return false;
  }

  void _updateTracks(Tracks tracks) {
    // Map audio tracks
    _audioTracks = tracks.audio.map((track) {
      return VideoAudioTrack(
        id: track.id,
        label: track.title ?? track.language ?? 'Track ${track.id}',
        language: track.language,
      );
    }).toList();

    // Map subtitle tracks
    _subtitleTracks = tracks.subtitle.map((track) {
      return VideoSubtitleTrack(
        id: track.id,
        label: track.title ?? track.language ?? 'Subtitle ${track.id}',
        language: track.language,
      );
    }).toList();

    // Update selected tracks
    final audioTrack = _player.state.track.audio;
    if (audioTrack != AudioTrack.no()) {
      _selectedAudioTrack = _audioTracks.cast<VideoAudioTrack?>().firstWhere(
            (t) => t?.id == audioTrack.id,
            orElse: () => null,
          );
    }

    final subtitleTrack = _player.state.track.subtitle;
    if (subtitleTrack != SubtitleTrack.no()) {
      _selectedSubtitleTrack =
          _subtitleTracks.cast<VideoSubtitleTrack?>().firstWhere(
                (t) => t?.id == subtitleTrack.id,
                orElse: () => null,
              );
    }
  }

  String _parseErrorMessage(String error) {
    // Parse common IPTV stream errors into user-friendly messages
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('unreachable')) {
      return 'Network error. Please check your connection.';
    }

    if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'Stream not found. The channel may be unavailable.';
    }

    if (lowerError.contains('403') || lowerError.contains('forbidden')) {
      return 'Access denied. Please check your subscription.';
    }

    if (lowerError.contains('401') || lowerError.contains('unauthorized')) {
      return 'Authentication failed. Please check your credentials.';
    }

    if (lowerError.contains('format') || lowerError.contains('codec')) {
      return 'Unsupported stream format.';
    }

    if (lowerError.contains('failed to open') ||
        lowerError.contains('could not open') ||
        lowerError.contains('unable to open')) {
      return 'Unable to load stream. Please try again.';
    }

    if (lowerError.contains('eof') || lowerError.contains('end of file')) {
      return 'Stream ended unexpectedly.';
    }

    if (lowerError.contains('ssl') || lowerError.contains('certificate')) {
      return 'Secure connection failed.';
    }

    if (lowerError.contains('dns') || lowerError.contains('resolve')) {
      return 'Could not connect to server.';
    }

    // Default user-friendly message (never expose URLs or technical details)
    return 'Unable to play this channel. Please try again.';
  }

  bool _isRecoverableError(String error) {
    final lowerError = error.toLowerCase();

    // Non-recoverable errors
    if (lowerError.contains('format') ||
        lowerError.contains('codec') ||
        lowerError.contains('unsupported')) {
      return false;
    }

    // Most errors are recoverable (network issues, temporary unavailability)
    return true;
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0) * 100);
  }

  @override
  Future<void> setMuted(bool muted) async {
    if (muted) {
      await _player.setVolume(0);
    } else {
      await _player.setVolume(100);
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setRate(speed.clamp(0.25, 4.0));
  }

  @override
  Future<void> selectAudioTrack(String trackId) async {
    final track = _player.state.tracks.audio.cast<AudioTrack?>().firstWhere(
          (t) => t?.id == trackId,
          orElse: () => null,
        );
    if (track != null) {
      await _player.setAudioTrack(track);
      _selectedAudioTrack = _audioTracks.cast<VideoAudioTrack?>().firstWhere(
            (t) => t?.id == trackId,
            orElse: () => null,
          );
    }
  }

  @override
  Future<void> selectSubtitleTrack(String? trackId) async {
    if (trackId == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      _selectedSubtitleTrack = null;
      return;
    }

    final track = _player.state.tracks.subtitle.cast<SubtitleTrack?>().firstWhere(
          (t) => t?.id == trackId,
          orElse: () => null,
        );
    if (track != null) {
      await _player.setSubtitleTrack(track);
      _selectedSubtitleTrack =
          _subtitleTracks.cast<VideoSubtitleTrack?>().firstWhere(
                (t) => t?.id == trackId,
                orElse: () => null,
              );
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _isInitialized = false;
  }

  @override
  Future<void> dispose() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferSubscription?.cancel();
    await _bufferingSubscription?.cancel();
    await _completedSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _tracksSubscription?.cancel();

    await _player.dispose();
    await _eventController.close();
  }
}
