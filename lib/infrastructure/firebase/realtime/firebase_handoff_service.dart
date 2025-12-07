// Kylos IPTV Player - Firebase Handoff Service
// Firebase Realtime Database implementation for handoff messaging.

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/handoff_request.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/handoff_repository.dart';
import 'package:uuid/uuid.dart';

/// Firebase Realtime Database implementation of [HandoffRepository].
///
/// Uses RTDB for low-latency handoff messaging between devices.
class FirebaseHandoffService implements HandoffRepository {
  FirebaseHandoffService({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final _uuid = const Uuid();

  /// Default timeout for handoff requests.
  static const _requestTimeout = Duration(seconds: 30);

  /// Reference to handoff requests for a user.
  DatabaseReference _userHandoffRef(String userId) =>
      _database.ref('handoff_requests/$userId');

  /// Reference to a specific device's incoming request.
  DatabaseReference _deviceHandoffRef(String userId, String deviceId) =>
      _database.ref('handoff_requests/$userId/$deviceId');

  /// Reference to a specific request by ID.
  DatabaseReference _requestRef(String requestId) =>
      _database.ref('handoff_status/$requestId');

  @override
  Future<HandoffRequest> sendHandoffRequest({
    required String userId,
    required String fromDeviceId,
    required String fromDeviceName,
    required String toDeviceId,
    required String toDeviceName,
    required PlayableContent content,
    required Duration position,
  }) async {
    final requestId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(_requestTimeout);

    final request = HandoffRequest(
      id: requestId,
      fromDeviceId: fromDeviceId,
      fromDeviceName: fromDeviceName,
      toDeviceId: toDeviceId,
      toDeviceName: toDeviceName,
      userId: userId,
      content: content,
      position: position,
      timestamp: now,
      status: HandoffStatus.pending,
      expiresAt: expiresAt,
    );

    try {
      // Write to target device's incoming request node
      await _deviceHandoffRef(userId, toDeviceId).set(request.toJson());

      // Also write to request status node for tracking
      await _requestRef(requestId).set(request.toJson());

      // Set up auto-expiry
      await _deviceHandoffRef(userId, toDeviceId)
          .onDisconnect()
          .remove();

      debugPrint(
        'HandoffService: Sent handoff request $requestId to $toDeviceId',
      );

      // Schedule cleanup after timeout
      _scheduleExpiry(requestId, userId, toDeviceId, _requestTimeout);

      return request;
    } catch (e) {
      debugPrint('HandoffService: Error sending handoff request: $e');
      rethrow;
    }
  }

  @override
  Stream<HandoffRequest?> watchIncomingRequests(
    String userId,
    String deviceId,
  ) {
    return _deviceHandoffRef(userId, deviceId).onValue.map((event) {
      if (!event.snapshot.exists) return null;

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final request = HandoffRequest.fromJson(data);

        // Check if request is still valid
        if (request.isExpired || request.isFinished) {
          // Auto-cleanup expired/finished requests
          _deviceHandoffRef(userId, deviceId).remove();
          return null;
        }

        return request;
      } catch (e) {
        debugPrint('HandoffService: Error parsing incoming request: $e');
        return null;
      }
    });
  }

  @override
  Future<HandoffRequest?> getPendingRequest(
    String userId,
    String deviceId,
  ) async {
    try {
      final snapshot = await _deviceHandoffRef(userId, deviceId).get();
      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final request = HandoffRequest.fromJson(data);

      if (request.isExpired || request.isFinished) {
        await _deviceHandoffRef(userId, deviceId).remove();
        return null;
      }

      return request;
    } catch (e) {
      debugPrint('HandoffService: Error getting pending request: $e');
      return null;
    }
  }

  @override
  Future<void> acceptHandoff(HandoffRequest request) async {
    try {
      final now = DateTime.now();
      final updates = {
        'status': HandoffStatus.accepted.name,
        'respondedAt': now.millisecondsSinceEpoch,
      };

      // Update both locations
      await _deviceHandoffRef(request.userId, request.toDeviceId)
          .update(updates);
      await _requestRef(request.id).update(updates);

      debugPrint('HandoffService: Accepted handoff request ${request.id}');
    } catch (e) {
      debugPrint('HandoffService: Error accepting handoff: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectHandoff(HandoffRequest request) async {
    try {
      final now = DateTime.now();
      final updates = {
        'status': HandoffStatus.rejected.name,
        'respondedAt': now.millisecondsSinceEpoch,
      };

      // Update status then remove from device node
      await _requestRef(request.id).update(updates);
      await _deviceHandoffRef(request.userId, request.toDeviceId).remove();

      debugPrint('HandoffService: Rejected handoff request ${request.id}');
    } catch (e) {
      debugPrint('HandoffService: Error rejecting handoff: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelHandoff(HandoffRequest request) async {
    try {
      final updates = {
        'status': HandoffStatus.cancelled.name,
      };

      await _requestRef(request.id).update(updates);
      await _deviceHandoffRef(request.userId, request.toDeviceId).remove();

      debugPrint('HandoffService: Cancelled handoff request ${request.id}');
    } catch (e) {
      debugPrint('HandoffService: Error cancelling handoff: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeHandoff(HandoffRequest request) async {
    try {
      final now = DateTime.now();
      final updates = {
        'status': HandoffStatus.completed.name,
        'completedAt': now.millisecondsSinceEpoch,
      };

      await _requestRef(request.id).update(updates);
      await _deviceHandoffRef(request.userId, request.toDeviceId).remove();

      debugPrint('HandoffService: Completed handoff request ${request.id}');
    } catch (e) {
      debugPrint('HandoffService: Error completing handoff: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearHandoffRequest(String userId, String deviceId) async {
    try {
      await _deviceHandoffRef(userId, deviceId).remove();
    } catch (e) {
      debugPrint('HandoffService: Error clearing handoff request: $e');
    }
  }

  @override
  Stream<HandoffRequest?> watchRequestStatus(String requestId) {
    return _requestRef(requestId).onValue.map((event) {
      if (!event.snapshot.exists) return null;

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return HandoffRequest.fromJson(data);
      } catch (e) {
        debugPrint('HandoffService: Error parsing request status: $e');
        return null;
      }
    });
  }

  void _scheduleExpiry(
    String requestId,
    String userId,
    String deviceId,
    Duration timeout,
  ) {
    Timer(timeout, () async {
      try {
        final snapshot = await _requestRef(requestId).get();
        if (!snapshot.exists) return;

        final data = snapshot.value as Map<dynamic, dynamic>;
        final status = data['status'] as String?;

        // Only expire if still pending
        if (status == HandoffStatus.pending.name) {
          await _requestRef(requestId).update({
            'status': HandoffStatus.expired.name,
          });
          await _deviceHandoffRef(userId, deviceId).remove();

          debugPrint('HandoffService: Request $requestId expired');
        }
      } catch (e) {
        debugPrint('HandoffService: Error expiring request: $e');
      }
    });
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed
  }
}
