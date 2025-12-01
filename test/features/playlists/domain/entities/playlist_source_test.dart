// Kylos IPTV Player - Playlist Source Entity Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';

void main() {
  group('PlaylistSource', () {
    test('should create PlaylistSource with required fields', () {
      const source = PlaylistSource(
        id: '1',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      expect(source.id, '1');
      expect(source.name, 'Test Playlist');
      expect(source.type, PlaylistType.m3uUrl);
      expect(source.status, PlaylistStatus.pending);
    });

    test('should create PlaylistSource with all fields', () {
      final now = DateTime.now();
      final url = PlaylistUrl.parse('http://example.com/playlist.m3u');
      final source = PlaylistSource(
        id: '1',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
        url: url,
        createdAt: now,
        updatedAt: now,
        status: PlaylistStatus.ready,
      );

      expect(source.url, url);
      expect(source.createdAt, now);
      expect(source.status, PlaylistStatus.ready);
      expect(source.isReady, true);
    });

    test('copyWith should create copy with updated fields', () {
      const original = PlaylistSource(
        id: '1',
        name: 'Original',
        type: PlaylistType.m3uUrl,
      );

      final copy = original.copyWith(name: 'Updated');

      expect(copy.id, '1');
      expect(copy.name, 'Updated');
      expect(copy.type, PlaylistType.m3uUrl);
    });

    test('equality should be based on id', () {
      const source1 = PlaylistSource(
        id: '1',
        name: 'Playlist 1',
        type: PlaylistType.m3uUrl,
      );

      const source2 = PlaylistSource(
        id: '1',
        name: 'Different Name',
        type: PlaylistType.m3uFile,
      );

      const source3 = PlaylistSource(
        id: '2',
        name: 'Playlist 1',
        type: PlaylistType.m3uUrl,
      );

      expect(source1, source2);
      expect(source1, isNot(source3));
    });

    group('factory constructors', () {
      test('m3uUrl creates correct source', () {
        final url = PlaylistUrl.parse('http://example.com/playlist.m3u');
        final source = PlaylistSource.m3uUrl(
          name: 'Test M3U',
          url: url,
        );

        expect(source.type, PlaylistType.m3uUrl);
        expect(source.url, url);
        expect(source.name, 'Test M3U');
        expect(source.id, isNotEmpty);
      });

      test('m3uFile creates correct source', () {
        final source = PlaylistSource.m3uFile(
          name: 'Test File',
          filePath: '/path/to/playlist.m3u',
        );

        expect(source.type, PlaylistType.m3uFile);
        expect(source.filePath, '/path/to/playlist.m3u');
        expect(source.name, 'Test File');
      });

      test('xtream creates correct source', () {
        final credentials = XtreamCredentials.create(
          serverUrl: 'http://example.com',
          username: 'user',
          password: 'pass',
        );
        final source = PlaylistSource.xtream(
          name: 'Test Xtream',
          credentials: credentials,
        );

        expect(source.type, PlaylistType.xtream);
        expect(source.xtreamCredentials, credentials);
        expect(source.name, 'Test Xtream');
      });
    });

    group('validation', () {
      test('validates m3uUrl source correctly', () {
        final url = PlaylistUrl.parse('http://example.com/playlist.m3u');
        final validSource = PlaylistSource.m3uUrl(name: 'Valid', url: url);
        expect(validSource.validate(), isA<PlaylistSourceValid>());

        const invalidSource = PlaylistSource(
          id: '1',
          name: 'Invalid',
          type: PlaylistType.m3uUrl,
          // Missing url
        );
        expect(invalidSource.validate(), isA<PlaylistSourceInvalid>());
      });

      test('validates empty name as invalid', () {
        final url = PlaylistUrl.parse('http://example.com/playlist.m3u');
        final source = PlaylistSource(
          id: '1',
          name: '',
          type: PlaylistType.m3uUrl,
          url: url,
        );
        final validation = source.validate();
        expect(validation, isA<PlaylistSourceInvalid>());
      });
    });
  });

  group('PlaylistType', () {
    test('should have three types', () {
      expect(PlaylistType.values.length, 3);
      expect(PlaylistType.values, contains(PlaylistType.m3uUrl));
      expect(PlaylistType.values, contains(PlaylistType.m3uFile));
      expect(PlaylistType.values, contains(PlaylistType.xtream));
    });
  });

  group('PlaylistStatus', () {
    test('should have five statuses', () {
      expect(PlaylistStatus.values.length, 5);
      expect(PlaylistStatus.values, contains(PlaylistStatus.pending));
      expect(PlaylistStatus.values, contains(PlaylistStatus.loading));
      expect(PlaylistStatus.values, contains(PlaylistStatus.ready));
      expect(PlaylistStatus.values, contains(PlaylistStatus.error));
      expect(PlaylistStatus.values, contains(PlaylistStatus.expired));
    });
  });
}
