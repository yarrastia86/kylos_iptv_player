// Kylos IPTV Player - Handoff Providers
// Riverpod providers for cross-device handoff functionality.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/device_presence.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/handoff_request.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/handoff_repository.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/presence_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/realtime/firebase_handoff_service.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/realtime/firebase_presence_service.dart';

// =============================================================================
// Service Providers
// =============================================================================

/// Provider for Firebase Realtime Database instance.
final firebaseRtdbProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

/// Provider for presence repository.
final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  final database = ref.watch(firebaseRtdbProvider);
  return FirebasePresenceService(database: database);
});

/// Provider for handoff repository.
final handoffRepositoryProvider = Provider<HandoffRepository>((ref) {
  final database = ref.watch(firebaseRtdbProvider);
  return FirebaseHandoffService(database: database);
});

// =============================================================================
// Presence Providers
// =============================================================================

/// Watch online devices for the current user.
final onlineDevicesProvider = StreamProvider<List<DevicePresence>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  final presenceRepo = ref.watch(presenceRepositoryProvider);
  final currentDeviceId = await ref.watch(currentDeviceIdProvider.future);

  yield* presenceRepo.watchOnlineDevices(user.uid).map((devices) {
    // Mark current device
    return devices.map((d) {
      return d.copyWith(isCurrentDevice: d.deviceId == currentDeviceId);
    }).toList();
  });
});

/// Devices available for handoff (online, not current device).
final availableHandoffDevicesProvider = Provider<List<DevicePresence>>((ref) {
  final devices = ref.watch(onlineDevicesProvider).valueOrNull ?? [];
  return devices.where((d) => !d.isCurrentDevice && d.canReceiveHandoff).toList();
});

/// Whether there are devices available for handoff.
final hasAvailableDevicesProvider = Provider<bool>((ref) {
  return ref.watch(availableHandoffDevicesProvider).isNotEmpty;
});

// =============================================================================
// Handoff State
// =============================================================================

/// State for the handoff controller.
class HandoffState {
  const HandoffState({
    this.isLoading = false,
    this.pendingOutgoingRequest,
    this.incomingRequest,
    this.error,
    this.lastHandoffResult,
  });

  final bool isLoading;
  final HandoffRequest? pendingOutgoingRequest;
  final HandoffRequest? incomingRequest;
  final String? error;
  final HandoffResult? lastHandoffResult;

  bool get hasPendingOutgoing => pendingOutgoingRequest != null;
  bool get hasIncoming => incomingRequest != null;

  HandoffState copyWith({
    bool? isLoading,
    HandoffRequest? pendingOutgoingRequest,
    HandoffRequest? incomingRequest,
    String? error,
    HandoffResult? lastHandoffResult,
    bool clearPendingOutgoing = false,
    bool clearIncoming = false,
    bool clearError = false,
  }) {
    return HandoffState(
      isLoading: isLoading ?? this.isLoading,
      pendingOutgoingRequest: clearPendingOutgoing
          ? null
          : (pendingOutgoingRequest ?? this.pendingOutgoingRequest),
      incomingRequest:
          clearIncoming ? null : (incomingRequest ?? this.incomingRequest),
      error: clearError ? null : (error ?? this.error),
      lastHandoffResult: lastHandoffResult ?? this.lastHandoffResult,
    );
  }
}

/// Result of a handoff operation.
enum HandoffResult {
  accepted,
  rejected,
  expired,
  cancelled,
  error,
}

// =============================================================================
// Handoff Controller
// =============================================================================

/// Controller for managing handoff operations.
class HandoffController extends StateNotifier<HandoffState> {
  HandoffController({
    required this.ref,
    required this.presenceRepository,
    required this.handoffRepository,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
  }) : super(const HandoffState()) {
    _initialize();
  }

  final Ref ref;
  final PresenceRepository presenceRepository;
  final HandoffRepository handoffRepository;
  final String userId;
  final String deviceId;
  final String deviceName;

  StreamSubscription<HandoffRequest?>? _incomingSubscription;
  StreamSubscription<HandoffRequest?>? _outgoingSubscription;

  void _initialize() {
    // Watch for incoming handoff requests
    _incomingSubscription = handoffRepository
        .watchIncomingRequests(userId, deviceId)
        .listen(_onIncomingRequest);
  }

  void _onIncomingRequest(HandoffRequest? request) {
    if (request != null && request.isPending) {
      state = state.copyWith(incomingRequest: request);
    } else {
      state = state.copyWith(clearIncoming: true);
    }
  }

  /// Send playback to another device.
  Future<void> sendToDevice(DevicePresence targetDevice) async {
    final playbackState = ref.read(playbackNotifierProvider);
    if (!playbackState.hasContent) {
      state = state.copyWith(error: 'No content playing');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final request = await handoffRepository.sendHandoffRequest(
        userId: userId,
        fromDeviceId: deviceId,
        fromDeviceName: deviceName,
        toDeviceId: targetDevice.deviceId,
        toDeviceName: targetDevice.deviceName,
        content: playbackState.content!,
        position: playbackState.position ?? Duration.zero,
      );

      state = state.copyWith(
        pendingOutgoingRequest: request,
        isLoading: false,
      );

      // Watch for status updates
      _watchOutgoingRequest(request.id);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send handoff request',
        isLoading: false,
      );
      debugPrint('HandoffController: Error sending handoff: $e');
    }
  }

  void _watchOutgoingRequest(String requestId) {
    _outgoingSubscription?.cancel();
    _outgoingSubscription = handoffRepository
        .watchRequestStatus(requestId)
        .listen(_onOutgoingStatusChange);
  }

  void _onOutgoingStatusChange(HandoffRequest? request) {
    if (request == null) return;

    switch (request.status) {
      case HandoffStatus.accepted:
        _onHandoffAccepted(request);
        break;
      case HandoffStatus.rejected:
        state = state.copyWith(
          clearPendingOutgoing: true,
          lastHandoffResult: HandoffResult.rejected,
        );
        _outgoingSubscription?.cancel();
        break;
      case HandoffStatus.expired:
        state = state.copyWith(
          clearPendingOutgoing: true,
          lastHandoffResult: HandoffResult.expired,
        );
        _outgoingSubscription?.cancel();
        break;
      case HandoffStatus.completed:
        state = state.copyWith(
          clearPendingOutgoing: true,
          lastHandoffResult: HandoffResult.accepted,
        );
        _outgoingSubscription?.cancel();
        break;
      case HandoffStatus.cancelled:
      case HandoffStatus.pending:
        // No action needed
        break;
    }
  }

  void _onHandoffAccepted(HandoffRequest request) {
    // Stop local playback
    ref.read(playbackNotifierProvider.notifier).stop();

    state = state.copyWith(
      clearPendingOutgoing: true,
      lastHandoffResult: HandoffResult.accepted,
    );
  }

  /// Accept an incoming handoff request.
  Future<void> acceptIncoming() async {
    final request = state.incomingRequest;
    if (request == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Accept the request
      await handoffRepository.acceptHandoff(request);

      // Start playback at the specified position
      final playbackNotifier = ref.read(playbackNotifierProvider.notifier);
      await playbackNotifier.play(request.content);

      // Seek to position after a short delay to ensure player is ready
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await playbackNotifier.seek(request.position);

      // Mark as completed
      await handoffRepository.completeHandoff(request);

      state = state.copyWith(
        clearIncoming: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to accept handoff',
        isLoading: false,
      );
      debugPrint('HandoffController: Error accepting handoff: $e');
    }
  }

  /// Reject an incoming handoff request.
  Future<void> rejectIncoming() async {
    final request = state.incomingRequest;
    if (request == null) return;

    try {
      await handoffRepository.rejectHandoff(request);
      state = state.copyWith(clearIncoming: true);
    } catch (e) {
      debugPrint('HandoffController: Error rejecting handoff: $e');
    }
  }

  /// Cancel a pending outgoing request.
  Future<void> cancelOutgoing() async {
    final request = state.pendingOutgoingRequest;
    if (request == null) return;

    try {
      await handoffRepository.cancelHandoff(request);
      state = state.copyWith(clearPendingOutgoing: true);
      _outgoingSubscription?.cancel();
    } catch (e) {
      debugPrint('HandoffController: Error cancelling handoff: $e');
    }
  }

  /// Clear the last result.
  void clearResult() {
    state = state.copyWith(lastHandoffResult: null);
  }

  /// Clear error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    _outgoingSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for the handoff controller.
final handoffControllerProvider =
    StateNotifierProvider.autoDispose<HandoffController, HandoffState>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final presenceRepo = ref.watch(presenceRepositoryProvider);
  final handoffRepo = ref.watch(handoffRepositoryProvider);

  // Get device info synchronously from cache or use defaults
  final deviceDetails = ref.watch(currentDeviceDetailsProvider).valueOrNull;
  final deviceId = deviceDetails?.id ?? 'unknown';
  final deviceName = deviceDetails?.defaultName ?? 'Unknown Device';

  final controller = HandoffController(
    ref: ref,
    presenceRepository: presenceRepo,
    handoffRepository: handoffRepo,
    userId: user.uid,
    deviceId: deviceId,
    deviceName: deviceName,
  );

  ref.onDispose(controller.dispose);

  return controller;
});

// =============================================================================
// Presence Manager
// =============================================================================

/// Manager for maintaining this device's presence.
class PresenceManager extends StateNotifier<bool> {
  PresenceManager({
    required this.ref,
    required this.presenceRepository,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.formFactor,
    this.appVersion,
  }) : super(false) {
    _goOnline();
  }

  final Ref ref;
  final PresenceRepository presenceRepository;
  final String userId;
  final String deviceId;
  final String deviceName;
  final DevicePlatform platform;
  final DeviceFormFactor formFactor;
  final String? appVersion;

  StreamSubscription<void>? _playbackSubscription;

  Future<void> _goOnline() async {
    try {
      final presence = DevicePresence.create(
        deviceId: deviceId,
        userId: userId,
        deviceName: deviceName,
        platform: platform,
        formFactor: formFactor,
        appVersion: appVersion,
        isCurrentDevice: true,
      );

      await presenceRepository.goOnline(presence);
      state = true;

      // Watch playback state to update presence
      _watchPlayback();
    } catch (e) {
      debugPrint('PresenceManager: Error going online: $e');
    }
  }

  void _watchPlayback() {
    _playbackSubscription = ref
        .read(playbackNotifierProvider.notifier)
        .stream
        .listen((playbackState) {
      if (playbackState.hasContent && playbackState.isActive) {
        presenceRepository.updateCurrentContent(
          userId,
          deviceId,
          CurrentPlayback.fromPlaybackState(playbackState),
        );
      } else {
        presenceRepository.updateCurrentContent(userId, deviceId, null);
      }
    });
  }

  Future<void> goOffline() async {
    await presenceRepository.goOffline(userId, deviceId);
    state = false;
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    presenceRepository.dispose();
    super.dispose();
  }
}

/// Provider for the presence manager.
final presenceManagerProvider =
    StateNotifierProvider<PresenceManager, bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final presenceRepo = ref.watch(presenceRepositoryProvider);
  final deviceDetails = ref.watch(currentDeviceDetailsProvider).valueOrNull;

  if (deviceDetails == null) {
    throw Exception('Device details not available');
  }

  final manager = PresenceManager(
    ref: ref,
    presenceRepository: presenceRepo,
    userId: user.uid,
    deviceId: deviceDetails.id,
    deviceName: deviceDetails.defaultName,
    platform: deviceDetails.platform,
    formFactor: deviceDetails.formFactor,
    appVersion: deviceDetails.appVersion,
  );

  ref.onDispose(() {
    manager.goOffline();
    manager.dispose();
  });

  return manager;
});
