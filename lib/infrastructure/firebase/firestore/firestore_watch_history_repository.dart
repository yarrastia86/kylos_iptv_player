// Kylos IPTV Player - Firebase Watch History Repository
// Cloud Firestore implementation for cross-device watch progress sync.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_repository.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';

/// Firebase Firestore implementation of WatchHistoryRepository.
///
/// Syncs watch progress to the cloud for cross-device access.
class FirestoreWatchHistoryRepository implements WatchHistoryRepository {
  FirestoreWatchHistoryRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  static const _maxHistoryItems = 100;

  /// Reference to the user's watch history collection.
  CollectionReference<Map<String, dynamic>> get _progressCollection =>
      _firestore.collection('users/$_userId/watch_history');

  @override
  Future<WatchHistory> getWatchHistory({int limit = 50}) async {
    try {
      final snapshot = await _progressCollection
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      final items = snapshot.docs
          .map((doc) => _parseProgress(doc.id, doc.data()))
          .whereType<WatchProgress>()
          .toList();

      // Get total count
      final countSnapshot = await _progressCollection.count().get();
      final totalCount = countSnapshot.count ?? items.length;

      return WatchHistory(
        items: items,
        totalCount: totalCount,
      );
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error getting history: $e');
      return const WatchHistory();
    }
  }

  @override
  Future<WatchProgress?> getProgress(String contentId) async {
    try {
      final doc = await _progressCollection.doc(contentId).get();
      if (!doc.exists) return null;

      return _parseProgress(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error getting progress: $e');
      return null;
    }
  }

  @override
  Future<void> saveProgress(WatchProgress progress) async {
    // Don't save if position is basically at the start (< 30 seconds)
    if (progress.positionSeconds < 30) {
      return;
    }

    try {
      await _progressCollection.doc(progress.contentId).set({
        'contentId': progress.contentId,
        'contentType': progress.contentType.name,
        'title': progress.title,
        'positionSeconds': progress.positionSeconds,
        'durationSeconds': progress.durationSeconds,
        'posterUrl': progress.posterUrl,
        'seriesId': progress.seriesId,
        'seriesName': progress.seriesName,
        'seasonNumber': progress.seasonNumber,
        'episodeNumber': progress.episodeNumber,
        'streamUrl': progress.streamUrl,
        'containerExtension': progress.containerExtension,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cleanup old entries if we have too many
      await _cleanupOldEntries();
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error saving progress: $e');
    }
  }

  @override
  Future<void> removeProgress(String contentId) async {
    try {
      await _progressCollection.doc(contentId).delete();
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error removing progress: $e');
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      final batch = _firestore.batch();
      final docs = await _progressCollection.get();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error clearing history: $e');
    }
  }

  @override
  Future<List<WatchProgress>> getContinueWatching({int limit = 20}) async {
    try {
      final snapshot = await _progressCollection
          .orderBy('updatedAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final items = snapshot.docs
          .map((doc) => _parseProgress(doc.id, doc.data()))
          .whereType<WatchProgress>()
          .where((p) => p.canResume)
          .take(limit)
          .toList();

      return items;
    } catch (e) {
      debugPrint(
        'FirestoreWatchHistoryRepository: Error getting continue watching: $e',
      );
      return [];
    }
  }

  @override
  Future<void> markAsCompleted(String contentId) async {
    try {
      final doc = await _progressCollection.doc(contentId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final duration = data['durationSeconds'] as int? ?? 0;

      await _progressCollection.doc(contentId).update({
        'positionSeconds': duration,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error marking completed: $e');
    }
  }

  @override
  Future<Map<String, WatchProgress>> getProgressForIds(
    List<String> contentIds,
  ) async {
    if (contentIds.isEmpty) return {};

    try {
      // Firestore whereIn is limited to 30 items
      final result = <String, WatchProgress>{};
      final chunks = _chunkList(contentIds, 30);

      for (final chunk in chunks) {
        final snapshot = await _progressCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final progress = _parseProgress(doc.id, doc.data());
          if (progress != null) {
            result[progress.contentId] = progress;
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint(
        'FirestoreWatchHistoryRepository: Error getting progress for IDs: $e',
      );
      return {};
    }
  }

  /// Stream watch progress updates for real-time sync.
  Stream<WatchHistory> watchHistory({int limit = 50}) {
    return _progressCollection
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => _parseProgress(doc.id, doc.data()))
          .whereType<WatchProgress>()
          .toList();

      return WatchHistory(
        items: items,
        totalCount: items.length,
      );
    });
  }

  /// Stream continue watching updates.
  Stream<List<WatchProgress>> watchContinueWatching({int limit = 20}) {
    return _progressCollection
        .orderBy('updatedAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _parseProgress(doc.id, doc.data()))
          .whereType<WatchProgress>()
          .where((p) => p.canResume)
          .take(limit)
          .toList();
    });
  }

  WatchProgress? _parseProgress(String docId, Map<String, dynamic> data) {
    try {
      final contentTypeStr = data['contentType'] as String?;
      final contentType = WatchContentType.values.firstWhere(
        (t) => t.name == contentTypeStr,
        orElse: () => WatchContentType.movie,
      );

      // Handle timestamp
      final updatedAtValue = data['updatedAt'];
      DateTime updatedAt;
      if (updatedAtValue is Timestamp) {
        updatedAt = updatedAtValue.toDate();
      } else {
        updatedAt = DateTime.now();
      }

      return WatchProgress(
        contentId: docId,
        contentType: contentType,
        title: data['title'] as String? ?? 'Unknown',
        positionSeconds: data['positionSeconds'] as int? ?? 0,
        durationSeconds: data['durationSeconds'] as int? ?? 0,
        posterUrl: data['posterUrl'] as String?,
        seriesId: data['seriesId'] as String?,
        seriesName: data['seriesName'] as String?,
        seasonNumber: data['seasonNumber'] as int?,
        episodeNumber: data['episodeNumber'] as int?,
        streamUrl: data['streamUrl'] as String?,
        containerExtension: data['containerExtension'] as String?,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error parsing progress: $e');
      return null;
    }
  }

  Future<void> _cleanupOldEntries() async {
    try {
      final countSnapshot = await _progressCollection.count().get();
      final count = countSnapshot.count ?? 0;

      if (count <= _maxHistoryItems) return;

      // Get oldest entries to delete
      final toDelete = count - _maxHistoryItems;
      final oldestSnapshot = await _progressCollection
          .orderBy('updatedAt', descending: false)
          .limit(toDelete)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldestSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint(
        'FirestoreWatchHistoryRepository: Cleaned up $toDelete old entries',
      );
    } catch (e) {
      debugPrint('FirestoreWatchHistoryRepository: Error cleaning up: $e');
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      ));
    }
    return chunks;
  }
}
