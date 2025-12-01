// Kylos IPTV Player - Playback State Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';

void main() {
  group('PlaybackState', () {
    test('initial should create idle state', () {
      final state = PlaybackState.initial();

      expect(state.status, PlaybackStatus.idle);
      expect(state.content, isNull);
      expect(state.hasContent, isFalse);
      expect(state.isActive, isFalse);
    });

    test('loading should create loading state with content', () {
      final content = PlayableContent.fromChannel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState.loading(content);

      expect(state.status, PlaybackStatus.loading);
      expect(state.content, content);
      expect(state.hasContent, isTrue);
    });

    test('withError should create error state', () {
      final error = PlaybackError.network();
      final state = PlaybackState.withError(error);

      expect(state.status, PlaybackStatus.error);
      expect(state.error, error);
    });

    test('isActive should return true for playing and buffering', () {
      final content = PlayableContent.fromChannel(
        id: '1',
        name: 'Test',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final playingState = PlaybackState(
        status: PlaybackStatus.playing,
        content: content,
      );
      expect(playingState.isActive, isTrue);

      final bufferingState = PlaybackState(
        status: PlaybackStatus.buffering,
        content: content,
      );
      expect(bufferingState.isActive, isTrue);

      final pausedState = PlaybackState(
        status: PlaybackStatus.paused,
        content: content,
      );
      expect(pausedState.isActive, isFalse);
    });

    test('progress should calculate correctly', () {
      final state = PlaybackState(
        status: PlaybackStatus.playing,
        position: const Duration(minutes: 30),
        duration: const Duration(hours: 1),
      );

      expect(state.progress, 0.5);
    });

    test('progress should return 0 when no duration', () {
      final state = PlaybackState(
        status: PlaybackStatus.playing,
        position: const Duration(minutes: 30),
      );

      expect(state.progress, 0.0);
    });

    test('isLive should return true for live channel content', () {
      final liveContent = PlayableContent.fromChannel(
        id: '1',
        name: 'Live Channel',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final state = PlaybackState(
        status: PlaybackStatus.playing,
        content: liveContent,
      );

      expect(state.isLive, isTrue);
    });

    test('copyWith should preserve unset fields', () {
      final content = PlayableContent.fromChannel(
        id: '1',
        name: 'Test',
        streamUrl: 'http://example.com/stream.m3u8',
      );

      final original = PlaybackState(
        status: PlaybackStatus.playing,
        content: content,
        position: const Duration(minutes: 5),
        duration: const Duration(hours: 1),
      );

      final updated = original.copyWith(status: PlaybackStatus.paused);

      expect(updated.status, PlaybackStatus.paused);
      expect(updated.content, content);
      expect(updated.position, const Duration(minutes: 5));
      expect(updated.duration, const Duration(hours: 1));
    });
  });

  group('PlayableContent', () {
    test('fromChannel should create live channel content', () {
      final content = PlayableContent.fromChannel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream.m3u8',
        logoUrl: 'http://example.com/logo.png',
        categoryName: 'Sports',
      );

      expect(content.id, '1');
      expect(content.title, 'Test Channel');
      expect(content.type, ContentType.liveChannel);
      expect(content.isLive, isTrue);
      expect(content.logoUrl, 'http://example.com/logo.png');
      expect(content.categoryName, 'Sports');
    });

    test('equality should be based on id and type', () {
      final content1 = PlayableContent.fromChannel(
        id: '1',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      final content2 = PlayableContent.fromChannel(
        id: '1',
        name: 'Different Name',
        streamUrl: 'http://example.com/2.m3u8',
      );

      final content3 = PlayableContent.fromChannel(
        id: '2',
        name: 'Channel 1',
        streamUrl: 'http://example.com/1.m3u8',
      );

      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
    });
  });

  group('PlaybackError', () {
    test('network factory should create recoverable error', () {
      final error = PlaybackError.network();

      expect(error.code, 'network_error');
      expect(error.isRecoverable, isTrue);
    });

    test('streamUnavailable factory should create recoverable error', () {
      final error = PlaybackError.streamUnavailable();

      expect(error.code, 'stream_unavailable');
      expect(error.isRecoverable, isTrue);
    });

    test('unsupportedFormat factory should create non-recoverable error', () {
      final error = PlaybackError.unsupportedFormat();

      expect(error.code, 'unsupported_format');
      expect(error.isRecoverable, isFalse);
    });

    test('unauthorized factory should create non-recoverable error', () {
      final error = PlaybackError.unauthorized();

      expect(error.code, 'unauthorized');
      expect(error.isRecoverable, isFalse);
    });

    test('unknown factory should include details', () {
      final error = PlaybackError.unknown('Custom error message');

      expect(error.code, 'unknown');
      expect(error.message, contains('Custom error message'));
      expect(error.isRecoverable, isTrue);
    });
  });

  group('AudioTrack', () {
    test('should create audio track', () {
      const track = AudioTrack(
        id: '1',
        label: 'English',
        language: 'en',
        isDefault: true,
      );

      expect(track.id, '1');
      expect(track.label, 'English');
      expect(track.language, 'en');
      expect(track.isDefault, isTrue);
    });
  });

  group('SubtitleTrack', () {
    test('should create subtitle track', () {
      const track = SubtitleTrack(
        id: '1',
        label: 'Spanish',
        language: 'es',
        isDefault: false,
      );

      expect(track.id, '1');
      expect(track.label, 'Spanish');
      expect(track.language, 'es');
      expect(track.isDefault, isFalse);
    });
  });
}
