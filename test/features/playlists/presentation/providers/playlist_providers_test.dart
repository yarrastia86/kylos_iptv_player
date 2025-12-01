// Kylos IPTV Player - Playlist Providers Tests

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';

/// Mock implementation of PlaylistRepository for testing.
class MockPlaylistRepository implements PlaylistRepository {
  final List<PlaylistSource> _playlists = [];
  String? _activePlaylistId;
  bool shouldFail = false;

  @override
  Future<List<PlaylistSource>> getPlaylists() async {
    if (shouldFail) throw Exception('Failed to load playlists');
    return List.from(_playlists);
  }

  @override
  Future<PlaylistSource?> getPlaylist(String id) async {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPlaylist(PlaylistSource playlist) async {
    if (shouldFail) throw Exception('Failed to add playlist');
    _playlists.add(playlist);
  }

  @override
  Future<void> updatePlaylist(PlaylistSource playlist) async {
    if (shouldFail) throw Exception('Failed to update playlist');
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = playlist;
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    if (shouldFail) throw Exception('Failed to delete playlist');
    _playlists.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> setActivePlaylist(String id) async {
    _activePlaylistId = id;
  }

  @override
  Future<String?> getActivePlaylistId() async {
    return _activePlaylistId;
  }
}

void main() {
  group('PlaylistsNotifier', () {
    late MockPlaylistRepository repository;
    late PlaylistsNotifier notifier;

    setUp(() {
      repository = MockPlaylistRepository();
      notifier = PlaylistsNotifier(repository: repository);
    });

    test('initial state should be empty', () {
      expect(notifier.state.playlists, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadPlaylists should update state with playlists', () async {
      // Add a playlist to the mock repository
      final playlist = PlaylistSource.m3uUrl(
        name: 'Test',
        url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
      );
      await repository.addPlaylist(playlist);

      await notifier.loadPlaylists();

      expect(notifier.state.playlists.length, 1);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadPlaylists should set error on failure', () async {
      repository.shouldFail = true;

      await notifier.loadPlaylists();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
    });

    test('addPlaylist should add valid playlist', () async {
      final playlist = PlaylistSource.m3uUrl(
        name: 'Test',
        url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
      );

      final result = await notifier.addPlaylist(playlist);

      expect(result, isTrue);
      expect(notifier.state.playlists.length, 1);
      expect(notifier.state.error, isNull);
    });

    test('addPlaylist should reject invalid playlist', () async {
      final playlist = PlaylistSource(
        id: '1',
        name: '',
        type: PlaylistType.m3uUrl,
      );

      final result = await notifier.addPlaylist(playlist);

      expect(result, isFalse);
      expect(notifier.state.playlists, isEmpty);
      expect(notifier.state.error, isNotNull);
    });

    test('removePlaylist should remove playlist', () async {
      final playlist = PlaylistSource.m3uUrl(
        name: 'Test',
        url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
      );
      await notifier.addPlaylist(playlist);
      expect(notifier.state.playlists.length, 1);

      final result = await notifier.removePlaylist(playlist.id);

      expect(result, isTrue);
      expect(notifier.state.playlists, isEmpty);
    });

    test('updatePlaylist should update existing playlist', () async {
      final playlist = PlaylistSource.m3uUrl(
        name: 'Original',
        url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
      );
      await notifier.addPlaylist(playlist);

      final updated = playlist.copyWith(name: 'Updated');
      final result = await notifier.updatePlaylist(updated);

      expect(result, isTrue);
      expect(notifier.state.playlists.first.name, 'Updated');
    });

    test('clearError should clear error state', () async {
      // Trigger an error
      final invalidPlaylist = PlaylistSource(
        id: '1',
        name: '',
        type: PlaylistType.m3uUrl,
      );
      await notifier.addPlaylist(invalidPlaylist);
      expect(notifier.state.error, isNotNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });
  });

  group('PlaylistsState', () {
    test('hasPlaylists should return true when playlists exist', () {
      final state = PlaylistsState(
        playlists: [
          PlaylistSource.m3uUrl(
            name: 'Test',
            url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
          ),
        ],
      );

      expect(state.hasPlaylists, isTrue);
    });

    test('hasPlaylists should return false when empty', () {
      const state = PlaylistsState();
      expect(state.hasPlaylists, isFalse);
    });

    test('loading factory should create loading state', () {
      final state = PlaylistsState.loading();
      expect(state.isLoading, isTrue);
    });

    test('withError factory should create error state', () {
      final state = PlaylistsState.withError('Test error');
      expect(state.error, 'Test error');
    });
  });

  group('ActivePlaylistState', () {
    test('hasActivePlaylist should return true when playlist is set', () {
      final playlist = PlaylistSource.m3uUrl(
        name: 'Test',
        url: PlaylistUrl.parse('http://example.com/playlist.m3u'),
      );
      final state = ActivePlaylistState(playlist: playlist);

      expect(state.hasActivePlaylist, isTrue);
    });

    test('hasActivePlaylist should return false when no playlist', () {
      const state = ActivePlaylistState();
      expect(state.hasActivePlaylist, isFalse);
    });
  });
}
