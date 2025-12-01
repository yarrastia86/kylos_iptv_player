// Kylos IPTV Player - Channel Entity Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

void main() {
  group('Channel', () {
    test('should create channel with required fields', () {
      const channel = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      expect(channel.id, '1');
      expect(channel.name, 'Test Channel');
      expect(channel.streamUrl, 'http://example.com/stream.m3u8');
      expect(channel.isFavorite, isFalse);
      expect(channel.isLocked, isFalse);
    });

    test('should create channel with all fields', () {
      const channel = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        categoryId: 'sports',
        logoUrl: 'http://example.com/logo.png',
        epgChannelId: 'test.channel',
        channelNumber: 123,
        isFavorite: true,
        isLocked: true,
      );

      expect(channel.categoryId, 'sports');
      expect(channel.logoUrl, 'http://example.com/logo.png');
      expect(channel.epgChannelId, 'test.channel');
      expect(channel.channelNumber, 123);
      expect(channel.isFavorite, isTrue);
      expect(channel.isLocked, isTrue);
    });

    test('copyWith should create copy with updated fields', () {
      const original = Channel(
        id: '1',
        name: 'Original',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final copy = original.copyWith(
        name: 'Updated',
        isFavorite: true,
      );

      expect(copy.id, '1');
      expect(copy.name, 'Updated');
      expect(copy.isFavorite, isTrue);
      expect(original.name, 'Original');
      expect(original.isFavorite, isFalse);
    });

    test('equality should be based on id', () {
      const channel1 = Channel(
        id: '1',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      const channel2 = Channel(
        id: '1',
        name: 'Different Name',
        streamUrl: 'http://example.com/2.m3u8',
      );

      const channel3 = Channel(
        id: '2',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      expect(channel1, equals(channel2));
      expect(channel1.hashCode, equals(channel2.hashCode));
      expect(channel1, isNot(equals(channel3)));
    });
  });
}
