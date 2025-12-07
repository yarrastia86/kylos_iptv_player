// Kylos IPTV Player - TV Pairing Repository Interface
// Manages TV pairing sessions for QR code authentication.

import 'package:kylos_iptv_player/core/handoff/domain/entities/tv_pairing.dart';

/// Repository for managing TV pairing sessions.
abstract class TvPairingRepository {
  /// Create a new pairing session for a TV device.
  ///
  /// Returns a session with QR code data and numeric code.
  Future<TvPairingSession> createPairingSession({
    required String deviceId,
    required String deviceName,
  });

  /// Get a pairing session by session ID.
  Future<TvPairingSession?> getSession(String sessionId);

  /// Get a pairing session by numeric code.
  Future<TvPairingSession?> getSessionByCode(String code);

  /// Watch for updates to a pairing session.
  Stream<TvPairingSession?> watchSession(String sessionId);

  /// Complete pairing by linking user to TV device.
  ///
  /// Called from mobile device after scanning QR code.
  Future<void> completePairing({
    required String sessionId,
    required String userId,
  });

  /// Cancel a pairing session.
  Future<void> cancelSession(String sessionId);

  /// Cleanup expired sessions.
  Future<void> cleanupExpiredSessions();

  /// Dispose resources.
  Future<void> dispose();
}
