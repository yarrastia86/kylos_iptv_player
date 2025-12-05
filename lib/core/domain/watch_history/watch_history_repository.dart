// Kylos IPTV Player - Watch History Repository Interface
// Domain layer interface for watch progress operations.

import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';

/// Repository interface for watch history operations.
///
/// Defines the contract for storing and retrieving watch progress
/// from any source (local storage, Firebase, etc.).
abstract class WatchHistoryRepository {
  /// Gets all watch progress items, sorted by most recently updated.
  Future<WatchHistory> getWatchHistory({int limit = 50});

  /// Gets watch progress for a specific content ID.
  Future<WatchProgress?> getProgress(String contentId);

  /// Saves or updates watch progress.
  Future<void> saveProgress(WatchProgress progress);

  /// Removes watch progress for a content ID.
  Future<void> removeProgress(String contentId);

  /// Clears all watch history.
  Future<void> clearHistory();

  /// Gets continue watching items (resumable only).
  Future<List<WatchProgress>> getContinueWatching({int limit = 20});

  /// Marks content as completed.
  Future<void> markAsCompleted(String contentId);

  /// Gets watch progress for multiple content IDs.
  Future<Map<String, WatchProgress>> getProgressForIds(List<String> contentIds);
}
