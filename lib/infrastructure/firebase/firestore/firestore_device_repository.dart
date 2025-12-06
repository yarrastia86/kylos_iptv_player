// Kylos IPTV Player - Firestore Device Repository
// Firebase Firestore implementation for device management.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_repository.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';
import 'package:uuid/uuid.dart';

/// Firestore implementation of [DeviceRepository].
class FirestoreDeviceRepository implements DeviceRepository {
  FirestoreDeviceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _devicesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('devices');
  }

  @override
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
  }) async {
    try {
      // Check if device is already registered
      final existingDevice = await getDevice(userId, deviceId);
      if (existingDevice != null) {
        // Device already registered, update last active
        await updateLastActive(userId, deviceId);
        return DeviceRegistrationSuccess(
          device: existingDevice.copyWith(lastActiveAt: DateTime.now()),
        );
      }

      // Check device count
      final devices = await getDevices(userId);
      if (devices.length >= maxDevices) {
        return DeviceRegistrationLimitExceeded(
          maxDevices: maxDevices,
          currentCount: devices.length,
          existingDevices: devices,
        );
      }

      // Create new device
      final now = DateTime.now();
      final device = Device(
        id: deviceId,
        userId: userId,
        name: deviceName,
        platform: platform,
        formFactor: formFactor,
        model: model,
        osVersion: osVersion,
        appVersion: appVersion,
        createdAt: now,
        lastActiveAt: now,
        isCurrentDevice: true,
      );

      await _devicesCollection(userId).doc(deviceId).set(device.toJson());

      debugPrint('DeviceRepository: Registered device $deviceId for user $userId');

      return DeviceRegistrationSuccess(device: device);
    } catch (e) {
      debugPrint('DeviceRepository: Error registering device: $e');
      return DeviceRegistrationError(message: e.toString());
    }
  }

  @override
  Future<Device?> getDevice(String userId, String deviceId) async {
    try {
      final doc = await _devicesCollection(userId).doc(deviceId).get();
      if (!doc.exists) return null;
      return Device.fromFirestore(doc);
    } catch (e) {
      debugPrint('DeviceRepository: Error getting device: $e');
      return null;
    }
  }

  @override
  Future<List<Device>> getDevices(String userId) async {
    try {
      final snapshot = await _devicesCollection(userId)
          .orderBy('lastActiveAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Device.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('DeviceRepository: Error getting devices: $e');
      return [];
    }
  }

  @override
  Stream<List<Device>> watchDevices(String userId) {
    return _devicesCollection(userId)
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Device.fromFirestore(doc)).toList());
  }

  @override
  Future<void> updateDevice(Device device) async {
    try {
      await _devicesCollection(device.userId)
          .doc(device.id)
          .update(device.toJson());
    } catch (e) {
      debugPrint('DeviceRepository: Error updating device: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastActive(String userId, String deviceId) async {
    try {
      await _devicesCollection(userId).doc(deviceId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('DeviceRepository: Error updating last active: $e');
    }
  }

  @override
  Future<void> renameDevice(
    String userId,
    String deviceId,
    String newName,
  ) async {
    try {
      await _devicesCollection(userId).doc(deviceId).update({
        'name': newName,
      });
    } catch (e) {
      debugPrint('DeviceRepository: Error renaming device: $e');
      rethrow;
    }
  }

  @override
  Future<void> setDeviceTrusted(
    String userId,
    String deviceId,
    bool trusted,
  ) async {
    try {
      await _devicesCollection(userId).doc(deviceId).update({
        'isTrusted': trusted,
      });
    } catch (e) {
      debugPrint('DeviceRepository: Error setting device trusted: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeDevice(String userId, String deviceId) async {
    try {
      await _devicesCollection(userId).doc(deviceId).delete();
      debugPrint('DeviceRepository: Removed device $deviceId');
    } catch (e) {
      debugPrint('DeviceRepository: Error removing device: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeAllDevices(String userId) async {
    try {
      final snapshot = await _devicesCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('DeviceRepository: Removed all devices for user $userId');
    } catch (e) {
      debugPrint('DeviceRepository: Error removing all devices: $e');
      rethrow;
    }
  }

  @override
  Future<int> getDeviceCount(String userId) async {
    try {
      final snapshot = await _devicesCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('DeviceRepository: Error getting device count: $e');
      return 0;
    }
  }

  @override
  Future<bool> isDeviceRegistered(String userId, String deviceId) async {
    try {
      final doc = await _devicesCollection(userId).doc(deviceId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('DeviceRepository: Error checking device registration: $e');
      return false;
    }
  }
}

/// Firestore implementation of [StreamSessionRepository].
class FirestoreStreamSessionRepository implements StreamSessionRepository {
  FirestoreStreamSessionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('stream_sessions');

  @override
  Future<StreamStartResult> startSession({
    required String userId,
    required String deviceId,
    required String deviceName,
    required DevicePlatform devicePlatform,
    required int maxConcurrentStreams,
    String? contentId,
    String? contentTitle,
    String? contentType,
  }) async {
    try {
      // Clean up stale sessions first
      await cleanupStaleSessions(userId);

      // Get active sessions
      final activeSessions = await getActiveSessions(userId);

      // Check if this device already has an active session
      final existingSession = activeSessions
          .where((s) => s.deviceId == deviceId)
          .firstOrNull;

      if (existingSession != null) {
        // Update existing session with new content
        await _sessionsCollection.doc(existingSession.id).update({
          'contentId': contentId,
          'contentTitle': contentTitle,
          'contentType': contentType,
          'lastHeartbeatAt': FieldValue.serverTimestamp(),
          'status': StreamSessionStatus.active.name,
        });

        return StreamStartSuccess(
          session: existingSession.copyWith(
            contentId: contentId,
            contentTitle: contentTitle,
            contentType: contentType,
            lastHeartbeatAt: DateTime.now(),
            status: StreamSessionStatus.active,
          ),
        );
      }

      // Check concurrent stream limit (excluding this device)
      final otherActiveSessions =
          activeSessions.where((s) => s.deviceId != deviceId).toList();

      if (otherActiveSessions.length >= maxConcurrentStreams) {
        return StreamLimitExceeded(
          maxStreams: maxConcurrentStreams,
          activeSessions: otherActiveSessions,
        );
      }

      // Create new session
      final sessionId = _uuid.v4();
      final now = DateTime.now();

      final session = StreamSession(
        id: sessionId,
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
        devicePlatform: devicePlatform,
        startedAt: now,
        lastHeartbeatAt: now,
        status: StreamSessionStatus.active,
        contentId: contentId,
        contentTitle: contentTitle,
        contentType: contentType,
      );

      await _sessionsCollection.doc(sessionId).set(session.toJson());

      debugPrint('StreamSession: Started session $sessionId on device $deviceId');

      return StreamStartSuccess(session: session);
    } catch (e) {
      debugPrint('StreamSession: Error starting session: $e');
      return StreamStartError(message: e.toString());
    }
  }

  @override
  Future<void> heartbeat(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'lastHeartbeatAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('StreamSession: Error sending heartbeat: $e');
    }
  }

  @override
  Future<void> pauseSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': StreamSessionStatus.paused.name,
        'lastHeartbeatAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('StreamSession: Error pausing session: $e');
    }
  }

  @override
  Future<void> resumeSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': StreamSessionStatus.active.name,
        'lastHeartbeatAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('StreamSession: Error resuming session: $e');
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': StreamSessionStatus.ended.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('StreamSession: Ended session $sessionId');
    } catch (e) {
      debugPrint('StreamSession: Error ending session: $e');
    }
  }

  @override
  Future<StreamSession?> getSession(String sessionId) async {
    try {
      final doc = await _sessionsCollection.doc(sessionId).get();
      if (!doc.exists) return null;
      return StreamSession.fromFirestore(doc);
    } catch (e) {
      debugPrint('StreamSession: Error getting session: $e');
      return null;
    }
  }

  @override
  Future<List<StreamSession>> getActiveSessions(String userId) async {
    try {
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            StreamSessionStatus.active.name,
            StreamSessionStatus.paused.name,
          ])
          .orderBy('startedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StreamSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('StreamSession: Error getting active sessions: $e');
      return [];
    }
  }

  @override
  Stream<List<StreamSession>> watchActiveSessions(String userId) {
    return _sessionsCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          StreamSessionStatus.active.name,
          StreamSessionStatus.paused.name,
        ])
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StreamSession.fromFirestore(doc)).toList());
  }

  @override
  Future<void> terminateSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': StreamSessionStatus.terminated.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('StreamSession: Terminated session $sessionId');
    } catch (e) {
      debugPrint('StreamSession: Error terminating session: $e');
      rethrow;
    }
  }

  @override
  Future<void> terminateAllSessions(String userId) async {
    try {
      final sessions = await getActiveSessions(userId);
      final batch = _firestore.batch();

      for (final session in sessions) {
        batch.update(_sessionsCollection.doc(session.id), {
          'status': StreamSessionStatus.terminated.name,
          'endedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('StreamSession: Terminated all sessions for user $userId');
    } catch (e) {
      debugPrint('StreamSession: Error terminating all sessions: $e');
      rethrow;
    }
  }

  @override
  Future<void> terminateOtherSessions(
    String userId,
    String currentSessionId,
  ) async {
    try {
      final sessions = await getActiveSessions(userId);
      final batch = _firestore.batch();

      for (final session in sessions) {
        if (session.id != currentSessionId) {
          batch.update(_sessionsCollection.doc(session.id), {
            'status': StreamSessionStatus.terminated.name,
            'endedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('StreamSession: Terminated other sessions for user $userId');
    } catch (e) {
      debugPrint('StreamSession: Error terminating other sessions: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanupStaleSessions(String userId) async {
    try {
      // Sessions with no heartbeat for > 5 minutes are stale
      final staleThreshold =
          DateTime.now().subtract(const Duration(minutes: 5));

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            StreamSessionStatus.active.name,
            StreamSessionStatus.paused.name,
          ])
          .where('lastHeartbeatAt', isLessThan: Timestamp.fromDate(staleThreshold))
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': StreamSessionStatus.expired.name,
          'endedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('StreamSession: Cleaned up ${snapshot.docs.length} stale sessions');
    } catch (e) {
      debugPrint('StreamSession: Error cleaning up stale sessions: $e');
    }
  }

  @override
  Future<int> getActiveStreamCount(String userId) async {
    try {
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: StreamSessionStatus.active.name)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('StreamSession: Error getting active stream count: $e');
      return 0;
    }
  }
}
