// Kylos IPTV Player - Firebase Purchase Verifier
// Implementation of PurchaseVerifier using Firebase Cloud Functions.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';

/// Implementation of PurchaseVerifier using Firebase Cloud Functions.
///
/// Sends purchase receipts to a Cloud Function for server-side verification
/// with Google Play or App Store. The Cloud Function validates the receipt
/// and updates the user's entitlement in Firestore.
class FirebasePurchaseVerifier implements PurchaseVerifier {
  FirebasePurchaseVerifier({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  @override
  Future<VerificationResult> verifyPurchase(PendingPurchase purchase) async {
    try {
      if (kDebugMode) {
        print('FirebasePurchaseVerifier: Verifying purchase ${purchase.purchaseId}');
      }

      // Create a verification request document
      // The Cloud Function will be triggered by this document creation
      // and will verify the receipt with the appropriate store.
      final verificationRef = _firestore
          .collection('purchase_verifications')
          .doc();

      final platform = _determinePlatform(purchase.verificationData.source);

      await verificationRef.set({
        'userId': _userId,
        'productId': purchase.productId,
        'purchaseId': purchase.purchaseId,
        'platform': platform,
        'receipt': purchase.verificationData.serverVerificationData,
        'transactionDate': purchase.transactionDate?.toIso8601String(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Wait for the Cloud Function to process the verification
      // In production, you might use a listener or polling with timeout
      final result = await _waitForVerification(verificationRef);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('FirebasePurchaseVerifier: Verification error: $e');
      }

      return VerificationFailure(
        reason: 'Verification failed: ${e.toString()}',
        shouldRetry: true,
      );
    }
  }

  /// Waits for the Cloud Function to verify the purchase.
  Future<VerificationResult> _waitForVerification(
    DocumentReference<Map<String, dynamic>> verificationRef,
  ) async {
    // Poll for verification result with timeout
    const maxAttempts = 30;
    const pollInterval = Duration(seconds: 1);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(pollInterval);

      final doc = await verificationRef.get();
      final data = doc.data();

      if (data == null) continue;

      final status = data['status'] as String?;

      if (status == 'verified') {
        return VerificationSuccess(
          productId: data['productId'] as String,
          purchaseId: data['purchaseId'] as String,
          expiresAt: data['expiresAt'] != null
              ? DateTime.parse(data['expiresAt'] as String)
              : null,
          isTrialPeriod: data['isTrialPeriod'] as bool? ?? false,
          platform: data['platform'] as String?,
        );
      }

      if (status == 'failed') {
        return VerificationFailure(
          reason: data['failureReason'] as String? ?? 'Verification failed',
          shouldRetry: data['shouldRetry'] as bool? ?? false,
        );
      }

      // Status is still 'pending', continue polling
    }

    // Timeout
    return const VerificationFailure(
      reason: 'Verification timeout',
      shouldRetry: true,
    );
  }

  String _determinePlatform(String source) {
    if (source == 'google_play' || Platform.isAndroid) {
      return 'google_play';
    }
    if (source == 'app_store' || Platform.isIOS) {
      return 'app_store';
    }
    return source;
  }
}

/// Mock implementation for testing.
class MockPurchaseVerifier implements PurchaseVerifier {
  MockPurchaseVerifier({
    this.shouldSucceed = true,
    this.verificationDelay = const Duration(milliseconds: 500),
  });

  final bool shouldSucceed;
  final Duration verificationDelay;

  @override
  Future<VerificationResult> verifyPurchase(PendingPurchase purchase) async {
    await Future<void>.delayed(verificationDelay);

    if (shouldSucceed) {
      return VerificationSuccess(
        productId: purchase.productId,
        purchaseId: purchase.purchaseId,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isTrialPeriod: false,
        platform: 'mock',
      );
    } else {
      return const VerificationFailure(
        reason: 'Mock verification failure',
        shouldRetry: false,
      );
    }
  }
}
