// Kylos IPTV Player - Playlist DTO
// Data transfer object for Firestore playlist serialization.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';

/// Data transfer object for PlaylistSource to/from Firestore.
///
/// Handles serialization/deserialization between domain entities
/// and Firestore document format.
class PlaylistDto {
  const PlaylistDto({
    required this.id,
    required this.name,
    required this.type,
    this.m3uUrl,
    this.m3uFileRef,
    this.xtream,
    this.epgUrl,
    this.status,
    this.channelCount,
    this.vodCount,
    this.seriesCount,
    this.lastRefreshAt,
    this.lastRefreshStatus,
    this.createdAt,
    this.updatedAt,
    this.errorMessage,
    this.autoRefresh,
    this.isActive = false,
    this.isPinned = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String type;
  final String? m3uUrl;
  final String? m3uFileRef;
  final XtreamDto? xtream;
  final String? epgUrl;
  final String? status;
  final int? channelCount;
  final int? vodCount;
  final int? seriesCount;
  final DateTime? lastRefreshAt;
  final String? lastRefreshStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;
  final AutoRefreshDto? autoRefresh;
  final bool isActive;
  final bool isPinned;
  final int sortOrder;

  /// Creates a DTO from a domain entity.
  factory PlaylistDto.fromDomain(PlaylistSource source) {
    return PlaylistDto(
      id: source.id,
      name: source.name,
      type: source.type.name,
      m3uUrl: source.url?.value,
      m3uFileRef: source.filePath,
      xtream: source.xtreamCredentials != null
          ? XtreamDto.fromDomain(source.xtreamCredentials!)
          : null,
      epgUrl: source.epgUrl?.value,
      status: source.status.name,
      channelCount: source.channelCount,
      vodCount: source.vodCount,
      seriesCount: source.seriesCount,
      lastRefreshAt: source.lastRefresh,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt ?? DateTime.now(),
      errorMessage: source.errorMessage,
    );
  }

  /// Creates a DTO from Firestore JSON.
  factory PlaylistDto.fromJson(Map<String, dynamic> json) {
    return PlaylistDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      m3uUrl: json['m3uUrl'] as String?,
      m3uFileRef: json['m3uFileRef'] as String?,
      xtream: json['xtream'] != null
          ? XtreamDto.fromJson(json['xtream'] as Map<String, dynamic>)
          : null,
      epgUrl: json['epgUrl'] as String?,
      status: json['status'] as String?,
      channelCount: json['metadata']?['channelCount'] as int?,
      vodCount: json['metadata']?['vodCount'] as int?,
      seriesCount: json['metadata']?['seriesCount'] as int?,
      lastRefreshAt: _parseTimestamp(json['lastRefreshAt']),
      lastRefreshStatus: json['lastRefreshStatus'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      errorMessage: json['errorMessage'] as String?,
      autoRefresh: json['autoRefresh'] != null
          ? AutoRefreshDto.fromJson(json['autoRefresh'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Converts to Firestore JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (m3uUrl != null) 'm3uUrl': m3uUrl,
      if (m3uFileRef != null) 'm3uFileRef': m3uFileRef,
      if (xtream != null) 'xtream': xtream!.toJson(),
      if (epgUrl != null) 'epgUrl': epgUrl,
      if (status != null) 'status': status,
      'metadata': {
        if (channelCount != null) 'channelCount': channelCount,
        if (vodCount != null) 'vodCount': vodCount,
        if (seriesCount != null) 'seriesCount': seriesCount,
      },
      if (lastRefreshAt != null)
        'lastRefreshAt': Timestamp.fromDate(lastRefreshAt!),
      if (lastRefreshStatus != null) 'lastRefreshStatus': lastRefreshStatus,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (autoRefresh != null) 'autoRefresh': autoRefresh!.toJson(),
      'isActive': isActive,
      'isPinned': isPinned,
      'sortOrder': sortOrder,
    };
  }

  /// Converts to domain entity.
  PlaylistSource toDomain() {
    return PlaylistSource(
      id: id,
      name: name,
      type: _parsePlaylistType(type),
      url: m3uUrl != null ? PlaylistUrl.tryParse(m3uUrl!) : null,
      filePath: m3uFileRef,
      xtreamCredentials: xtream?.toDomain(),
      epgUrl: epgUrl != null ? PlaylistUrl.tryParse(epgUrl!) : null,
      status: _parsePlaylistStatus(status),
      channelCount: channelCount,
      vodCount: vodCount,
      seriesCount: seriesCount,
      lastRefresh: lastRefreshAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      errorMessage: errorMessage,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static PlaylistType _parsePlaylistType(String value) {
    return PlaylistType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PlaylistType.m3uUrl,
    );
  }

  static PlaylistStatus _parsePlaylistStatus(String? value) {
    if (value == null) return PlaylistStatus.pending;
    return PlaylistStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PlaylistStatus.pending,
    );
  }
}

/// DTO for Xtream credentials.
class XtreamDto {
  const XtreamDto({
    required this.serverUrl,
    required this.username,
    required this.encryptedPassword,
  });

  final String serverUrl;
  final String username;

  /// Password is stored encrypted in Firestore.
  /// For this implementation, we store it as-is but in production
  /// should use Cloud Functions for encryption.
  final String encryptedPassword;

  factory XtreamDto.fromDomain(XtreamCredentials credentials) {
    return XtreamDto(
      serverUrl: credentials.serverUrl.value,
      username: credentials.username,
      // In production, encrypt this via Cloud Function
      encryptedPassword: credentials.password,
    );
  }

  factory XtreamDto.fromJson(Map<String, dynamic> json) {
    return XtreamDto(
      serverUrl: json['serverUrl'] as String,
      username: json['username'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'encryptedPassword': encryptedPassword,
    };
  }

  XtreamCredentials? toDomain() {
    // In production, decrypt password via Cloud Function
    return XtreamCredentials.tryCreate(
      serverUrl: serverUrl,
      username: username,
      password: encryptedPassword,
    );
  }
}

/// DTO for auto-refresh settings.
class AutoRefreshDto {
  const AutoRefreshDto({
    this.enabled = true,
    this.intervalHours = 24,
    this.onAppStart = true,
  });

  final bool enabled;
  final int intervalHours;
  final bool onAppStart;

  factory AutoRefreshDto.fromJson(Map<String, dynamic> json) {
    return AutoRefreshDto(
      enabled: json['enabled'] as bool? ?? true,
      intervalHours: json['intervalHours'] as int? ?? 24,
      onAppStart: json['onAppStart'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intervalHours': intervalHours,
      'onAppStart': onAppStart,
    };
  }
}
