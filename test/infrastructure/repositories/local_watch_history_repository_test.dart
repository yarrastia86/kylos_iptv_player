// Kylos IPTV Player - Local Watch History Repository Tests
// Unit tests for watch history persistence.

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/infrastructure/repositories/local_watch_history_repository.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late LocalWatchHistoryRepository repository;
  late MockLocalStorage mockStorage;

  setUp(() {
    mockStorage = MockLocalStorage();
    when(() => mockStorage.getString(any())).thenReturn(null);
    when(() => mockStorage.setString(any(), any())).thenAnswer((_) async => true);
    repository = LocalWatchHistoryRepository(localStorage: mockStorage);
  });

  group('LocalWatchHistoryRepository', () {
    group('saveProgress', () {
      test('should not save progress if position is less than 30 seconds', () async {
        final progress = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Test Movie',
          positionSeconds: 15,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        await repository.saveProgress(progress);

        verifyNever(() => mockStorage.setString(any(), any()));
      });

      test('should save progress if position is 30 seconds or more', () async {
        final progress = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Test Movie',
          positionSeconds: 60,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        await repository.saveProgress(progress);

        verify(() => mockStorage.setString(any(), any())).called(1);
      });
    });

    group('getProgress', () {
      test('should return null for non-existent content', () async {
        final progress = await repository.getProgress('non-existent');

        expect(progress, isNull);
      });

      test('should return saved progress', () async {
        final progress = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Test Movie',
          positionSeconds: 1800,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        await repository.saveProgress(progress);
        final retrieved = await repository.getProgress('movie-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.contentId, equals('movie-1'));
        expect(retrieved.positionSeconds, equals(1800));
      });
    });

    group('getContinueWatching', () {
      test('should return only resumable items', () async {
        // Completed item (>= 90%)
        final completed = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Completed Movie',
          positionSeconds: 3300,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        // In progress item (50%)
        final inProgress = WatchProgress(
          contentId: 'movie-2',
          contentType: WatchContentType.movie,
          title: 'In Progress Movie',
          positionSeconds: 1800,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        await repository.saveProgress(completed);
        await repository.saveProgress(inProgress);

        final continueWatching = await repository.getContinueWatching();

        expect(continueWatching.length, equals(1));
        expect(continueWatching.first.contentId, equals('movie-2'));
      });
    });

    group('removeProgress', () {
      test('should remove progress for content', () async {
        final progress = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Test Movie',
          positionSeconds: 1800,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        await repository.saveProgress(progress);
        await repository.removeProgress('movie-1');
        final retrieved = await repository.getProgress('movie-1');

        expect(retrieved, isNull);
      });
    });

    group('clearHistory', () {
      test('should clear all history', () async {
        final progress1 = WatchProgress(
          contentId: 'movie-1',
          contentType: WatchContentType.movie,
          title: 'Test Movie 1',
          positionSeconds: 1800,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        final progress2 = WatchProgress(
          contentId: 'movie-2',
          contentType: WatchContentType.movie,
          title: 'Test Movie 2',
          positionSeconds: 1200,
          durationSeconds: 3600,
          updatedAt: DateTime.now(),
        );

        when(() => mockStorage.remove(any())).thenAnswer((_) async => true);

        await repository.saveProgress(progress1);
        await repository.saveProgress(progress2);
        await repository.clearHistory();

        final history = await repository.getWatchHistory();

        expect(history.items, isEmpty);
      });
    });
  });

  group('WatchProgress', () {
    test('progress should calculate correctly', () {
      final progress = WatchProgress(
        contentId: 'movie-1',
        contentType: WatchContentType.movie,
        title: 'Test',
        positionSeconds: 1800,
        durationSeconds: 3600,
        updatedAt: DateTime.now(),
      );

      expect(progress.progress, equals(0.5));
      expect(progress.progressPercent, equals(50));
    });

    test('isCompleted should be true when >= 90%', () {
      final progress = WatchProgress(
        contentId: 'movie-1',
        contentType: WatchContentType.movie,
        title: 'Test',
        positionSeconds: 3240,
        durationSeconds: 3600,
        updatedAt: DateTime.now(),
      );

      expect(progress.isCompleted, isTrue);
    });

    test('canResume should be true when >= 1% and < 90%', () {
      final progress = WatchProgress(
        contentId: 'movie-1',
        contentType: WatchContentType.movie,
        title: 'Test',
        positionSeconds: 1800,
        durationSeconds: 3600,
        updatedAt: DateTime.now(),
      );

      expect(progress.canResume, isTrue);
    });

    test('episodeSubtitle should format correctly', () {
      final progress = WatchProgress(
        contentId: 'ep-1',
        contentType: WatchContentType.episode,
        title: 'Pilot',
        positionSeconds: 600,
        durationSeconds: 3600,
        seasonNumber: 1,
        episodeNumber: 5,
        seriesId: 'series-1',
        updatedAt: DateTime.now(),
      );

      expect(progress.episodeSubtitle, equals('S01E05'));
    });
  });
}
