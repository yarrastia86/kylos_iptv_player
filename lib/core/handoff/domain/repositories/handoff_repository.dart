// Kylos IPTV Player - Handoff Repository Interface
// Manages handoff requests between devices.

import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/handoff_request.dart';

/// Repository for managing playback handoff between devices.
abstract class HandoffRepository {
  /// Send a handoff request to another device.
  ///
  /// Returns the created request with a unique ID.
  Future<HandoffRequest> sendHandoffRequest({
    required String userId,
    required String fromDeviceId,
    required String fromDeviceName,
    required String toDeviceId,
    required String toDeviceName,
    required PlayableContent content,
    required Duration position,
  });

  /// Watch for incoming handoff requests to this device.
  ///
  /// Returns a stream that emits when a new request arrives.
  Stream<HandoffRequest?> watchIncomingRequests(
    String userId,
    String deviceId,
  );

  /// Get the current pending request for this device (if any).
  Future<HandoffRequest?> getPendingRequest(String userId, String deviceId);

  /// Accept an incoming handoff request.
  ///
  /// Updates the request status to accepted.
  Future<void> acceptHandoff(HandoffRequest request);

  /// Reject an incoming handoff request.
  ///
  /// Updates the request status to rejected.
  Future<void> rejectHandoff(HandoffRequest request);

  /// Cancel a sent handoff request.
  ///
  /// Updates the request status to cancelled.
  Future<void> cancelHandoff(HandoffRequest request);

  /// Mark a handoff as completed.
  ///
  /// Called when playback has successfully started on the target device.
  Future<void> completeHandoff(HandoffRequest request);

  /// Clear the handoff request (remove from database).
  ///
  /// Called after the request has been processed.
  Future<void> clearHandoffRequest(String userId, String deviceId);

  /// Watch for status updates on an outgoing request.
  Stream<HandoffRequest?> watchRequestStatus(String requestId);

  /// Dispose resources.
  Future<void> dispose();
}
