// Kylos IPTV Player - Local Watch History Repository
// Implementation that stores watch progress in local storage.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_repository.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';

/// Local storage implementation of WatchHistoryRepository.
class LocalWatchHistoryRepository implements WatchHistoryRepository {
  LocalWatchHistoryRepository({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage {
    _loadFromStorage();
  }

  final LocalStorage _localStorage;

  static const _storageKey = 'watch_history';
  static const _maxHistoryItems = 100;

  // In-memory cache
  final Map<String, WatchProgress> _progressCache = {};

  void _loadFromStorage() {
    try {
      final jsonString = _localStorage.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        for (final item in jsonList) {
          final progress = WatchProgress.fromJson(item as Map<String, dynamic>);
          _progressCache[progress.contentId] = progress;
        }
        debugPrint('[LocalWatchHistoryRepository] Loaded ${_progressCache.length} items');
      }
    } catch (e) {
      debugPrint('[LocalWatchHistoryRepository] Error loading: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      // Sort by updatedAt descending and limit
      final sortedItems = _progressCache.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final limitedItems = sortedItems.take(_maxHistoryItems).toList();

      // Update cache to match limited items
      _progressCache.clear();
      for (final item in limitedItems) {
        _progressCache[item.contentId] = item;
      }

      final jsonList = limitedItems.map((p) => p.toJson()).toList();
      await _localStorage.setString(_storageKey, jsonEncode(jsonList));
      debugPrint('[LocalWatchHistoryRepository] Saved ${limitedItems.length} items');
    } catch (e) {
      debugPrint('[LocalWatchHistoryRepository] Error saving: $e');
    }
  }

  @override
  Future<WatchHistory> getWatchHistory({int limit = 50}) async {
    final sortedItems = _progressCache.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return WatchHistory(
      items: sortedItems.take(limit).toList(),
      totalCount: sortedItems.length,
    );
  }

  @override
  Future<WatchProgress?> getProgress(String contentId) async {
    return _progressCache[contentId];
  }

  @override
  Future<void> saveProgress(WatchProgress progress) async {
    // Don't save if position is basically at the start (< 30 seconds)
    if (progress.positionSeconds < 30) {
      return;
    }

    _progressCache[progress.contentId] = progress;
    await _saveToStorage();
  }

  @override
  Future<void> removeProgress(String contentId) async {
    _progressCache.remove(contentId);
    await _saveToStorage();
  }

  @override
  Future<void> clearHistory() async {
    _progressCache.clear();
    await _localStorage.remove(_storageKey);
  }

  @override
  Future<List<WatchProgress>> getContinueWatching({int limit = 20}) async {
    final resumableItems = _progressCache.values
        .where((p) => p.canResume)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return resumableItems.take(limit).toList();
  }

  @override
  Future<void> markAsCompleted(String contentId) async {
    final progress = _progressCache[contentId];
    if (progress != null) {
      _progressCache[contentId] = progress.copyWith(
        positionSeconds: progress.durationSeconds,
        updatedAt: DateTime.now(),
      );
      await _saveToStorage();
    }
  }

  @override
  Future<Map<String, WatchProgress>> getProgressForIds(
    List<String> contentIds,
  ) async {
    final result = <String, WatchProgress>{};
    for (final id in contentIds) {
      final progress = _progressCache[id];
      if (progress != null) {
        result[id] = progress;
      }
    }
    return result;
  }
}
