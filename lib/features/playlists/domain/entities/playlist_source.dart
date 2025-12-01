// Kylos IPTV Player - Playlist Source Entity
// Domain entity representing an IPTV playlist source.

import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_id.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';

/// Type of playlist source.
enum PlaylistType {
  /// M3U playlist from a URL.
  m3uUrl,

  /// M3U playlist from a local file.
  m3uFile,

  /// Xtream Codes API connection.
  xtream,
}

/// Status of a playlist source.
enum PlaylistStatus {
  /// Playlist has not been loaded yet.
  pending,

  /// Playlist is currently being loaded.
  loading,

  /// Playlist loaded successfully.
  ready,

  /// Playlist failed to load.
  error,

  /// Playlist credentials are expired or invalid.
  expired,
}

/// Result of playlist source validation.
sealed class PlaylistSourceValidation {
  const PlaylistSourceValidation();
}

/// Playlist source is valid.
class PlaylistSourceValid extends PlaylistSourceValidation {
  const PlaylistSourceValid();
}

/// Playlist source is invalid with errors.
class PlaylistSourceInvalid extends PlaylistSourceValidation {
  const PlaylistSourceInvalid(this.errors);
  final List<String> errors;
}

/// Represents an IPTV playlist source configuration.
///
/// A playlist source defines how to fetch content from an IPTV provider.
/// Supports multiple source types: M3U URLs, local files, and Xtream Codes API.
class PlaylistSource {
  const PlaylistSource({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.filePath,
    this.xtreamCredentials,
    this.epgUrl,
    this.status = PlaylistStatus.pending,
    this.channelCount,
    this.vodCount,
    this.seriesCount,
    this.lastRefresh,
    this.createdAt,
    this.updatedAt,
    this.errorMessage,
  });

  /// Unique identifier for this playlist source.
  final String id;

  /// User-friendly name for the playlist.
  final String name;

  /// Type of playlist source.
  final PlaylistType type;

  /// URL for M3U playlist sources.
  final PlaylistUrl? url;

  /// Local file path for M3U file sources.
  final String? filePath;

  /// Credentials for Xtream Codes API sources.
  final XtreamCredentials? xtreamCredentials;

  /// Optional EPG URL for program guide data.
  final PlaylistUrl? epgUrl;

  /// Current status of the playlist.
  final PlaylistStatus status;

  /// Number of live TV channels in this playlist.
  final int? channelCount;

  /// Number of VOD items in this playlist.
  final int? vodCount;

  /// Number of series in this playlist.
  final int? seriesCount;

  /// When the playlist was last refreshed from source.
  final DateTime? lastRefresh;

  /// When this source was added.
  final DateTime? createdAt;

  /// When this source was last updated.
  final DateTime? updatedAt;

  /// Error message if status is error.
  final String? errorMessage;

  /// Creates an M3U URL playlist source.
  factory PlaylistSource.m3uUrl({
    required String name,
    required PlaylistUrl url,
    PlaylistUrl? epgUrl,
    String? id,
  }) {
    return PlaylistSource(
      id: id ?? PlaylistId.generate().value,
      name: name,
      type: PlaylistType.m3uUrl,
      url: url,
      epgUrl: epgUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Creates an M3U file playlist source.
  factory PlaylistSource.m3uFile({
    required String name,
    required String filePath,
    PlaylistUrl? epgUrl,
    String? id,
  }) {
    return PlaylistSource(
      id: id ?? PlaylistId.generate().value,
      name: name,
      type: PlaylistType.m3uFile,
      filePath: filePath,
      epgUrl: epgUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Creates an Xtream Codes API playlist source.
  factory PlaylistSource.xtream({
    required String name,
    required XtreamCredentials credentials,
    String? id,
  }) {
    return PlaylistSource(
      id: id ?? PlaylistId.generate().value,
      name: name,
      type: PlaylistType.xtream,
      xtreamCredentials: credentials,
      createdAt: DateTime.now(),
    );
  }

  /// Validates the playlist source configuration.
  PlaylistSourceValidation validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Playlist name cannot be empty');
    }

    switch (type) {
      case PlaylistType.m3uUrl:
        if (url == null) {
          errors.add('M3U URL is required for URL-based playlists');
        }
      case PlaylistType.m3uFile:
        if (filePath == null || filePath!.trim().isEmpty) {
          errors.add('File path is required for file-based playlists');
        }
      case PlaylistType.xtream:
        if (xtreamCredentials == null) {
          errors.add('Credentials are required for Xtream Codes playlists');
        }
    }

    if (errors.isEmpty) {
      return const PlaylistSourceValid();
    }
    return PlaylistSourceInvalid(errors);
  }

  /// Whether this playlist is in a usable state.
  bool get isReady => status == PlaylistStatus.ready;

  /// Whether this playlist needs refresh (older than 24 hours).
  bool get needsRefresh {
    if (lastRefresh == null) return true;
    final age = DateTime.now().difference(lastRefresh!);
    return age.inHours >= 24;
  }

  /// Total content count across all categories.
  int get totalContentCount =>
      (channelCount ?? 0) + (vodCount ?? 0) + (seriesCount ?? 0);

  /// Creates a copy with the given fields replaced.
  PlaylistSource copyWith({
    String? id,
    String? name,
    PlaylistType? type,
    PlaylistUrl? url,
    String? filePath,
    XtreamCredentials? xtreamCredentials,
    PlaylistUrl? epgUrl,
    PlaylistStatus? status,
    int? channelCount,
    int? vodCount,
    int? seriesCount,
    DateTime? lastRefresh,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return PlaylistSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      xtreamCredentials: xtreamCredentials ?? this.xtreamCredentials,
      epgUrl: epgUrl ?? this.epgUrl,
      status: status ?? this.status,
      channelCount: channelCount ?? this.channelCount,
      vodCount: vodCount ?? this.vodCount,
      seriesCount: seriesCount ?? this.seriesCount,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistSource &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlaylistSource($id, $name, $type)';
}
