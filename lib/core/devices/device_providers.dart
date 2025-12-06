// Kylos IPTV Player - Device Providers
// Riverpod providers for device management and stream sessions.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_info.dart';
import 'package:kylos_iptv_player/core/devices/device_repository.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firebase_providers.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/firestore_device_repository.dart';

// =============================================================================
// Service Providers
// =============================================================================

/// Provider for device info service.
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

/// Provider for device repository.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreDeviceRepository(firestore: firestore);
});

/// Provider for stream session repository.
final streamSessionRepositoryProvider = Provider<StreamSessionRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreStreamSessionRepository(firestore: firestore);
});

// =============================================================================
// Device Info Providers
// =============================================================================

/// Provider for current device details.
final currentDeviceDetailsProvider = FutureProvider<DeviceDetails>((ref) async {
  final service = ref.watch(deviceInfoServiceProvider);
  return service.getDeviceDetails();
});

/// Provider for current device ID.
final currentDeviceIdProvider = FutureProvider<String>((ref) async {
  final details = await ref.watch(currentDeviceDetailsProvider.future);
  return details.id;
});

// =============================================================================
// Stream Limits Providers
// =============================================================================

/// Provider for feature limits (includes stream and device limits).
final featureLimitsForDevicesProvider = Provider<FeatureLimits>((ref) {
  final entitlement = ref.watch(entitlementProvider).valueOrNull;
  if (entitlement == null) return FeatureLimits.free;
  return FeatureLimits.forTier(entitlement.currentTier);
});

/// Provider for max concurrent streams.
final maxConcurrentStreamsProvider = Provider<int>((ref) {
  return ref.watch(featureLimitsForDevicesProvider).maxConcurrentStreams;
});

/// Provider for max registered devices.
final maxRegisteredDevicesProvider = Provider<int>((ref) {
  return ref.watch(featureLimitsForDevicesProvider).maxRegisteredDevices;
});

// =============================================================================
// Device Management Providers
// =============================================================================

/// Provider for user's registered devices.
final userDevicesProvider = StreamProvider<List<Device>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.watch(deviceRepositoryProvider);
  return repo.watchDevices(user.uid);
});

/// Provider for device count.
final deviceCountProvider = Provider<int>((ref) {
  return ref.watch(userDevicesProvider).valueOrNull?.length ?? 0;
});

/// Provider for checking if device limit is reached.
final isDeviceLimitReachedProvider = Provider<bool>((ref) {
  final count = ref.watch(deviceCountProvider);
  final max = ref.watch(maxRegisteredDevicesProvider);
  return count >= max;
});

// =============================================================================
// Stream Session Providers
// =============================================================================

/// Provider for active stream sessions.
final activeSessionsProvider = StreamProvider<List<StreamSession>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.watch(streamSessionRepositoryProvider);
  return repo.watchActiveSessions(user.uid);
});

/// Provider for active stream count.
final activeStreamCountProvider = Provider<int>((ref) {
  return ref.watch(activeSessionsProvider).valueOrNull?.length ?? 0;
});

/// Provider for checking if stream limit is reached.
final isStreamLimitReachedProvider = Provider<bool>((ref) {
  final count = ref.watch(activeStreamCountProvider);
  final max = ref.watch(maxConcurrentStreamsProvider);
  return count >= max;
});

// =============================================================================
// Device Manager Notifier
// =============================================================================

/// State for device manager.
class DeviceManagerState {
  const DeviceManagerState({
    this.currentDevice,
    this.isRegistering = false,
    this.registrationResult,
    this.error,
  });

  final Device? currentDevice;
  final bool isRegistering;
  final DeviceRegistrationResult? registrationResult;
  final String? error;

  DeviceManagerState copyWith({
    Device? currentDevice,
    bool? isRegistering,
    DeviceRegistrationResult? registrationResult,
    String? error,
  }) {
    return DeviceManagerState(
      currentDevice: currentDevice ?? this.currentDevice,
      isRegistering: isRegistering ?? this.isRegistering,
      registrationResult: registrationResult ?? this.registrationResult,
      error: error,
    );
  }
}

/// Notifier for device management.
class DeviceManagerNotifier extends StateNotifier<DeviceManagerState> {
  DeviceManagerNotifier({
    required this.ref,
    required this.deviceRepository,
    required this.deviceInfoService,
  }) : super(const DeviceManagerState());

  final Ref ref;
  final DeviceRepository deviceRepository;
  final DeviceInfoService deviceInfoService;

  /// Registers the current device.
  Future<DeviceRegistrationResult> registerCurrentDevice({
    String? customName,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return const DeviceRegistrationError(message: 'User not authenticated');
    }

    state = state.copyWith(isRegistering: true, error: null);

    try {
      final details = await deviceInfoService.getDeviceDetails();
      final maxDevices = ref.read(maxRegisteredDevicesProvider);

      final result = await deviceRepository.registerDevice(
        userId: user.uid,
        deviceId: details.id,
        deviceName: customName ?? details.defaultName,
        platform: details.platform,
        formFactor: details.formFactor,
        model: details.model,
        osVersion: details.osVersion,
        appVersion: details.appVersion,
        maxDevices: maxDevices,
      );

      state = state.copyWith(
        isRegistering: false,
        registrationResult: result,
        currentDevice: result is DeviceRegistrationSuccess ? result.device : null,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.toString(),
      );
      return DeviceRegistrationError(message: e.toString());
    }
  }

  /// Renames a device.
  Future<void> renameDevice(String deviceId, String newName) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await deviceRepository.renameDevice(user.uid, deviceId, newName);
  }

  /// Removes a device.
  Future<void> removeDevice(String deviceId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await deviceRepository.removeDevice(user.uid, deviceId);
  }

  /// Updates last active for current device.
  Future<void> updateLastActive() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final deviceId = await deviceInfoService.getDeviceId();
      await deviceRepository.updateLastActive(user.uid, deviceId);
    } catch (e) {
      debugPrint('DeviceManager: Error updating last active: $e');
    }
  }
}

/// Provider for device manager.
final deviceManagerProvider =
    StateNotifierProvider<DeviceManagerNotifier, DeviceManagerState>((ref) {
  return DeviceManagerNotifier(
    ref: ref,
    deviceRepository: ref.watch(deviceRepositoryProvider),
    deviceInfoService: ref.watch(deviceInfoServiceProvider),
  );
});

// =============================================================================
// Stream Session Manager Notifier
// =============================================================================

/// State for stream session manager.
class StreamSessionManagerState {
  const StreamSessionManagerState({
    this.currentSession,
    this.isStarting = false,
    this.startResult,
    this.error,
  });

  final StreamSession? currentSession;
  final bool isStarting;
  final StreamStartResult? startResult;
  final String? error;

  StreamSessionManagerState copyWith({
    StreamSession? currentSession,
    bool? isStarting,
    StreamStartResult? startResult,
    String? error,
  }) {
    return StreamSessionManagerState(
      currentSession: currentSession ?? this.currentSession,
      isStarting: isStarting ?? this.isStarting,
      startResult: startResult ?? this.startResult,
      error: error,
    );
  }
}

/// Notifier for stream session management.
class StreamSessionManagerNotifier extends StateNotifier<StreamSessionManagerState> {
  StreamSessionManagerNotifier({
    required this.ref,
    required this.sessionRepository,
    required this.deviceInfoService,
  }) : super(const StreamSessionManagerState());

  final Ref ref;
  final StreamSessionRepository sessionRepository;
  final DeviceInfoService deviceInfoService;
  Timer? _heartbeatTimer;

  /// Starts a streaming session.
  Future<StreamStartResult> startStream({
    String? contentId,
    String? contentTitle,
    String? contentType,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return const StreamStartError(message: 'User not authenticated');
    }

    state = state.copyWith(isStarting: true, error: null);

    try {
      final details = await deviceInfoService.getDeviceDetails();
      final devices = ref.read(userDevicesProvider).valueOrNull ?? [];
      final currentDevice = devices.where((d) => d.id == details.id).firstOrNull;

      if (currentDevice == null) {
        state = state.copyWith(isStarting: false);
        return const StreamDeviceNotRegistered();
      }

      final maxStreams = ref.read(maxConcurrentStreamsProvider);

      final result = await sessionRepository.startSession(
        userId: user.uid,
        deviceId: details.id,
        deviceName: currentDevice.name,
        devicePlatform: details.platform,
        maxConcurrentStreams: maxStreams,
        contentId: contentId,
        contentTitle: contentTitle,
        contentType: contentType,
      );

      state = state.copyWith(
        isStarting: false,
        startResult: result,
        currentSession: result is StreamStartSuccess ? result.session : null,
      );

      // Start heartbeat timer
      if (result is StreamStartSuccess) {
        _startHeartbeat(result.session.id);
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        error: e.toString(),
      );
      return StreamStartError(message: e.toString());
    }
  }

  void _startHeartbeat(String sessionId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => sessionRepository.heartbeat(sessionId),
    );
  }

  /// Pauses the current session (when app goes to background).
  Future<void> pauseSession() async {
    final session = state.currentSession;
    if (session == null) return;

    _heartbeatTimer?.cancel();
    await sessionRepository.pauseSession(session.id);
    state = state.copyWith(
      currentSession: session.copyWith(status: StreamSessionStatus.paused),
    );
  }

  /// Resumes the current session.
  Future<void> resumeSession() async {
    final session = state.currentSession;
    if (session == null) return;

    await sessionRepository.resumeSession(session.id);
    _startHeartbeat(session.id);
    state = state.copyWith(
      currentSession: session.copyWith(status: StreamSessionStatus.active),
    );
  }

  /// Ends the current session.
  Future<void> endSession() async {
    final session = state.currentSession;
    if (session == null) return;

    _heartbeatTimer?.cancel();
    await sessionRepository.endSession(session.id);
    state = const StreamSessionManagerState();
  }

  /// Terminates a specific session (kick off device).
  Future<void> terminateSession(String sessionId) async {
    await sessionRepository.terminateSession(sessionId);
    if (state.currentSession?.id == sessionId) {
      _heartbeatTimer?.cancel();
      state = const StreamSessionManagerState();
    }
  }

  /// Terminates all other sessions.
  Future<void> terminateOtherSessions() async {
    final user = ref.read(currentUserProvider);
    final session = state.currentSession;
    if (user == null || session == null) return;

    await sessionRepository.terminateOtherSessions(user.uid, session.id);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

/// Provider for stream session manager.
final streamSessionManagerProvider = StateNotifierProvider<
    StreamSessionManagerNotifier, StreamSessionManagerState>((ref) {
  final notifier = StreamSessionManagerNotifier(
    ref: ref,
    sessionRepository: ref.watch(streamSessionRepositoryProvider),
    deviceInfoService: ref.watch(deviceInfoServiceProvider),
  );
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// =============================================================================
// Current Session Provider
// =============================================================================

/// Provider for current stream session.
final currentStreamSessionProvider = Provider<StreamSession?>((ref) {
  return ref.watch(streamSessionManagerProvider).currentSession;
});

/// Provider to check if currently streaming.
final isStreamingProvider = Provider<bool>((ref) {
  final session = ref.watch(currentStreamSessionProvider);
  return session?.isActive ?? false;
});
