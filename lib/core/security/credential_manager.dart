// Kylos IPTV Player - Credential Manager
// Manages secure storage and retrieval of IPTV provider credentials.
//
// This service handles the secure caching of sensitive playlist credentials
// on the device. Credentials stored here are encrypted at rest using
// platform-appropriate mechanisms (Android Keystore, iOS Keychain).

import 'dart:convert';
import 'package:kylos_iptv_player/core/security/secure_storage_service.dart';

/// Data class for cached playlist credentials.
///
/// Stores the minimum required authentication data for a playlist source.
/// Password is stored encrypted via SecureStorageService.
class CachedPlaylistCredentials {
  const CachedPlaylistCredentials({
    required this.playlistId,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.cachedAt,
  });

  /// Unique identifier for the playlist.
  final String playlistId;

  /// Server URL (not considered sensitive, but included for convenience).
  final String serverUrl;

  /// Username (mildly sensitive, stored encrypted anyway).
  final String username;

  /// Password (highly sensitive).
  final String password;

  /// When these credentials were cached.
  final DateTime? cachedAt;

  /// Serializes to JSON for storage.
  Map<String, dynamic> toJson() => {
        'playlistId': playlistId,
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'cachedAt': cachedAt?.toIso8601String(),
      };

  /// Deserializes from JSON.
  factory CachedPlaylistCredentials.fromJson(Map<String, dynamic> json) {
    return CachedPlaylistCredentials(
      playlistId: json['playlistId'] as String,
      serverUrl: json['serverUrl'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      cachedAt: json['cachedAt'] != null
          ? DateTime.tryParse(json['cachedAt'] as String)
          : null,
    );
  }
}

/// Manages the secure storage of playlist credentials.
///
/// Provides methods to cache, retrieve, and clear credentials for
/// individual playlists or all playlists at once.
class CredentialManager {
  CredentialManager({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  /// Caches credentials for a playlist.
  ///
  /// Overwrites any existing cached credentials for this playlist.
  Future<bool> cacheCredentials(CachedPlaylistCredentials credentials) async {
    final key =
        '${SecureStorageKeys.playlistCredentialsPrefix}${credentials.playlistId}';
    final json = jsonEncode(credentials.toJson());

    final result = await _secureStorage.write(key, json);
    return result.isSuccess;
  }

  /// Retrieves cached credentials for a playlist.
  ///
  /// Returns null if no credentials are cached or on error.
  Future<CachedPlaylistCredentials?> getCredentials(String playlistId) async {
    final key = '${SecureStorageKeys.playlistCredentialsPrefix}$playlistId';
    final result = await _secureStorage.read(key);

    final value = result.valueOrNull;
    if (value == null) return null;

    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return CachedPlaylistCredentials.fromJson(json);
    } catch (_) {
      // Corrupted data - remove it
      await _secureStorage.delete(key);
      return null;
    }
  }

  /// Checks if credentials are cached for a playlist.
  Future<bool> hasCredentials(String playlistId) async {
    final key = '${SecureStorageKeys.playlistCredentialsPrefix}$playlistId';
    final result = await _secureStorage.containsKey(key);
    return result.valueOrNull ?? false;
  }

  /// Clears cached credentials for a specific playlist.
  Future<bool> clearCredentials(String playlistId) async {
    final key = '${SecureStorageKeys.playlistCredentialsPrefix}$playlistId';
    final result = await _secureStorage.delete(key);
    return result.isSuccess;
  }

  /// Clears all cached playlist credentials.
  ///
  /// Typically called on logout or account reset.
  /// Does NOT clear auth tokens - use clearAllSecureData for that.
  Future<bool> clearAllCredentials() async {
    final keysResult = await _secureStorage.getAllKeys();
    final keys = keysResult.valueOrNull ?? [];

    var success = true;
    for (final key in keys) {
      if (key.startsWith(SecureStorageKeys.playlistCredentialsPrefix)) {
        final result = await _secureStorage.delete(key);
        if (result.isFailure) success = false;
      }
    }

    return success;
  }

  /// Clears ALL secure data including auth tokens.
  ///
  /// Use this for complete app reset or account deletion.
  /// After calling this, the user will need to re-authenticate.
  Future<bool> clearAllSecureData() async {
    final result = await _secureStorage.deleteAll();
    return result.isSuccess;
  }

  /// Lists all playlist IDs with cached credentials.
  ///
  /// Useful for debugging and migration.
  Future<List<String>> getCachedPlaylistIds() async {
    final keysResult = await _secureStorage.getAllKeys();
    final keys = keysResult.valueOrNull ?? [];

    return keys
        .where((k) => k.startsWith(SecureStorageKeys.playlistCredentialsPrefix))
        .map((k) =>
            k.substring(SecureStorageKeys.playlistCredentialsPrefix.length))
        .toList();
  }
}
