// Kylos IPTV Player - Watch Progress Entity
// Domain entity for tracking playback progress.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'watch_progress.freezed.dart';
part 'watch_progress.g.dart';

/// Type of content for watch progress tracking.
enum WatchContentType {
  movie,
  episode,
}

/// Represents watch progress for a piece of content.
@freezed
class WatchProgress with _$WatchProgress {
  const factory WatchProgress({
    /// Unique ID of the content (movie ID or episode ID).
    required String contentId,

    /// Type of content.
    required WatchContentType contentType,

    /// Title of the content for display.
    required String title,

    /// Current playback position in seconds.
    required int positionSeconds,

    /// Total duration in seconds.
    required int durationSeconds,

    /// Poster or thumbnail URL.
    String? posterUrl,

    /// Series ID (for episodes only).
    String? seriesId,

    /// Series name (for episodes only).
    String? seriesName,

    /// Season number (for episodes only).
    int? seasonNumber,

    /// Episode number (for episodes only).
    int? episodeNumber,

    /// Stream URL for quick resume.
    String? streamUrl,

    /// Container extension for building stream URL.
    String? containerExtension,

    /// When this progress was last updated.
    required DateTime updatedAt,
  }) = _WatchProgress;

  const WatchProgress._();

  factory WatchProgress.fromJson(Map<String, dynamic> json) =>
      _$WatchProgressFromJson(json);

  /// Progress percentage (0.0 to 1.0).
  double get progress {
    if (durationSeconds == 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  /// Progress percentage as integer (0 to 100).
  int get progressPercent => (progress * 100).round();

  /// Position as Duration.
  Duration get position => Duration(seconds: positionSeconds);

  /// Duration as Duration.
  Duration get duration => Duration(seconds: durationSeconds);

  /// Remaining time as Duration.
  Duration get remaining => Duration(seconds: durationSeconds - positionSeconds);

  /// Whether the content has been fully watched (>= 90%).
  bool get isCompleted => progress >= 0.90;

  /// Whether there's meaningful progress to resume (>= 1% and < 90%).
  bool get canResume => progress >= 0.01 && progress < 0.90;

  /// Display subtitle for episodes.
  String? get episodeSubtitle {
    if (contentType != WatchContentType.episode) return null;
    if (seasonNumber == null || episodeNumber == null) return null;
    return 'S${seasonNumber!.toString().padLeft(2, '0')}E${episodeNumber!.toString().padLeft(2, '0')}';
  }
}

/// A list of watch progress items for continue watching.
@freezed
class WatchHistory with _$WatchHistory {
  const factory WatchHistory({
    @Default([]) List<WatchProgress> items,
    @Default(0) int totalCount,
  }) = _WatchHistory;

  const WatchHistory._();

  factory WatchHistory.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryFromJson(json);

  /// Gets only items that can be resumed.
  List<WatchProgress> get resumableItems =>
      items.where((item) => item.canResume).toList();

  /// Gets movies in progress.
  List<WatchProgress> get moviesInProgress => items
      .where((item) =>
          item.contentType == WatchContentType.movie && item.canResume)
      .toList();

  /// Gets episodes in progress.
  List<WatchProgress> get episodesInProgress => items
      .where((item) =>
          item.contentType == WatchContentType.episode && item.canResume)
      .toList();

  /// Checks if a content ID exists in history.
  bool hasProgress(String contentId) =>
      items.any((item) => item.contentId == contentId);

  /// Gets progress for a specific content ID.
  WatchProgress? getProgress(String contentId) {
    try {
      return items.firstWhere((item) => item.contentId == contentId);
    } catch (_) {
      return null;
    }
  }
}
