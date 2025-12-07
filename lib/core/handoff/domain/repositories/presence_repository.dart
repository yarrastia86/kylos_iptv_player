// Kylos IPTV Player - Presence Repository Interface
// Manages device presence for cross-device discovery.

import 'package:kylos_iptv_player/core/handoff/domain/entities/device_presence.dart';

/// Repository for managing device presence and discovery.
abstract class PresenceRepository {
  /// Advertise this device as online and available for handoff.
  ///
  /// Sets up automatic offline handling when the connection is lost.
  Future<void> goOnline(DevicePresence presence);

  /// Mark this device as offline.
  Future<void> goOffline(String userId, String deviceId);

  /// Update the current playback information for this device.
  ///
  /// Pass null to clear the current content (not playing).
  Future<void> updateCurrentContent(
    String userId,
    String deviceId,
    CurrentPlayback? content,
  );

  /// Update the FCM token for push notifications.
  Future<void> updateFcmToken(
    String userId,
    String deviceId,
    String fcmToken,
  );

  /// Send a heartbeat to maintain presence.
  ///
  /// Should be called periodically (e.g., every 30 seconds).
  Future<void> heartbeat(String userId, String deviceId);

  /// Watch all online devices for a user.
  ///
  /// Returns a stream that updates whenever devices come online/offline
  /// or their status changes.
  Stream<List<DevicePresence>> watchOnlineDevices(String userId);

  /// Get a snapshot of all online devices for a user.
  Future<List<DevicePresence>> getOnlineDevices(String userId);

  /// Get the presence of a specific device.
  Future<DevicePresence?> getDevicePresence(String userId, String deviceId);

  /// Watch a specific device's presence.
  Stream<DevicePresence?> watchDevicePresence(String userId, String deviceId);

  /// Cleanup stale presence entries (devices that haven't sent heartbeat).
  Future<void> cleanupStalePresence(String userId);

  /// Dispose resources and go offline.
  Future<void> dispose();
}
