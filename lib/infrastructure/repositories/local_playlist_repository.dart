// Kylos IPTV Player - Local Playlist Repository
// Implementation of PlaylistRepository using local storage.

import 'dart:convert';

import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';

/// Local storage implementation of PlaylistRepository.
///
/// Persists playlist sources to device local storage using SharedPreferences.
class LocalPlaylistRepository implements PlaylistRepository {
  LocalPlaylistRepository({required this.localStorage});

  final LocalStorage localStorage;

  static const _playlistsKey = 'playlists';
  static const _activePlaylistKey = 'active_playlist_id';

  @override
  Future<List<PlaylistSource>> getPlaylists() async {
    final jsonString = localStorage.getString(_playlistsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => _playlistFromJson(json as Map<String, dynamic>))
          .whereType<PlaylistSource>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PlaylistSource?> getPlaylist(String id) async {
    final playlists = await getPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPlaylist(PlaylistSource playlist) async {
    final playlists = await getPlaylists();
    playlists.add(playlist);
    await _savePlaylists(playlists);
  }

  @override
  Future<void> updatePlaylist(PlaylistSource playlist) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlist;
      await _savePlaylists(playlists);
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await _savePlaylists(playlists);
  }

  @override
  Future<void> setActivePlaylist(String id) async {
    await localStorage.setString(_activePlaylistKey, id);
  }

  @override
  Future<String?> getActivePlaylistId() async {
    return localStorage.getString(_activePlaylistKey);
  }

  Future<void> _savePlaylists(List<PlaylistSource> playlists) async {
    final jsonList = playlists.map(_playlistToJson).toList();
    final jsonString = jsonEncode(jsonList);
    await localStorage.setString(_playlistsKey, jsonString);
  }

  Map<String, dynamic> _playlistToJson(PlaylistSource playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'type': playlist.type.index,
      'url': playlist.url?.value,
      'filePath': playlist.filePath,
      'xtreamCredentials': playlist.xtreamCredentials != null
          ? {
              'serverUrl': playlist.xtreamCredentials!.serverUrl.value,
              'username': playlist.xtreamCredentials!.username,
              'password': playlist.xtreamCredentials!.password,
            }
          : null,
      'epgUrl': playlist.epgUrl?.value,
      'status': playlist.status.index,
      'channelCount': playlist.channelCount,
      'vodCount': playlist.vodCount,
      'seriesCount': playlist.seriesCount,
      'lastRefresh': playlist.lastRefresh?.toIso8601String(),
      'createdAt': playlist.createdAt?.toIso8601String(),
      'updatedAt': playlist.updatedAt?.toIso8601String(),
      'errorMessage': playlist.errorMessage,
    };
  }

  PlaylistSource? _playlistFromJson(Map<String, dynamic> json) {
    try {
      final typeIndex = json['type'] as int;
      final statusIndex = json['status'] as int? ?? 0;

      PlaylistUrl? url;
      if (json['url'] != null) {
        url = PlaylistUrl.tryParse(json['url'] as String);
      }

      PlaylistUrl? epgUrl;
      if (json['epgUrl'] != null) {
        epgUrl = PlaylistUrl.tryParse(json['epgUrl'] as String);
      }

      XtreamCredentials? xtreamCredentials;
      if (json['xtreamCredentials'] != null) {
        final creds = json['xtreamCredentials'] as Map<String, dynamic>;
        xtreamCredentials = XtreamCredentials.tryCreate(
          serverUrl: creds['serverUrl'] as String,
          username: creds['username'] as String,
          password: creds['password'] as String,
        );
      }

      return PlaylistSource(
        id: json['id'] as String,
        name: json['name'] as String,
        type: PlaylistType.values[typeIndex],
        url: url,
        filePath: json['filePath'] as String?,
        xtreamCredentials: xtreamCredentials,
        epgUrl: epgUrl,
        status: PlaylistStatus.values[statusIndex],
        channelCount: json['channelCount'] as int?,
        vodCount: json['vodCount'] as int?,
        seriesCount: json['seriesCount'] as int?,
        lastRefresh: json['lastRefresh'] != null
            ? DateTime.tryParse(json['lastRefresh'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
