// Kylos IPTV Player - Xtream Credentials Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';

void main() {
  group('XtreamCredentials', () {
    group('validate', () {
      test('should return valid for correct credentials', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
        expect(result, isA<XtreamCredentialsValid>());
      });

      test('should return invalid for empty username', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'http://example.com:8080',
          username: '',
          password: 'testpass',
        );
        expect(result, isA<XtreamCredentialsInvalid>());
        expect((result as XtreamCredentialsInvalid).usernameError,
            'Username cannot be empty');
      });

      test('should return invalid for short username', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'http://example.com:8080',
          username: 'a',
          password: 'testpass',
        );
        expect(result, isA<XtreamCredentialsInvalid>());
        expect((result as XtreamCredentialsInvalid).usernameError,
            'Username must be at least 2 characters');
      });

      test('should return invalid for empty password', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: '',
        );
        expect(result, isA<XtreamCredentialsInvalid>());
        expect((result as XtreamCredentialsInvalid).passwordError,
            'Password cannot be empty');
      });

      test('should return invalid for invalid server URL', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'invalid-url',
          username: 'testuser',
          password: 'testpass',
        );
        expect(result, isA<XtreamCredentialsInvalid>());
        expect(
            (result as XtreamCredentialsInvalid).serverUrlError, isNotNull);
      });

      test('should collect multiple errors', () {
        final result = XtreamCredentials.validate(
          serverUrl: 'invalid',
          username: '',
          password: '',
        );
        expect(result, isA<XtreamCredentialsInvalid>());
        final invalid = result as XtreamCredentialsInvalid;
        expect(invalid.hasErrors, isTrue);
        expect(invalid.allErrors.length, 3);
      });
    });

    group('tryCreate', () {
      test('should return credentials for valid input', () {
        final creds = XtreamCredentials.tryCreate(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
        expect(creds, isNotNull);
        expect(creds!.username, 'testuser');
        expect(creds.password, 'testpass');
      });

      test('should return null for invalid input', () {
        final creds = XtreamCredentials.tryCreate(
          serverUrl: 'invalid',
          username: '',
          password: '',
        );
        expect(creds, isNull);
      });

      test('should trim username', () {
        final creds = XtreamCredentials.tryCreate(
          serverUrl: 'http://example.com:8080',
          username: '  testuser  ',
          password: 'testpass',
        );
        expect(creds!.username, 'testuser');
      });
    });

    group('API URL builders', () {
      late XtreamCredentials creds;

      setUp(() {
        creds = XtreamCredentials.create(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
      });

      test('buildLiveStreamUrl should return correct URL', () {
        final url = creds.buildLiveStreamUrl('123', 'm3u8');
        expect(url,
            'http://example.com:8080/live/testuser/testpass/123.m3u8');
      });

      test('buildVodUrl should return correct URL', () {
        final url = creds.buildVodUrl('456', 'mp4');
        expect(url,
            'http://example.com:8080/movie/testuser/testpass/456.mp4');
      });

      test('buildSeriesUrl should return correct URL', () {
        final url = creds.buildSeriesUrl('789', 'mkv');
        expect(url,
            'http://example.com:8080/series/testuser/testpass/789.mkv');
      });

      test('buildApiUrl should return correct URL', () {
        final url = creds.buildApiUrl('get_live_streams');
        expect(url,
            'http://example.com:8080/player_api.php?username=testuser&password=testpass&action=get_live_streams');
      });
    });

    group('equality', () {
      test('should be equal for same credentials', () {
        final creds1 = XtreamCredentials.create(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
        final creds2 = XtreamCredentials.create(
          serverUrl: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
        expect(creds1, equals(creds2));
      });

      test('should not be equal for different credentials', () {
        final creds1 = XtreamCredentials.create(
          serverUrl: 'http://example.com:8080',
          username: 'testuser1',
          password: 'testpass',
        );
        final creds2 = XtreamCredentials.create(
          serverUrl: 'http://example.com:8080',
          username: 'testuser2',
          password: 'testpass',
        );
        expect(creds1, isNot(equals(creds2)));
      });
    });
  });
}
