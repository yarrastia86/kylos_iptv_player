// Kylos IPTV Player - Live TV Screen Widget Tests
// Tests for the Live TV screen integration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/live_tv/data/repositories/mock_channel_repository.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/channel_repository.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/channel_list_tile.dart';

void main() {
  group('ChannelListTile', () {
    testWidgets('displays channel name', (tester) async {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChannelListTile(channel: channel),
          ),
        ),
      );

      expect(find.text('Test Channel'), findsOneWidget);
    });

    testWidgets('displays channel number when available', (tester) async {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        channelNumber: 42,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChannelListTile(channel: channel),
          ),
        ),
      );

      expect(find.text('Ch. 42'), findsOneWidget);
    });

    testWidgets('shows LIVE indicator when playing', (tester) async {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChannelListTile(
              channel: channel,
              isPlaying: true,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('shows favorite icon when favorited', (tester) async {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelListTile(
              channel: channel,
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows lock icon when locked', (tester) async {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        isLocked: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChannelListTile(channel: channel),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelListTile(
              channel: channel,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ChannelListTile));
      expect(tapped, isTrue);
    });

    testWidgets('calls onFavoriteToggle when favorite button tapped',
        (tester) async {
      var toggled = false;
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelListTile(
              channel: channel,
              onFavoriteToggle: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(toggled, isTrue);
    });
  });

  group('ChannelListState', () {
    test('hasChannels returns true when channels exist', () {
      const state = ChannelListState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'Test',
            streamUrl: 'http://example.com/stream.m3u8',
          ),
        ],
      );

      expect(state.hasChannels, isTrue);
    });

    test('hasChannels returns false when empty', () {
      const state = ChannelListState();
      expect(state.hasChannels, isFalse);
    });

    test('hasMore returns true when more pages available', () {
      const state = ChannelListState(
        currentPage: 0,
        totalPages: 3,
      );

      expect(state.hasMore, isTrue);
    });

    test('hasMore returns false on last page', () {
      const state = ChannelListState(
        currentPage: 2,
        totalPages: 3,
      );

      expect(state.hasMore, isFalse);
    });
  });

  group('MockChannelRepository', () {
    late MockChannelRepository repository;

    setUp(() {
      repository = MockChannelRepository();
    });

    test('getCategories returns categories', () async {
      final categories = await repository.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name == 'News'), isTrue);
      expect(categories.any((c) => c.name == 'Sports'), isTrue);
    });

    test('getChannels returns paginated channels', () async {
      final result = await repository.getChannels(pageSize: 10);

      expect(result.channels, isNotEmpty);
      expect(result.channels.length, lessThanOrEqualTo(10));
      expect(result.currentPage, 0);
      expect(result.totalCount, greaterThan(0));
    });

    test('getChannels filters by category', () async {
      final result = await repository.getChannels(categoryId: 'news');

      expect(result.channels, isNotEmpty);
      expect(result.channels.every((c) => c.categoryId == 'news'), isTrue);
    });

    test('setFavorite and getFavoriteChannels work together', () async {
      await repository.setFavorite('ch1', true);
      final favorites = await repository.getFavoriteChannels();

      expect(favorites.any((c) => c.id == 'ch1'), isTrue);
      expect(favorites.every((c) => c.isFavorite), isTrue);
    });

    test('searchChannels finds matching channels', () async {
      final results = await repository.searchChannels('News');

      expect(results, isNotEmpty);
      expect(results.every((c) => c.name.toLowerCase().contains('news')),
          isTrue);
    });

    test('getChannel returns channel with id', () async {
      final channel = await repository.getChannel('ch1');

      expect(channel, isNotNull);
      expect(channel!.id, 'ch1');
    });

    test('getChannel returns null for unknown id', () async {
      final channel = await repository.getChannel('unknown');

      expect(channel, isNull);
    });
  });

  group('Integration: Channel selection updates playback state', () {
    test('selecting channel creates playable content', () {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        logoUrl: 'http://example.com/logo.png',
      );

      final content = PlayableContent.fromChannel(
        id: channel.id,
        name: channel.name,
        streamUrl: channel.streamUrl,
        logoUrl: channel.logoUrl,
      );

      expect(content.id, 'ch1');
      expect(content.title, 'Test Channel');
      expect(content.streamUrl, 'http://example.com/stream.m3u8');
      expect(content.type, ContentType.liveChannel);
      expect(content.isLive, isTrue);
    });

    test('PlaybackState.loading creates correct state from content', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState.loading(content);

      expect(state.status, PlaybackStatus.loading);
      expect(state.content, content);
      expect(state.hasContent, isTrue);
    });
  });
}
