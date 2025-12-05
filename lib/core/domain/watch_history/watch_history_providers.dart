// Kylos IPTV Player - Watch History Providers
// Riverpod providers for watch history state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_repository.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';

/// Provider for the watch history repository.
/// Must be overridden in bootstrap.dart.
final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  throw UnimplementedError(
    'watchHistoryRepositoryProvider must be overridden with an implementation',
  );
});

/// Provider for continue watching items.
final continueWatchingProvider =
    FutureProvider.autoDispose<List<WatchProgress>>((ref) async {
  final repository = ref.watch(watchHistoryRepositoryProvider);
  return repository.getContinueWatching(limit: 20);
});

/// Provider for full watch history.
final watchHistoryProvider =
    FutureProvider.autoDispose<WatchHistory>((ref) async {
  final repository = ref.watch(watchHistoryRepositoryProvider);
  return repository.getWatchHistory();
});

/// Provider for getting progress for a specific content.
final watchProgressProvider =
    FutureProvider.autoDispose.family<WatchProgress?, String>(
  (ref, contentId) async {
    final repository = ref.watch(watchHistoryRepositoryProvider);
    return repository.getProgress(contentId);
  },
);

/// Notifier for managing watch progress updates.
class WatchProgressNotifier extends StateNotifier<AsyncValue<void>> {
  WatchProgressNotifier(this._repository) : super(const AsyncValue.data(null));

  final WatchHistoryRepository _repository;

  /// Saves progress for content.
  Future<void> saveProgress(WatchProgress progress) async {
    try {
      await _repository.saveProgress(progress);
    } catch (e) {
      // Silently fail - watch progress is non-critical
    }
  }

  /// Removes progress for content.
  Future<void> removeProgress(String contentId) async {
    try {
      await _repository.removeProgress(contentId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Marks content as completed.
  Future<void> markAsCompleted(String contentId) async {
    try {
      await _repository.markAsCompleted(contentId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clears all history.
  Future<void> clearHistory() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearHistory();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the watch progress notifier.
final watchProgressNotifierProvider =
    StateNotifierProvider<WatchProgressNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(watchHistoryRepositoryProvider);
  return WatchProgressNotifier(repository);
});
