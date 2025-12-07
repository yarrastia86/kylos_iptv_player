// Kylos IPTV Player - Firebase Presence Service
// Firebase Realtime Database implementation for device presence.

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/device_presence.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/presence_repository.dart';

/// Firebase Realtime Database implementation of [PresenceRepository].
///
/// Uses RTDB for low-latency presence updates and automatic offline handling.
class FirebasePresenceService implements PresenceRepository {
  FirebasePresenceService({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  Timer? _heartbeatTimer;
  String? _currentUserId;
  String? _currentDeviceId;

  /// Reference to the presence node for a user.
  DatabaseReference _userPresenceRef(String userId) =>
      _database.ref('presence/$userId');

  /// Reference to a specific device's presence.
  DatabaseReference _devicePresenceRef(String userId, String deviceId) =>
      _database.ref('presence/$userId/$deviceId');

  @override
  Future<void> goOnline(DevicePresence presence) async {
    try {
      final ref = _devicePresenceRef(presence.userId, presence.deviceId);

      // Set presence data
      await ref.set(presence.toJson());

      // Set up onDisconnect to automatically mark offline
      await ref.child('online').onDisconnect().set(false);
      await ref.child('lastSeen').onDisconnect().set(
            ServerValue.timestamp,
          );

      // Store current user/device for heartbeat
      _currentUserId = presence.userId;
      _currentDeviceId = presence.deviceId;

      // Start heartbeat timer
      _startHeartbeat();

      debugPrint(
        'PresenceService: Device ${presence.deviceId} is now online',
      );
    } catch (e) {
      debugPrint('PresenceService: Error going online: $e');
      rethrow;
    }
  }

  @override
  Future<void> goOffline(String userId, String deviceId) async {
    try {
      _stopHeartbeat();

      final ref = _devicePresenceRef(userId, deviceId);
      await ref.update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'currentContent': null,
      });

      _currentUserId = null;
      _currentDeviceId = null;

      debugPrint('PresenceService: Device $deviceId is now offline');
    } catch (e) {
      debugPrint('PresenceService: Error going offline: $e');
    }
  }

  @override
  Future<void> updateCurrentContent(
    String userId,
    String deviceId,
    CurrentPlayback? content,
  ) async {
    try {
      final ref = _devicePresenceRef(userId, deviceId);
      await ref.update({
        'currentContent': content?.toJson(),
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService: Error updating content: $e');
    }
  }

  @override
  Future<void> updateFcmToken(
    String userId,
    String deviceId,
    String fcmToken,
  ) async {
    try {
      final ref = _devicePresenceRef(userId, deviceId);
      await ref.update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      debugPrint('PresenceService: Error updating FCM token: $e');
    }
  }

  @override
  Future<void> heartbeat(String userId, String deviceId) async {
    try {
      final ref = _devicePresenceRef(userId, deviceId);
      await ref.update({
        'lastSeen': ServerValue.timestamp,
        'online': true,
      });
    } catch (e) {
      debugPrint('PresenceService: Heartbeat error: $e');
    }
  }

  @override
  Stream<List<DevicePresence>> watchOnlineDevices(String userId) {
    return _userPresenceRef(userId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <DevicePresence>[];

      final devices = <DevicePresence>[];
      for (final entry in data.entries) {
        try {
          final deviceId = entry.key as String;
          final deviceData = entry.value as Map<dynamic, dynamic>;
          final presence = DevicePresence.fromJson(deviceId, deviceData);

          // Only include devices that are online and recently active
          if (presence.isOnline && presence.isRecentlyActive) {
            devices.add(presence);
          }
        } catch (e) {
          debugPrint('PresenceService: Error parsing device: $e');
        }
      }

      // Sort by last seen (most recent first)
      devices.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

      return devices;
    });
  }

  @override
  Future<List<DevicePresence>> getOnlineDevices(String userId) async {
    try {
      final snapshot = await _userPresenceRef(userId).get();
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final devices = <DevicePresence>[];
      for (final entry in data.entries) {
        try {
          final deviceId = entry.key as String;
          final deviceData = entry.value as Map<dynamic, dynamic>;
          final presence = DevicePresence.fromJson(deviceId, deviceData);

          if (presence.isOnline && presence.isRecentlyActive) {
            devices.add(presence);
          }
        } catch (e) {
          debugPrint('PresenceService: Error parsing device: $e');
        }
      }

      return devices;
    } catch (e) {
      debugPrint('PresenceService: Error getting online devices: $e');
      return [];
    }
  }

  @override
  Future<DevicePresence?> getDevicePresence(
    String userId,
    String deviceId,
  ) async {
    try {
      final snapshot = await _devicePresenceRef(userId, deviceId).get();
      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>;
      return DevicePresence.fromJson(deviceId, data);
    } catch (e) {
      debugPrint('PresenceService: Error getting device presence: $e');
      return null;
    }
  }

  @override
  Stream<DevicePresence?> watchDevicePresence(
    String userId,
    String deviceId,
  ) {
    return _devicePresenceRef(userId, deviceId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return DevicePresence.fromJson(deviceId, data);
    });
  }

  @override
  Future<void> cleanupStalePresence(String userId) async {
    try {
      final devices = await getOnlineDevices(userId);
      final staleThreshold = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      for (final device in devices) {
        if (device.lastSeen.isBefore(staleThreshold)) {
          await _devicePresenceRef(userId, device.deviceId).update({
            'online': false,
          });
          debugPrint(
            'PresenceService: Marked stale device ${device.deviceId} as offline',
          );
        }
      }
    } catch (e) {
      debugPrint('PresenceService: Error cleaning stale presence: $e');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_currentUserId != null && _currentDeviceId != null) {
          heartbeat(_currentUserId!, _currentDeviceId!);
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  Future<void> dispose() async {
    if (_currentUserId != null && _currentDeviceId != null) {
      await goOffline(_currentUserId!, _currentDeviceId!);
    }
    _stopHeartbeat();
  }
}
