// Kylos IPTV Player - Secure Storage Service
// Platform-agnostic secure storage abstraction for sensitive data.
//
// Uses platform-appropriate secure storage:
// - iOS: Keychain Services
// - Android: EncryptedSharedPreferences (backed by Android Keystore)
//
// IMPORTANT: Only use this for genuinely sensitive data like:
// - IPTV provider credentials (passwords)
// - Authentication tokens
// - Encryption keys
//
// For non-sensitive preferences, use LocalStorage instead.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used for secure storage.
///
/// Centralizing keys prevents typos and makes auditing easier.
abstract class SecureStorageKeys {
  /// Prefix for all secure storage keys (aids in debugging/auditing).
  static const String _prefix = 'kylos_secure_';

  /// Cached Firebase auth token (if custom token handling needed).
  static const String authToken = '${_prefix}auth_token';

  /// Cached refresh token.
  static const String refreshToken = '${_prefix}refresh_token';

  /// Encryption key for local playlist credential caching.
  static const String playlistEncryptionKey = '${_prefix}playlist_enc_key';

  /// Prefix for individual playlist credentials.
  /// Full key format: kylos_secure_playlist_creds_{playlistId}
  static const String playlistCredentialsPrefix = '${_prefix}playlist_creds_';
}

/// Result type for secure storage operations.
sealed class SecureStorageResult<T> {
  const SecureStorageResult();
}

/// Operation succeeded with a value.
class SecureStorageSuccess<T> extends SecureStorageResult<T> {
  const SecureStorageSuccess(this.value);
  final T value;
}

/// Operation failed with an error.
class SecureStorageFailure<T> extends SecureStorageResult<T> {
  const SecureStorageFailure(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SecureStorageFailure: $error';
}

/// Secure storage service interface.
///
/// Abstraction over platform-specific secure storage mechanisms.
/// Implementations should handle encryption transparently.
abstract class SecureStorageService {
  /// Reads a secure value by key.
  ///
  /// Returns null if the key does not exist.
  /// Throws or returns failure on platform errors.
  Future<SecureStorageResult<String?>> read(String key);

  /// Writes a value securely.
  ///
  /// Overwrites any existing value for the key.
  Future<SecureStorageResult<void>> write(String key, String value);

  /// Deletes a secure value.
  ///
  /// No-op if the key does not exist.
  Future<SecureStorageResult<void>> delete(String key);

  /// Deletes all secure values.
  ///
  /// Use with caution - typically only on logout/account deletion.
  Future<SecureStorageResult<void>> deleteAll();

  /// Checks if a key exists in secure storage.
  Future<SecureStorageResult<bool>> containsKey(String key);

  /// Reads all keys (for debugging/migration - values not exposed).
  Future<SecureStorageResult<List<String>>> getAllKeys();
}

/// Implementation of SecureStorageService using flutter_secure_storage.
///
/// Configuration:
/// - iOS: Uses Keychain with kSecAttrAccessibleAfterFirstUnlock
/// - Android: Uses EncryptedSharedPreferences with AES-256-GCM
class FlutterSecureStorageService implements SecureStorageService {
  FlutterSecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? _createSecureStorage();

  final FlutterSecureStorage _storage;

  /// Creates a properly configured FlutterSecureStorage instance.
  static FlutterSecureStorage _createSecureStorage() {
    // Android options:
    // - encryptedSharedPreferences: true uses EncryptedSharedPreferences
    //   backed by Android Keystore (hardware-backed on supported devices)
    // - resetOnError: true clears storage if decryption fails (e.g., after
    //   app restore to new device without key backup)
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    );

    // iOS options:
    // - accessibility: afterFirstUnlock allows background access after
    //   device unlock, required for background sync
    // - accountName: groups all app keychain items together
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'com.kylos.iptvplayer.secure',
    );

    // macOS options for development/desktop
    const macOsOptions = MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'com.kylos.iptvplayer.secure',
    );

    return const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
      mOptions: macOsOptions,
    );
  }

  @override
  Future<SecureStorageResult<String?>> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return SecureStorageSuccess(value);
    } catch (e, st) {
      // Do NOT log the key name in production - could leak information
      return SecureStorageFailure(e, st);
    }
  }

  @override
  Future<SecureStorageResult<void>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return const SecureStorageSuccess(null);
    } catch (e, st) {
      return SecureStorageFailure(e, st);
    }
  }

  @override
  Future<SecureStorageResult<void>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return const SecureStorageSuccess(null);
    } catch (e, st) {
      return SecureStorageFailure(e, st);
    }
  }

  @override
  Future<SecureStorageResult<void>> deleteAll() async {
    try {
      await _storage.deleteAll();
      return const SecureStorageSuccess(null);
    } catch (e, st) {
      return SecureStorageFailure(e, st);
    }
  }

  @override
  Future<SecureStorageResult<bool>> containsKey(String key) async {
    try {
      final exists = await _storage.containsKey(key: key);
      return SecureStorageSuccess(exists);
    } catch (e, st) {
      return SecureStorageFailure(e, st);
    }
  }

  @override
  Future<SecureStorageResult<List<String>>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      return SecureStorageSuccess(all.keys.toList());
    } catch (e, st) {
      return SecureStorageFailure(e, st);
    }
  }
}

/// Extension methods for convenient result handling.
extension SecureStorageResultExtensions<T> on SecureStorageResult<T> {
  /// Returns the value if successful, null otherwise.
  T? get valueOrNull {
    final self = this;
    if (self is SecureStorageSuccess<T>) {
      return self.value;
    }
    return null;
  }

  /// Returns the value if successful, throws otherwise.
  T get valueOrThrow {
    final self = this;
    if (self is SecureStorageSuccess<T>) {
      return self.value;
    }
    final failure = self as SecureStorageFailure<T>;
    throw failure.error;
  }

  /// Returns true if the operation succeeded.
  bool get isSuccess => this is SecureStorageSuccess<T>;

  /// Returns true if the operation failed.
  bool get isFailure => this is SecureStorageFailure<T>;
}
