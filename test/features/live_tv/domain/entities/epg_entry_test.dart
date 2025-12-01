// Kylos IPTV Player - EPG Entry Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';

void main() {
  group('EpgEntry', () {
    test('should create entry with required fields', () {
      final startTime = DateTime(2024, 1, 1, 10, 0);
      final endTime = DateTime(2024, 1, 1, 11, 0);

      final entry = EpgEntry(
        id: '1',
        channelId: 'ch1',
        title: 'Test Program',
        startTime: startTime,
        endTime: endTime,
      );

      expect(entry.id, '1');
      expect(entry.channelId, 'ch1');
      expect(entry.title, 'Test Program');
      expect(entry.startTime, startTime);
      expect(entry.endTime, endTime);
    });

    test('duration should calculate correctly', () {
      final entry = EpgEntry(
        id: '1',
        channelId: 'ch1',
        title: 'Test Program',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 30),
      );

      expect(entry.duration, const Duration(hours: 1, minutes: 30));
      expect(entry.durationMinutes, 90);
    });

    test('isCurrentlyAiring should work correctly', () {
      final now = DateTime.now();

      final currentEntry = EpgEntry(
        id: '1',
        channelId: 'ch1',
        title: 'Current',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      final pastEntry = EpgEntry(
        id: '2',
        channelId: 'ch1',
        title: 'Past',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
      );

      final futureEntry = EpgEntry(
        id: '3',
        channelId: 'ch1',
        title: 'Future',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
      );

      expect(currentEntry.isCurrentlyAiring, isTrue);
      expect(pastEntry.isCurrentlyAiring, isFalse);
      expect(futureEntry.isCurrentlyAiring, isFalse);
    });

    test('hasEnded and isUpcoming should work correctly', () {
      final now = DateTime.now();

      final pastEntry = EpgEntry(
        id: '1',
        channelId: 'ch1',
        title: 'Past',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
      );

      final futureEntry = EpgEntry(
        id: '2',
        channelId: 'ch1',
        title: 'Future',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
      );

      expect(pastEntry.hasEnded, isTrue);
      expect(pastEntry.isUpcoming, isFalse);
      expect(futureEntry.hasEnded, isFalse);
      expect(futureEntry.isUpcoming, isTrue);
    });

    test('progress should calculate correctly', () {
      final now = DateTime.now();

      // Entry that started 30 minutes ago, ends in 30 minutes
      final entry = EpgEntry(
        id: '1',
        channelId: 'ch1',
        title: 'Current',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      // Progress should be around 0.5 (50%)
      expect(entry.progress, closeTo(0.5, 0.02));

      // Past entry should have 100% progress
      final pastEntry = EpgEntry(
        id: '2',
        channelId: 'ch1',
        title: 'Past',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
      );
      expect(pastEntry.progress, 1.0);

      // Future entry should have 0% progress
      final futureEntry = EpgEntry(
        id: '3',
        channelId: 'ch1',
        title: 'Future',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
      );
      expect(futureEntry.progress, 0.0);
    });
  });

  group('EpisodeInfo', () {
    test('formatted should return S01E05 format', () {
      const info = EpisodeInfo(
        seasonNumber: 1,
        episodeNumber: 5,
      );

      expect(info.formatted, 'S01E05');
    });

    test('formatted should handle double digits', () {
      const info = EpisodeInfo(
        seasonNumber: 12,
        episodeNumber: 23,
      );

      expect(info.formatted, 'S12E23');
    });

    test('formatted should handle missing season', () {
      const info = EpisodeInfo(
        episodeNumber: 5,
      );

      expect(info.formatted, 'E05');
    });

    test('formatted should handle missing episode', () {
      const info = EpisodeInfo(
        seasonNumber: 1,
      );

      expect(info.formatted, 'S01');
    });

    test('formatted should return null when both are missing', () {
      const info = EpisodeInfo();

      expect(info.formatted, isNull);
    });
  });

  group('ChannelEpg', () {
    test('hasData should return true when current program exists', () {
      final epg = ChannelEpg(
        channelId: 'ch1',
        currentProgram: EpgEntry(
          id: '1',
          channelId: 'ch1',
          title: 'Current',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      expect(epg.hasData, isTrue);
    });

    test('hasData should return true when programs list is not empty', () {
      final epg = ChannelEpg(
        channelId: 'ch1',
        programs: [
          EpgEntry(
            id: '1',
            channelId: 'ch1',
            title: 'Program 1',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
          ),
        ],
      );

      expect(epg.hasData, isTrue);
    });

    test('hasData should return false for empty EPG', () {
      final epg = ChannelEpg.empty('ch1');
      expect(epg.hasData, isFalse);
    });
  });
}
