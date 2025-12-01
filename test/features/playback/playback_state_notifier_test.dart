// Kylos IPTV Player - Playback State Notifier Tests
// Tests for playback state management (without actual video plugin).

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

void main() {
  group('PlaybackState', () {
    test('initial state should be idle with no content', () {
      final state = PlaybackState.initial();

      expect(state.status, PlaybackStatus.idle);
      expect(state.content, isNull);
      expect(state.hasContent, isFalse);
      expect(state.isActive, isFalse);
      expect(state.error, isNull);
    });

    test('loading state should have content but not be active', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState.loading(content);

      expect(state.status, PlaybackStatus.loading);
      expect(state.content, content);
      expect(state.hasContent, isTrue);
      expect(state.isActive, isFalse);
    });

    test('playing state should be active', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.playing,
        content: content,
      );

      expect(state.isActive, isTrue);
    });

    test('buffering state should be active', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.buffering,
        content: content,
      );

      expect(state.isActive, isTrue);
    });

    test('paused state should not be active', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.paused,
        content: content,
      );

      expect(state.isActive, isFalse);
    });

    test('error state should contain error details', () {
      final error = PlaybackError.network();
      final state = PlaybackState.withError(error);

      expect(state.status, PlaybackStatus.error);
      expect(state.error, error);
      expect(state.error?.isRecoverable, isTrue);
    });

    test('isLive should return true for live channel content', () {
      final liveContent = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Live Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.playing,
        content: liveContent,
      );

      expect(state.isLive, isTrue);
    });

    test('isLive should return false for VOD content', () {
      const vodContent = PlayableContent(
        id: 'movie1',
        title: 'Test Movie',
        streamUrl: 'http://example.com/movie.mp4',
        type: ContentType.vod,
        duration: Duration(hours: 2),
      );

      const state = PlaybackState(
        status: PlaybackStatus.playing,
        content: vodContent,
      );

      expect(state.isLive, isFalse);
    });

    test('progress should calculate correctly for VOD', () {
      const vodContent = PlayableContent(
        id: 'movie1',
        title: 'Test Movie',
        streamUrl: 'http://example.com/movie.mp4',
        type: ContentType.vod,
      );

      const state = PlaybackState(
        status: PlaybackStatus.playing,
        content: vodContent,
        position: Duration(minutes: 30),
        duration: Duration(hours: 1),
      );

      expect(state.progress, 0.5);
    });

    test('progress should return 0 for live content', () {
      final liveContent = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Live Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.playing,
        content: liveContent,
        position: const Duration(minutes: 30),
        // No duration for live
      );

      expect(state.progress, 0.0);
    });

    test('copyWith should preserve unset fields', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final original = PlaybackState(
        status: PlaybackStatus.playing,
        content: content,
        position: const Duration(minutes: 5),
      );

      final updated = original.copyWith(status: PlaybackStatus.paused);

      expect(updated.status, PlaybackStatus.paused);
      expect(updated.content, content);
      expect(updated.position, const Duration(minutes: 5));
    });
  });

  group('PlayableContent', () {
    test('fromChannel creates live content', () {
      final content = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        logoUrl: 'http://example.com/logo.png',
        categoryName: 'News',
      );

      expect(content.id, 'ch1');
      expect(content.title, 'Test Channel');
      expect(content.streamUrl, 'http://example.com/stream.m3u8');
      expect(content.type, ContentType.liveChannel);
      expect(content.isLive, isTrue);
      expect(content.logoUrl, 'http://example.com/logo.png');
      expect(content.categoryName, 'News');
    });

    test('VOD content is not live', () {
      const content = PlayableContent(
        id: 'movie1',
        title: 'Test Movie',
        streamUrl: 'http://example.com/movie.mp4',
        type: ContentType.vod,
      );

      expect(content.isLive, isFalse);
    });

    test('equality based on id and type', () {
      final content1 = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      final content2 = PlayableContent.fromChannel(
        id: 'ch1',
        name: 'Different Name',
        streamUrl: 'http://example.com/2.m3u8',
      );

      final content3 = PlayableContent.fromChannel(
        id: 'ch2',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
    });
  });

  group('PlaybackError', () {
    test('network error is recoverable', () {
      final error = PlaybackError.network();

      expect(error.code, 'network_error');
      expect(error.isRecoverable, isTrue);
      expect(error.message, contains('connection'));
    });

    test('stream unavailable is recoverable', () {
      final error = PlaybackError.streamUnavailable();

      expect(error.code, 'stream_unavailable');
      expect(error.isRecoverable, isTrue);
    });

    test('unsupported format is not recoverable', () {
      final error = PlaybackError.unsupportedFormat();

      expect(error.code, 'unsupported_format');
      expect(error.isRecoverable, isFalse);
    });

    test('unauthorized is not recoverable', () {
      final error = PlaybackError.unauthorized();

      expect(error.code, 'unauthorized');
      expect(error.isRecoverable, isFalse);
    });

    test('unknown error includes details', () {
      final error = PlaybackError.unknown('Custom error message');

      expect(error.code, 'unknown');
      expect(error.message, contains('Custom error message'));
      expect(error.isRecoverable, isTrue);
    });
  });

  group('Channel to PlayableContent', () {
    test('channel can be converted to playable content', () {
      const channel = Channel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        logoUrl: 'http://example.com/logo.png',
        categoryId: 'news',
      );

      final content = PlayableContent.fromChannel(
        id: channel.id,
        name: channel.name,
        streamUrl: channel.streamUrl,
        logoUrl: channel.logoUrl,
      );

      expect(content.id, channel.id);
      expect(content.title, channel.name);
      expect(content.streamUrl, channel.streamUrl);
      expect(content.type, ContentType.liveChannel);
    });
  });
}
