// Kylos IPTV Player - Promo Code Repository
// Handles promo code validation and redemption.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/promo_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing promotional codes.
///
/// Promo codes can be:
/// 1. Stored in Firebase Firestore (for dynamic management)
/// 2. Hardcoded for special cases (e.g., beta testers)
///
/// User's redeemed codes are stored locally and optionally synced to Firestore.
abstract class PromoCodeRepository {
  /// Validate and redeem a promo code.
  Future<PromoCodeResult> redeemCode(String code, {String? userId});

  /// Get all active redeemed benefits for the user.
  Future<List<RedeemedPromoCode>> getRedeemedCodes();

  /// Check if user has an active premium benefit from promo code.
  Future<bool> hasActivePremiumBenefit();

  /// Check if user has an active ad-free benefit from promo code.
  Future<bool> hasActiveAdFreeBenefit();

  /// Clear all redeemed codes (for testing or account reset).
  Future<void> clearRedeemedCodes();
}

/// Implementation using Firebase Firestore and local storage.
class FirebasePromoCodeRepository implements PromoCodeRepository {
  FirebasePromoCodeRepository({
    FirebaseFirestore? firestore,
    required SharedPreferences preferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;

  static const String _redeemedCodesKey = 'redeemed_promo_codes';
  static const String _promoCodesCollection = 'promo_codes';

  // Hardcoded promo codes for special users (beta testers, reviewers, etc.)
  // These work even without Firebase connection.
  static final Map<String, PromoCode> _hardcodedCodes = {
    'KYLOSBETA': const PromoCode(
      code: 'KYLOSBETA',
      type: PromoCodeType.premium,
      durationDays: 365, // 1 year
      description: 'Beta tester premium access',
    ),
    'KYLOSVIP': const PromoCode(
      code: 'KYLOSVIP',
      type: PromoCodeType.premium,
      durationDays: 0, // Permanent
      description: 'VIP lifetime premium access',
    ),
    'NOADS30': const PromoCode(
      code: 'NOADS30',
      type: PromoCodeType.adFree,
      durationDays: 30,
      description: '30 days ad-free experience',
    ),
    'FREEWEEK': const PromoCode(
      code: 'FREEWEEK',
      type: PromoCodeType.premium,
      durationDays: 7,
      description: '7 days free premium trial',
    ),
  };

  @override
  Future<PromoCodeResult> redeemCode(String code, {String? userId}) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return const PromoCodeError('Please enter a promo code');
    }

    // Check if already redeemed
    final redeemed = await getRedeemedCodes();
    if (redeemed.any((r) => r.code.toUpperCase() == normalizedCode && r.isActive)) {
      return const PromoCodeError('This code has already been redeemed');
    }

    // First check hardcoded codes
    PromoCode? promoCode = _hardcodedCodes[normalizedCode];

    // Then check Firebase if not found
    if (promoCode == null) {
      promoCode = await _fetchCodeFromFirebase(normalizedCode);
    }

    if (promoCode == null) {
      return const PromoCodeError('Invalid promo code');
    }

    if (!promoCode.isValid) {
      if (promoCode.expiresAt != null &&
          DateTime.now().isAfter(promoCode.expiresAt!)) {
        return const PromoCodeError('This promo code has expired');
      }
      if (promoCode.maxRedemptions != null &&
          promoCode.currentRedemptions >= promoCode.maxRedemptions!) {
        return const PromoCodeError('This promo code has reached its maximum redemptions');
      }
      return const PromoCodeError('This promo code is no longer valid');
    }

    // Redeem the code
    final redeemedCode = RedeemedPromoCode(
      code: normalizedCode,
      type: promoCode.type,
      redeemedAt: DateTime.now(),
      expiresAt: promoCode.benefitExpiresAt,
    );

    // Save locally
    await _saveRedeemedCode(redeemedCode);

    // Update redemption count in Firebase (if it's a Firebase code)
    if (!_hardcodedCodes.containsKey(normalizedCode)) {
      await _incrementRedemptionCount(normalizedCode, userId);
    }

    // Generate success message
    final message = _getSuccessMessage(promoCode);

    debugPrint('PromoCode: Redeemed $normalizedCode - ${promoCode.type.name} for ${promoCode.durationDays} days');

    return PromoCodeSuccess(
      code: promoCode,
      benefitExpiresAt: redeemedCode.expiresAt,
      message: message,
    );
  }

  Future<PromoCode?> _fetchCodeFromFirebase(String code) async {
    try {
      final doc = await _firestore
          .collection(_promoCodesCollection)
          .doc(code)
          .get();

      if (!doc.exists) return null;

      return PromoCode.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('PromoCode: Error fetching from Firebase: $e');
      return null;
    }
  }

  Future<void> _incrementRedemptionCount(String code, String? userId) async {
    try {
      await _firestore
          .collection(_promoCodesCollection)
          .doc(code)
          .update({
        'currentRedemptions': FieldValue.increment(1),
        'redemptions': FieldValue.arrayUnion([
          {
            'userId': userId,
            'redeemedAt': DateTime.now().toIso8601String(),
          }
        ]),
      });
    } catch (e) {
      debugPrint('PromoCode: Error updating redemption count: $e');
    }
  }

  Future<void> _saveRedeemedCode(RedeemedPromoCode code) async {
    final codes = await getRedeemedCodes();
    codes.add(code);

    final jsonList = codes.map((c) => c.toJson()).toList();
    await _preferences.setString(_redeemedCodesKey, jsonEncode(jsonList));
  }

  @override
  Future<List<RedeemedPromoCode>> getRedeemedCodes() async {
    final jsonString = _preferences.getString(_redeemedCodesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((j) => RedeemedPromoCode.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PromoCode: Error parsing redeemed codes: $e');
      return [];
    }
  }

  @override
  Future<bool> hasActivePremiumBenefit() async {
    final codes = await getRedeemedCodes();
    return codes.any((c) =>
        c.isActive &&
        (c.type == PromoCodeType.premium || c.type == PromoCodeType.freeTrial));
  }

  @override
  Future<bool> hasActiveAdFreeBenefit() async {
    final codes = await getRedeemedCodes();
    return codes.any((c) =>
        c.isActive &&
        (c.type == PromoCodeType.premium ||
            c.type == PromoCodeType.adFree ||
            c.type == PromoCodeType.freeTrial));
  }

  @override
  Future<void> clearRedeemedCodes() async {
    await _preferences.remove(_redeemedCodesKey);
  }

  String _getSuccessMessage(PromoCode code) {
    final durationText = code.durationDays == 0
        ? 'permanently'
        : 'for ${code.durationDays} days';

    switch (code.type) {
      case PromoCodeType.premium:
        return 'Premium access activated $durationText!';
      case PromoCodeType.adFree:
        return 'Ad-free experience activated $durationText!';
      case PromoCodeType.discount:
        return '${code.discountPercent}% discount applied!';
      case PromoCodeType.freeTrial:
        return 'Free trial activated $durationText!';
    }
  }
}

/// Local-only implementation (when Firebase is not available).
class LocalPromoCodeRepository implements PromoCodeRepository {
  LocalPromoCodeRepository({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const String _redeemedCodesKey = 'redeemed_promo_codes';

  // Same hardcoded codes as Firebase version
  static final Map<String, PromoCode> _hardcodedCodes =
      FirebasePromoCodeRepository._hardcodedCodes;

  @override
  Future<PromoCodeResult> redeemCode(String code, {String? userId}) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return const PromoCodeError('Please enter a promo code');
    }

    final redeemed = await getRedeemedCodes();
    if (redeemed.any((r) => r.code.toUpperCase() == normalizedCode && r.isActive)) {
      return const PromoCodeError('This code has already been redeemed');
    }

    final promoCode = _hardcodedCodes[normalizedCode];
    if (promoCode == null) {
      return const PromoCodeError('Invalid promo code');
    }

    if (!promoCode.isValid) {
      return const PromoCodeError('This promo code is no longer valid');
    }

    final redeemedCode = RedeemedPromoCode(
      code: normalizedCode,
      type: promoCode.type,
      redeemedAt: DateTime.now(),
      expiresAt: promoCode.benefitExpiresAt,
    );

    await _saveRedeemedCode(redeemedCode);

    final message = promoCode.durationDays == 0
        ? 'Premium access activated permanently!'
        : 'Premium access activated for ${promoCode.durationDays} days!';

    return PromoCodeSuccess(
      code: promoCode,
      benefitExpiresAt: redeemedCode.expiresAt,
      message: message,
    );
  }

  Future<void> _saveRedeemedCode(RedeemedPromoCode code) async {
    final codes = await getRedeemedCodes();
    codes.add(code);

    final jsonList = codes.map((c) => c.toJson()).toList();
    await _preferences.setString(_redeemedCodesKey, jsonEncode(jsonList));
  }

  @override
  Future<List<RedeemedPromoCode>> getRedeemedCodes() async {
    final jsonString = _preferences.getString(_redeemedCodesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((j) => RedeemedPromoCode.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> hasActivePremiumBenefit() async {
    final codes = await getRedeemedCodes();
    return codes.any((c) =>
        c.isActive &&
        (c.type == PromoCodeType.premium || c.type == PromoCodeType.freeTrial));
  }

  @override
  Future<bool> hasActiveAdFreeBenefit() async {
    final codes = await getRedeemedCodes();
    return codes.any((c) =>
        c.isActive &&
        (c.type == PromoCodeType.premium ||
            c.type == PromoCodeType.adFree ||
            c.type == PromoCodeType.freeTrial));
  }

  @override
  Future<void> clearRedeemedCodes() async {
    await _preferences.remove(_redeemedCodesKey);
  }
}
