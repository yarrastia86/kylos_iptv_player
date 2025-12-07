// Kylos IPTV Player - TV Pairing Providers
// Riverpod providers for TV QR code authentication.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/devices/device_providers.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/tv_pairing.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/tv_pairing_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/realtime/firebase_tv_pairing_service.dart';

// =============================================================================
// Service Provider
// =============================================================================

/// Provider for TV pairing repository.
final tvPairingRepositoryProvider = Provider<TvPairingRepository>((ref) {
  final database = FirebaseDatabase.instance;
  return FirebaseTvPairingService(database: database);
});

// =============================================================================
// TV Side (Display QR Code)
// =============================================================================

/// State for TV pairing screen.
class TvPairingState {
  const TvPairingState({
    this.session,
    this.isLoading = false,
    this.error,
    this.isPaired = false,
    this.pairedUserId,
  });

  final TvPairingSession? session;
  final bool isLoading;
  final String? error;
  final bool isPaired;
  final String? pairedUserId;

  bool get hasActiveSession =>
      session != null && !session!.isExpired && !isPaired;

  TvPairingState copyWith({
    TvPairingSession? session,
    bool? isLoading,
    String? error,
    bool? isPaired,
    String? pairedUserId,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return TvPairingState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isPaired: isPaired ?? this.isPaired,
      pairedUserId: pairedUserId ?? this.pairedUserId,
    );
  }
}

/// Controller for TV pairing (TV side - displays QR code).
class TvPairingController extends StateNotifier<TvPairingState> {
  TvPairingController({
    required this.ref,
    required this.pairingRepository,
    required this.deviceId,
    required this.deviceName,
  }) : super(const TvPairingState());

  final Ref ref;
  final TvPairingRepository pairingRepository;
  final String deviceId;
  final String deviceName;

  StreamSubscription<TvPairingSession?>? _sessionSubscription;
  Timer? _expiryTimer;

  /// Start a new pairing session.
  Future<void> startPairing() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSession: true);

    try {
      final session = await pairingRepository.createPairingSession(
        deviceId: deviceId,
        deviceName: deviceName,
      );

      state = state.copyWith(session: session, isLoading: false);

      // Watch for status updates
      _watchSession(session.sessionId);

      // Start expiry countdown
      _startExpiryTimer(session.expiresAt);
    } catch (e) {
      state = state.copyWith(
        error: 'Error al crear sesión de emparejamiento',
        isLoading: false,
      );
      debugPrint('TvPairingController: Error starting pairing: $e');
    }
  }

  void _watchSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription =
        pairingRepository.watchSession(sessionId).listen(_onSessionUpdate);
  }

  void _onSessionUpdate(TvPairingSession? session) {
    if (session == null) {
      // Session was deleted (completed or cancelled)
      return;
    }

    if (session.status == TvPairingStatus.completed) {
      _onPairingCompleted(session);
    } else if (session.status == TvPairingStatus.expired) {
      state = state.copyWith(
        error: 'La sesión de emparejamiento ha expirado',
        clearSession: true,
      );
    } else if (session.status == TvPairingStatus.cancelled) {
      state = state.copyWith(clearSession: true);
    } else {
      state = state.copyWith(session: session);
    }
  }

  void _onPairingCompleted(TvPairingSession session) {
    _sessionSubscription?.cancel();
    _expiryTimer?.cancel();

    state = state.copyWith(
      isPaired: true,
      pairedUserId: session.pairedUserId,
      clearSession: true,
    );

    // Sign in with the paired user's custom token
    // This would require a Cloud Function to generate a custom token
    // For now, we'll just mark as paired
    debugPrint(
      'TvPairingController: Paired with user ${session.pairedUserId}',
    );
  }

  void _startExpiryTimer(DateTime expiresAt) {
    _expiryTimer?.cancel();
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return;

    _expiryTimer = Timer(remaining, () {
      state = state.copyWith(
        error: 'La sesión de emparejamiento ha expirado',
        clearSession: true,
      );
    });
  }

  /// Refresh the pairing session (generate new QR code).
  Future<void> refreshSession() async {
    await cancel();
    await startPairing();
  }

  /// Cancel the current pairing session.
  Future<void> cancel() async {
    _sessionSubscription?.cancel();
    _expiryTimer?.cancel();

    if (state.session != null) {
      try {
        await pairingRepository.cancelSession(state.session!.sessionId);
      } catch (e) {
        debugPrint('TvPairingController: Error cancelling session: $e');
      }
    }

    state = state.copyWith(clearSession: true, clearError: true);
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }
}

/// Provider for TV pairing controller.
final tvPairingControllerProvider =
    StateNotifierProvider.autoDispose<TvPairingController, TvPairingState>(
        (ref) {
  final pairingRepo = ref.watch(tvPairingRepositoryProvider);
  final deviceDetails = ref.watch(currentDeviceDetailsProvider).valueOrNull;

  final controller = TvPairingController(
    ref: ref,
    pairingRepository: pairingRepo,
    deviceId: deviceDetails?.id ?? 'unknown-tv',
    deviceName: deviceDetails?.defaultName ?? 'TV',
  );

  ref.onDispose(controller.dispose);

  return controller;
});

// =============================================================================
// Mobile Side (Scan QR Code)
// =============================================================================

/// State for mobile pairing scanner.
class MobilePairingScannerState {
  const MobilePairingScannerState({
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
    this.pairedDeviceName,
  });

  final bool isLoading;
  final String? error;
  final bool isCompleted;
  final String? pairedDeviceName;

  MobilePairingScannerState copyWith({
    bool? isLoading,
    String? error,
    bool? isCompleted,
    String? pairedDeviceName,
    bool clearError = false,
  }) {
    return MobilePairingScannerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCompleted: isCompleted ?? this.isCompleted,
      pairedDeviceName: pairedDeviceName ?? this.pairedDeviceName,
    );
  }
}

/// Controller for mobile pairing scanner.
class MobilePairingScannerController
    extends StateNotifier<MobilePairingScannerState> {
  MobilePairingScannerController({
    required this.pairingRepository,
    required this.userId,
  }) : super(const MobilePairingScannerState());

  final TvPairingRepository pairingRepository;
  final String userId;

  /// Complete pairing from scanned QR code URL.
  Future<void> handleScannedUrl(String url) async {
    // Parse the URL: kylos://pair?session=<sessionId>
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'kylos' ||
        uri.host != 'pair' ||
        !uri.queryParameters.containsKey('session')) {
      state = state.copyWith(error: 'Código QR inválido');
      return;
    }

    final sessionId = uri.queryParameters['session']!;
    await _completePairing(sessionId);
  }

  /// Complete pairing with numeric code (manual entry).
  Future<void> handleNumericCode(String code) async {
    if (code.length != 6 || int.tryParse(code) == null) {
      state = state.copyWith(error: 'Código inválido (debe ser 6 dígitos)');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await pairingRepository.getSessionByCode(code);
      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Código no encontrado o expirado',
        );
        return;
      }

      await _completePairing(session.sessionId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar código',
      );
      debugPrint('MobilePairingScannerController: Error finding code: $e');
    }
  }

  Future<void> _completePairing(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await pairingRepository.getSession(sessionId);
      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sesión de emparejamiento no encontrada',
        );
        return;
      }

      if (!session.canBePaired) {
        state = state.copyWith(
          isLoading: false,
          error: 'La sesión de emparejamiento ya no es válida',
        );
        return;
      }

      await pairingRepository.completePairing(
        sessionId: sessionId,
        userId: userId,
      );

      state = state.copyWith(
        isLoading: false,
        isCompleted: true,
        pairedDeviceName: session.deviceName,
      );

      debugPrint(
        'MobilePairingScannerController: Paired TV ${session.deviceId}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al completar emparejamiento',
      );
      debugPrint('MobilePairingScannerController: Error completing pairing: $e');
    }
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for mobile pairing scanner controller.
final mobilePairingScannerProvider = StateNotifierProvider.autoDispose<
    MobilePairingScannerController, MobilePairingScannerState>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final pairingRepo = ref.watch(tvPairingRepositoryProvider);

  return MobilePairingScannerController(
    pairingRepository: pairingRepo,
    userId: user.uid,
  );
});
