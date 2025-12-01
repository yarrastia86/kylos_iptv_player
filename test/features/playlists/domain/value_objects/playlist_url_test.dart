// Kylos IPTV Player - Playlist URL Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';

void main() {
  group('PlaylistUrl', () {
    group('validate', () {
      test('should return valid for http URL', () {
        final result = PlaylistUrl.validate('http://example.com/playlist.m3u');
        expect(result, isA<PlaylistUrlValid>());
      });

      test('should return valid for https URL', () {
        final result =
            PlaylistUrl.validate('https://example.com/playlist.m3u');
        expect(result, isA<PlaylistUrlValid>());
      });

      test('should return invalid for empty string', () {
        final result = PlaylistUrl.validate('');
        expect(result, isA<PlaylistUrlInvalid>());
        expect((result as PlaylistUrlInvalid).reason,
            'URL cannot be empty');
      });

      test('should return invalid for URL without scheme', () {
        final result = PlaylistUrl.validate('example.com/playlist.m3u');
        expect(result, isA<PlaylistUrlInvalid>());
        expect((result as PlaylistUrlInvalid).reason,
            'URL must start with http:// or https://');
      });

      test('should return invalid for URL with invalid scheme', () {
        final result = PlaylistUrl.validate('ftp://example.com/playlist.m3u');
        expect(result, isA<PlaylistUrlInvalid>());
      });

      test('should return invalid for URL without host', () {
        final result = PlaylistUrl.validate('http://');
        expect(result, isA<PlaylistUrlInvalid>());
      });
    });

    group('tryParse', () {
      test('should return PlaylistUrl for valid URL', () {
        final url = PlaylistUrl.tryParse('https://example.com/playlist.m3u');
        expect(url, isNotNull);
        expect(url!.value, 'https://example.com/playlist.m3u');
        expect(url.protocol, 'https');
      });

      test('should return null for invalid URL', () {
        final url = PlaylistUrl.tryParse('invalid');
        expect(url, isNull);
      });

      test('should trim whitespace', () {
        final url =
            PlaylistUrl.tryParse('  https://example.com/playlist.m3u  ');
        expect(url, isNotNull);
        expect(url!.value, 'https://example.com/playlist.m3u');
      });
    });

    group('parse', () {
      test('should return PlaylistUrl for valid URL', () {
        final url = PlaylistUrl.parse('https://example.com/playlist.m3u');
        expect(url.value, 'https://example.com/playlist.m3u');
      });

      test('should throw FormatException for invalid URL', () {
        expect(
          () => PlaylistUrl.parse('invalid'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('properties', () {
      test('isSecure should return true for https', () {
        final url = PlaylistUrl.parse('https://example.com/playlist.m3u');
        expect(url.isSecure, isTrue);
      });

      test('isSecure should return false for http', () {
        final url = PlaylistUrl.parse('http://example.com/playlist.m3u');
        expect(url.isSecure, isFalse);
      });

      test('host should return the host', () {
        final url = PlaylistUrl.parse('https://example.com/playlist.m3u');
        expect(url.host, 'example.com');
      });

      test('port should return the port when specified', () {
        final url = PlaylistUrl.parse('http://example.com:8080/playlist.m3u');
        expect(url.port, 8080);
      });

      test('port should return null when using default port', () {
        final url = PlaylistUrl.parse('https://example.com/playlist.m3u');
        expect(url.port, isNull);
      });
    });

    group('equality', () {
      test('should be equal for same URL', () {
        final url1 = PlaylistUrl.parse('https://example.com/playlist.m3u');
        final url2 = PlaylistUrl.parse('https://example.com/playlist.m3u');
        expect(url1, equals(url2));
        expect(url1.hashCode, equals(url2.hashCode));
      });

      test('should not be equal for different URLs', () {
        final url1 = PlaylistUrl.parse('https://example.com/playlist1.m3u');
        final url2 = PlaylistUrl.parse('https://example.com/playlist2.m3u');
        expect(url1, isNot(equals(url2)));
      });
    });
  });
}
