// Kylos IPTV Player - Firestore Entitlement Repository
// Implementation of EntitlementRepository using Cloud Firestore.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';

/// Firestore implementation of EntitlementRepository.
///
/// Entitlements are read-only from the client - all modifications
/// happen via Cloud Functions after purchase verification.
class FirestoreEntitlementRepository implements EntitlementRepository {
  FirestoreEntitlementRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Collection path: /entitlements/{userId}
  DocumentReference<Map<String, dynamic>> _entitlementDoc(String userId) =>
      _firestore.collection('entitlements').doc(userId);

  /// Sub-collection path: /entitlements/{userId}/purchases
  CollectionReference<Map<String, dynamic>> _purchasesCollection(
          String userId) =>
      _entitlementDoc(userId).collection('purchases');

  /// App config document for feature limits
  DocumentReference<Map<String, dynamic>> get _limitsDoc =>
      _firestore.collection('app_config').doc('limits');

  @override
  Future<Entitlement?> getEntitlement(String userId) async {
    try {
      final doc = await _entitlementDoc(userId).get();
      if (!doc.exists) {
        // Return free tier entitlement if no document exists
        return Entitlement.free(userId);
      }
      return _documentToEntitlement(doc);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting entitlement: ${e.message}');
      }
      // Return free tier on error - graceful degradation
      return Entitlement.free(userId);
    }
  }

  @override
  Stream<Entitlement?> watchEntitlement(String userId) {
    return _entitlementDoc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return Entitlement.free(userId);
          }
          return _documentToEntitlement(doc);
        })
        .handleError((e) {
          if (kDebugMode) {
            print('Firestore stream error: $e');
          }
          return Entitlement.free(userId);
        });
  }

  @override
  Future<List<PurchaseRecord>> getPurchaseHistory(String userId) async {
    try {
      final snapshot = await _purchasesCollection(userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _documentToPurchase(doc))
          .whereType<PurchaseRecord>()
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting purchase history: ${e.message}');
      }
      return [];
    }
  }

  @override
  Future<FeatureLimits> getFeatureLimits(String userId) async {
    try {
      // First get the user's tier
      final entitlement = await getEntitlement(userId);
      final tier = entitlement?.currentTier ?? SubscriptionTier.free;

      // Try to get limits from Remote Config / Firestore
      final limitsDoc = await _limitsDoc.get();
      if (!limitsDoc.exists) {
        return FeatureLimits.forTier(tier);
      }

      final data = limitsDoc.data()!;
      final tierKey = tier == SubscriptionTier.pro ? 'pro' : 'free';
      final tierLimits = data[tierKey] as Map<String, dynamic>?;

      if (tierLimits == null) {
        return FeatureLimits.forTier(tier);
      }

      final defaults = FeatureLimits.forTier(tier);
      return FeatureLimits(
        maxProfiles: tierLimits['maxProfiles'] as int? ?? defaults.maxProfiles,
        maxPlaylists: tierLimits['maxPlaylists'] as int? ?? defaults.maxPlaylists,
        maxFavorites: tierLimits['maxFavorites'] as int? ?? defaults.maxFavorites,
        epgDaysAvailable: tierLimits['epgDaysAvailable'] as int? ?? defaults.epgDaysAvailable,
        cloudSyncEnabled: tierLimits['cloudSyncEnabled'] as bool? ?? defaults.cloudSyncEnabled,
        maxConcurrentStreams: tierLimits['maxConcurrentStreams'] as int? ?? defaults.maxConcurrentStreams,
        maxRegisteredDevices: tierLimits['maxRegisteredDevices'] as int? ?? defaults.maxRegisteredDevices,
        allowDownloads: tierLimits['allowDownloads'] as bool? ?? defaults.allowDownloads,
        maxDownloads: tierLimits['maxDownloads'] as int? ?? defaults.maxDownloads,
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting feature limits: ${e.message}');
      }
      return FeatureLimits.free;
    }
  }

  @override
  Future<Entitlement?> refreshEntitlement(String userId) async {
    // Force a fresh read from the server, bypassing cache
    try {
      final doc = await _entitlementDoc(userId).get(
        const GetOptions(source: Source.server),
      );
      if (!doc.exists) {
        return Entitlement.free(userId);
      }
      return _documentToEntitlement(doc);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error refreshing entitlement: ${e.message}');
      }
      // Fall back to cached data
      return getEntitlement(userId);
    }
  }

  /// Converts a Firestore document to an Entitlement.
  Entitlement? _documentToEntitlement(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null) return null;

      return Entitlement(
        userId: data['userId'] as String? ?? doc.id,
        currentTier: _parseTier(data['currentTier'] as String?),
        currentPlatform: _parsePlatform(data['currentPlatform'] as String?),
        expiresAt: _parseTimestamp(data['expiresAt']),
        graceEndAt: _parseTimestamp(data['graceEndAt']),
        hasLifetime: data['hasLifetime'] as bool? ?? false,
        isTrial: data['isTrial'] as bool? ?? false,
        trialUsed: data['trialUsed'] as bool? ?? false,
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing entitlement document ${doc.id}: $e');
      }
      return null;
    }
  }

  /// Converts a Firestore document to a PurchaseRecord.
  PurchaseRecord? _documentToPurchase(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null) return null;

      return PurchaseRecord(
        id: data['id'] as String? ?? doc.id,
        platform: _parsePlatform(data['platform'] as String?) ??
            PurchasePlatform.googlePlay,
        productId: data['productId'] as String,
        purchasedAt: _parseTimestamp(data['purchasedAt']) ?? DateTime.now(),
        expiresAt: _parseTimestamp(data['expiresAt']),
        state: _parseSubscriptionState(data['state'] as String?),
        autoRenew: data['autoRenew'] as bool? ?? false,
        price: (data['price'] as num?)?.toDouble(),
        currency: data['currency'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing purchase document ${doc.id}: $e');
      }
      return null;
    }
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static SubscriptionTier _parseTier(String? value) {
    if (value == null) return SubscriptionTier.free;
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  static PurchasePlatform? _parsePlatform(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll('_', '').toLowerCase();
    return switch (normalized) {
      'googleplay' => PurchasePlatform.googlePlay,
      'appstore' => PurchasePlatform.appStore,
      'amazon' => PurchasePlatform.amazon,
      _ => null,
    };
  }

  static SubscriptionState _parseSubscriptionState(String? value) {
    if (value == null) return SubscriptionState.active;
    final normalized = value.replaceAll('_', '').toLowerCase();
    return switch (normalized) {
      'active' => SubscriptionState.active,
      'cancelled' => SubscriptionState.cancelled,
      'expired' => SubscriptionState.expired,
      'graceperiod' => SubscriptionState.gracePeriod,
      'paused' => SubscriptionState.paused,
      _ => SubscriptionState.active,
    };
  }
}
