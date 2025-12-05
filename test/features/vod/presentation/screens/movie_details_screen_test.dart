// Kylos IPTV Player - Movie Details Screen Tests
// Widget tests for the movie details screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_providers.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_repository.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/domain/repositories/vod_repository.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/features/vod/presentation/screens/movie_details_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockVodRepository extends Mock implements VodRepository {}

class MockWatchHistoryRepository extends Mock implements WatchHistoryRepository {}

void main() {
  late MockVodRepository mockVodRepository;
  late MockWatchHistoryRepository mockWatchHistoryRepository;

  setUp(() {
    mockVodRepository = MockVodRepository();
    mockWatchHistoryRepository = MockWatchHistoryRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        vodRepositoryProvider.overrideWithValue(mockVodRepository),
        watchHistoryRepositoryProvider.overrideWithValue(mockWatchHistoryRepository),
      ],
      child: const MaterialApp(
        home: MovieDetailsScreen(movieId: 'test-movie-1'),
      ),
    );
  }

  group('MovieDetailsScreen', () {
    testWidgets('should show loading indicator initially', (tester) async {
      when(() => mockVodRepository.getMovie('test-movie-1'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 5));
        return null;
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error when movie not found', (tester) async {
      when(() => mockVodRepository.getMovie('test-movie-1'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Movie not found'), findsOneWidget);
    });

    testWidgets('should display movie details when loaded', (tester) async {
      final movie = VodMovie(
        id: 'test-movie-1',
        name: 'Test Movie',
        streamUrl: 'http://example.com/stream.mp4',
        categoryName: 'Action',
        rating: '8.5',
        plot: 'This is a test movie plot.',
        director: 'Test Director',
        cast: 'Actor One, Actor Two',
      );

      when(() => mockVodRepository.getMovie('test-movie-1'))
          .thenAnswer((_) async => movie);
      when(() => mockWatchHistoryRepository.getProgress('test-movie-1'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test Movie'), findsOneWidget);
      expect(find.text('This is a test movie plot.'), findsOneWidget);
    });

    testWidgets('should show Resume button when has progress', (tester) async {
      final movie = VodMovie(
        id: 'test-movie-1',
        name: 'Test Movie',
        streamUrl: 'http://example.com/stream.mp4',
      );

      final progress = WatchProgress(
        contentId: 'test-movie-1',
        contentType: WatchContentType.movie,
        title: 'Test Movie',
        positionSeconds: 1800,
        durationSeconds: 3600,
        updatedAt: DateTime.now(),
      );

      when(() => mockVodRepository.getMovie('test-movie-1'))
          .thenAnswer((_) async => movie);
      when(() => mockWatchHistoryRepository.getProgress('test-movie-1'))
          .thenAnswer((_) async => progress);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });

    testWidgets('should show Play button when no progress', (tester) async {
      final movie = VodMovie(
        id: 'test-movie-1',
        name: 'Test Movie',
        streamUrl: 'http://example.com/stream.mp4',
      );

      when(() => mockVodRepository.getMovie('test-movie-1'))
          .thenAnswer((_) async => movie);
      when(() => mockWatchHistoryRepository.getProgress('test-movie-1'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
    });
  });
}
