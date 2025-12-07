// Kylos IPTV Player - Hybrid Watch History Repository
// Combines local and cloud storage for cross-device watch progress sync.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_repository.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/firestore_watch_history_repository.dart';
import 'package:kylos_iptv_player/infrastructure/repositories/local_watch_history_repository.dart';

/// Hybrid watch history repository that syncs between local and cloud storage.
///
/// - Uses local storage for fast reads and offline support
/// - Syncs to Firebase when user is authenticated (for cross-device access)
/// - Falls back to local-only when not authenticated or Firebase unavailable
class HybridWatchHistoryRepository implements WatchHistoryRepository {
  HybridWatchHistoryRepository({
    required LocalWatchHistoryRepository localRepository,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _localRepository = localRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _initializeCloudSync();
  }

  final LocalWatchHistoryRepository _localRepository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  FirestoreWatchHistoryRepository? _cloudRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<WatchHistory>? _cloudSyncSubscription;

  /// Whether cloud sync is enabled (user is authenticated).
  bool get _isCloudEnabled =>
      _cloudRepository != null && _firebaseAuth.currentUser != null;

  void _initializeCloudSync() {
    // Listen to auth state changes
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        _enableCloudSync(user.uid);
      } else {
        _disableCloudSync();
      }
    });

    // Check current user
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      _enableCloudSync(currentUser.uid);
    }
  }

  void _enableCloudSync(String userId) {
    _cloudRepository = FirestoreWatchHistoryRepository(
      firestore: _firestore,
      userId: userId,
    );

    // Start listening to cloud changes for real-time sync
    _cloudSyncSubscription?.cancel();
    _cloudSyncSubscription =
        _cloudRepository!.watchHistory(limit: 50).listen((cloudHistory) {
      // Sync cloud items to local (in background)
      _syncCloudToLocal(cloudHistory.items);
    });

    debugPrint('HybridWatchHistory: Cloud sync enabled for user $userId');
  }

  void _disableCloudSync() {
    _cloudSyncSubscription?.cancel();
    _cloudSyncSubscription = null;
    _cloudRepository = null;
    debugPrint('HybridWatchHistory: Cloud sync disabled');
  }

  /// Sync cloud items to local storage (merge, don't replace).
  Future<void> _syncCloudToLocal(List<WatchProgress> cloudItems) async {
    for (final cloudItem in cloudItems) {
      final localItem = await _localRepository.getProgress(cloudItem.contentId);

      // If cloud item is newer, update local
      if (localItem == null ||
          cloudItem.updatedAt.isAfter(localItem.updatedAt)) {
        await _localRepository.saveProgress(cloudItem);
      }
    }
  }

  /// Sync local item to cloud (in background).
  Future<void> _syncToCloud(WatchProgress progress) async {
    if (!_isCloudEnabled) return;

    try {
      await _cloudRepository!.saveProgress(progress);
    } catch (e) {
      debugPrint('HybridWatchHistory: Error syncing to cloud: $e');
      // Fail silently - local is always available
    }
  }

  @override
  Future<WatchHistory> getWatchHistory({int limit = 50}) async {
    // Prefer local for speed
    final localHistory = await _localRepository.getWatchHistory(limit: limit);

    // If cloud is enabled, merge cloud data in background
    if (_isCloudEnabled) {
      unawaited(_mergeCloudHistory());
    }

    return localHistory;
  }

  Future<void> _mergeCloudHistory() async {
    if (!_isCloudEnabled) return;

    try {
      final cloudHistory = await _cloudRepository!.getWatchHistory(limit: 100);
      await _syncCloudToLocal(cloudHistory.items);
    } catch (e) {
      debugPrint('HybridWatchHistory: Error merging cloud history: $e');
    }
  }

  @override
  Future<WatchProgress?> getProgress(String contentId) async {
    // Check local first
    final localProgress = await _localRepository.getProgress(contentId);

    // If cloud is enabled and local doesn't have it, check cloud
    if (localProgress == null && _isCloudEnabled) {
      try {
        final cloudProgress = await _cloudRepository!.getProgress(contentId);
        if (cloudProgress != null) {
          // Cache locally
          await _localRepository.saveProgress(cloudProgress);
          return cloudProgress;
        }
      } catch (e) {
        debugPrint('HybridWatchHistory: Error getting cloud progress: $e');
      }
    }

    return localProgress;
  }

  @override
  Future<void> saveProgress(WatchProgress progress) async {
    // Always save locally first (fast, offline-capable)
    await _localRepository.saveProgress(progress);

    // Sync to cloud in background
    unawaited(_syncToCloud(progress));
  }

  @override
  Future<void> removeProgress(String contentId) async {
    await _localRepository.removeProgress(contentId);

    if (_isCloudEnabled) {
      unawaited(_cloudRepository!.removeProgress(contentId));
    }
  }

  @override
  Future<void> clearHistory() async {
    await _localRepository.clearHistory();

    if (_isCloudEnabled) {
      unawaited(_cloudRepository!.clearHistory());
    }
  }

  @override
  Future<List<WatchProgress>> getContinueWatching({int limit = 20}) async {
    // Get local items
    final localItems = await _localRepository.getContinueWatching(limit: limit);

    // Merge cloud data in background
    if (_isCloudEnabled) {
      unawaited(_mergeCloudHistory());
    }

    return localItems;
  }

  @override
  Future<void> markAsCompleted(String contentId) async {
    await _localRepository.markAsCompleted(contentId);

    if (_isCloudEnabled) {
      unawaited(_cloudRepository!.markAsCompleted(contentId));
    }
  }

  @override
  Future<Map<String, WatchProgress>> getProgressForIds(
    List<String> contentIds,
  ) async {
    // Get from local
    final localProgress =
        await _localRepository.getProgressForIds(contentIds);

    // Merge cloud data for any missing items
    if (_isCloudEnabled) {
      final missingIds =
          contentIds.where((id) => !localProgress.containsKey(id)).toList();

      if (missingIds.isNotEmpty) {
        try {
          final cloudProgress =
              await _cloudRepository!.getProgressForIds(missingIds);

          // Merge and cache locally
          for (final entry in cloudProgress.entries) {
            localProgress[entry.key] = entry.value;
            await _localRepository.saveProgress(entry.value);
          }
        } catch (e) {
          debugPrint('HybridWatchHistory: Error getting cloud progress: $e');
        }
      }
    }

    return localProgress;
  }

  /// Force a full sync from cloud to local.
  ///
  /// Useful when user signs in on a new device.
  Future<void> forceCloudSync() async {
    if (!_isCloudEnabled) {
      debugPrint('HybridWatchHistory: Cannot sync - cloud not enabled');
      return;
    }

    try {
      debugPrint('HybridWatchHistory: Starting full cloud sync...');
      final cloudHistory = await _cloudRepository!.getWatchHistory(limit: 100);
      await _syncCloudToLocal(cloudHistory.items);
      debugPrint(
        'HybridWatchHistory: Synced ${cloudHistory.items.length} items from cloud',
      );
    } catch (e) {
      debugPrint('HybridWatchHistory: Error during full sync: $e');
    }
  }

  /// Dispose resources.
  void dispose() {
    _authSubscription?.cancel();
    _cloudSyncSubscription?.cancel();
  }
}
