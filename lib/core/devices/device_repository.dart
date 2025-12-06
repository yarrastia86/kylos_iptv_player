// Kylos IPTV Player - Device Repository
// Interface for device management operations.

import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';

/// Repository interface for device management.
abstract class DeviceRepository {
  /// Registers a new device for the user.
  ///
  /// Returns [DeviceRegistrationSuccess] if successful, or
  /// [DeviceRegistrationLimitExceeded] if the user has too many devices.
  Future<DeviceRegistrationResult> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
    required DevicePlatform platform,
    required DeviceFormFactor formFactor,
    String? model,
    String? osVersion,
    String? appVersion,
    required int maxDevices,
  });

  /// Gets a device by ID.
  Future<Device?> getDevice(String userId, String deviceId);

  /// Gets all devices for a user.
  Future<List<Device>> getDevices(String userId);

  /// Watches all devices for a user.
  Stream<List<Device>> watchDevices(String userId);

  /// Updates device information.
  Future<void> updateDevice(Device device);

  /// Updates the device's last active timestamp.
  Future<void> updateLastActive(String userId, String deviceId);

  /// Renames a device.
  Future<void> renameDevice(String userId, String deviceId, String newName);

  /// Marks a device as trusted.
  Future<void> setDeviceTrusted(String userId, String deviceId, bool trusted);

  /// Removes a device from the user's account.
  Future<void> removeDevice(String userId, String deviceId);

  /// Removes all devices for a user (for account reset).
  Future<void> removeAllDevices(String userId);

  /// Gets the count of registered devices.
  Future<int> getDeviceCount(String userId);

  /// Checks if a device is registered.
  Future<bool> isDeviceRegistered(String userId, String deviceId);
}

/// Repository interface for stream session management.
abstract class StreamSessionRepository {
  /// Starts a new streaming session.
  ///
  /// Returns [StreamStartSuccess] if successful, or
  /// [StreamLimitExceeded] if the user has too many active streams.
  Future<StreamStartResult> startSession({
    required String userId,
    required String deviceId,
    required String deviceName,
    required DevicePlatform devicePlatform,
    required int maxConcurrentStreams,
    String? contentId,
    String? contentTitle,
    String? contentType,
  });

  /// Updates session heartbeat (call every 30 seconds during playback).
  Future<void> heartbeat(String sessionId);

  /// Pauses a session (when app goes to background).
  Future<void> pauseSession(String sessionId);

  /// Resumes a paused session.
  Future<void> resumeSession(String sessionId);

  /// Ends a session normally.
  Future<void> endSession(String sessionId);

  /// Gets a session by ID.
  Future<StreamSession?> getSession(String sessionId);

  /// Gets all active sessions for a user.
  Future<List<StreamSession>> getActiveSessions(String userId);

  /// Watches active sessions for a user.
  Stream<List<StreamSession>> watchActiveSessions(String userId);

  /// Terminates a specific session (kick off device).
  Future<void> terminateSession(String sessionId);

  /// Terminates all sessions for a user.
  Future<void> terminateAllSessions(String userId);

  /// Terminates all sessions except the current one.
  Future<void> terminateOtherSessions(String userId, String currentSessionId);

  /// Cleans up expired/stale sessions.
  Future<void> cleanupStaleSessions(String userId);

  /// Gets count of active streams for a user.
  Future<int> getActiveStreamCount(String userId);
}
