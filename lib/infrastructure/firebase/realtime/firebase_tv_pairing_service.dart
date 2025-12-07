// Kylos IPTV Player - Firebase TV Pairing Service
// Firebase Realtime Database implementation for TV pairing.

import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/tv_pairing.dart';
import 'package:kylos_iptv_player/core/handoff/domain/repositories/tv_pairing_repository.dart';
import 'package:uuid/uuid.dart';

/// Firebase Realtime Database implementation of [TvPairingRepository].
class FirebaseTvPairingService implements TvPairingRepository {
  FirebaseTvPairingService({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final _uuid = const Uuid();
  final _random = Random.secure();

  /// Default timeout for pairing sessions (5 minutes).
  static const _sessionTimeout = Duration(minutes: 5);

  /// Reference to pairing sessions collection.
  DatabaseReference get _sessionsRef => _database.ref('tv_pairing_sessions');

  /// Reference to code lookup index.
  DatabaseReference get _codesRef => _database.ref('tv_pairing_codes');

  @override
  Future<TvPairingSession> createPairingSession({
    required String deviceId,
    required String deviceName,
  }) async {
    final sessionId = _uuid.v4();
    final code = _generateCode();
    final now = DateTime.now();
    final expiresAt = now.add(_sessionTimeout);

    final session = TvPairingSession(
      sessionId: sessionId,
      code: code,
      deviceId: deviceId,
      deviceName: deviceName,
      createdAt: now,
      expiresAt: expiresAt,
      status: TvPairingStatus.pending,
    );

    try {
      // Save session
      await _sessionsRef.child(sessionId).set(session.toJson());

      // Create code lookup index
      await _codesRef.child(code).set(sessionId);

      // Set up auto-cleanup on disconnect
      await _sessionsRef.child(sessionId).onDisconnect().remove();
      await _codesRef.child(code).onDisconnect().remove();

      // Schedule automatic expiry
      _scheduleExpiry(sessionId, code, _sessionTimeout);

      debugPrint('TvPairingService: Created session $sessionId with code $code');

      return session;
    } catch (e) {
      debugPrint('TvPairingService: Error creating session: $e');
      rethrow;
    }
  }

  @override
  Future<TvPairingSession?> getSession(String sessionId) async {
    try {
      final snapshot = await _sessionsRef.child(sessionId).get();
      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>;
      return TvPairingSession.fromJson(data);
    } catch (e) {
      debugPrint('TvPairingService: Error getting session: $e');
      return null;
    }
  }

  @override
  Future<TvPairingSession?> getSessionByCode(String code) async {
    try {
      // Look up session ID from code index
      final codeSnapshot = await _codesRef.child(code).get();
      if (!codeSnapshot.exists) return null;

      final sessionId = codeSnapshot.value as String;
      return getSession(sessionId);
    } catch (e) {
      debugPrint('TvPairingService: Error getting session by code: $e');
      return null;
    }
  }

  @override
  Stream<TvPairingSession?> watchSession(String sessionId) {
    return _sessionsRef.child(sessionId).onValue.map((event) {
      if (!event.snapshot.exists) return null;

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return TvPairingSession.fromJson(data);
      } catch (e) {
        debugPrint('TvPairingService: Error parsing session: $e');
        return null;
      }
    });
  }

  @override
  Future<void> completePairing({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Pairing session not found');
      }

      if (!session.canBePaired) {
        throw Exception('Pairing session is no longer valid');
      }

      // Update session status
      await _sessionsRef.child(sessionId).update({
        'status': TvPairingStatus.completed.name,
        'pairedUserId': userId,
        'pairedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Remove code index
      await _codesRef.child(session.code).remove();

      debugPrint(
        'TvPairingService: Completed pairing for session $sessionId with user $userId',
      );
    } catch (e) {
      debugPrint('TvPairingService: Error completing pairing: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) return;

      // Update status
      await _sessionsRef.child(sessionId).update({
        'status': TvPairingStatus.cancelled.name,
      });

      // Remove code index
      await _codesRef.child(session.code).remove();

      // Remove session after a short delay
      await Future<void>.delayed(const Duration(seconds: 2));
      await _sessionsRef.child(sessionId).remove();

      debugPrint('TvPairingService: Cancelled session $sessionId');
    } catch (e) {
      debugPrint('TvPairingService: Error cancelling session: $e');
    }
  }

  @override
  Future<void> cleanupExpiredSessions() async {
    try {
      final snapshot = await _sessionsRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in data.entries) {
        final sessionData = entry.value as Map<dynamic, dynamic>;
        final expiresAt = sessionData['expiresAt'] as int;
        final status = sessionData['status'] as String;

        if (expiresAt < now ||
            status == TvPairingStatus.completed.name ||
            status == TvPairingStatus.cancelled.name ||
            status == TvPairingStatus.expired.name) {
          // Remove expired session
          final sessionId = entry.key as String;
          final code = sessionData['code'] as String?;

          await _sessionsRef.child(sessionId).remove();
          if (code != null) {
            await _codesRef.child(code).remove();
          }
        }
      }

      debugPrint('TvPairingService: Cleaned up expired sessions');
    } catch (e) {
      debugPrint('TvPairingService: Error cleaning up sessions: $e');
    }
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed
  }

  /// Generate a 6-digit numeric code.
  String _generateCode() {
    return (_random.nextInt(900000) + 100000).toString();
  }

  void _scheduleExpiry(String sessionId, String code, Duration timeout) {
    Timer(timeout, () async {
      try {
        final snapshot = await _sessionsRef.child(sessionId).get();
        if (!snapshot.exists) return;

        final data = snapshot.value as Map<dynamic, dynamic>;
        final status = data['status'] as String?;

        // Only expire if still pending
        if (status == TvPairingStatus.pending.name) {
          await _sessionsRef.child(sessionId).update({
            'status': TvPairingStatus.expired.name,
          });
          await _codesRef.child(code).remove();

          // Remove session after a short delay
          await Future<void>.delayed(const Duration(seconds: 5));
          await _sessionsRef.child(sessionId).remove();

          debugPrint('TvPairingService: Session $sessionId expired');
        }
      } catch (e) {
        debugPrint('TvPairingService: Error expiring session: $e');
      }
    });
  }
}
