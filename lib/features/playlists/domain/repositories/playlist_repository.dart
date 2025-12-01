// Kylos IPTV Player - Playlist Repository Interface
// Domain layer interface for playlist data operations.

import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';

/// Repository interface for playlist operations.
///
/// Defines the contract for playlist data access.
/// Implementations may use local storage, remote API, or both.
abstract class PlaylistRepository {
  /// Gets all saved playlist sources.
  Future<List<PlaylistSource>> getPlaylists();

  /// Gets a specific playlist by ID.
  Future<PlaylistSource?> getPlaylist(String id);

  /// Saves a new playlist source.
  Future<void> addPlaylist(PlaylistSource playlist);

  /// Updates an existing playlist.
  Future<void> updatePlaylist(PlaylistSource playlist);

  /// Removes a playlist by ID.
  Future<void> deletePlaylist(String id);

  /// Sets a playlist as the active/default playlist.
  Future<void> setActivePlaylist(String id);

  /// Gets the currently active playlist ID.
  Future<String?> getActivePlaylistId();
}
