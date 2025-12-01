// Kylos IPTV Player - Billing Service Interface
// Domain layer interface for billing operations.

import 'dart:async';

import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';

/// Represents a pending purchase from the store.
class PendingPurchase {
  const PendingPurchase({
    required this.productId,
    required this.purchaseId,
    required this.verificationData,
    this.transactionDate,
    this.status = PurchaseStatus.pending,
  });

  /// Product ID of the purchase.
  final String productId;

  /// Unique purchase/transaction ID.
  final String purchaseId;

  /// Verification data (receipt) for server-side validation.
  final PurchaseVerificationData verificationData;

  /// When the transaction occurred.
  final DateTime? transactionDate;

  /// Current status of this purchase.
  final PurchaseStatus status;
}

/// Verification data for server-side purchase validation.
class PurchaseVerificationData {
  const PurchaseVerificationData({
    required this.localVerificationData,
    required this.serverVerificationData,
    required this.source,
  });

  /// Local verification data (for client-side checks).
  final String localVerificationData;

  /// Server verification data (receipt/token for backend verification).
  final String serverVerificationData;

  /// Source platform of the purchase.
  final String source;
}

/// Event emitted when purchase status changes.
sealed class BillingEvent {
  const BillingEvent();
}

/// Products were loaded successfully.
class ProductsLoaded extends BillingEvent {
  const ProductsLoaded(this.products);
  final List<Product> products;
}

/// Products failed to load.
class ProductsLoadError extends BillingEvent {
  const ProductsLoadError(this.error);
  final String error;
}

/// A purchase is pending and needs to be processed.
class PurchasePendingEvent extends BillingEvent {
  const PurchasePendingEvent(this.purchase);
  final PendingPurchase purchase;
}

/// A purchase was completed (acknowledged).
class PurchaseCompletedEvent extends BillingEvent {
  const PurchaseCompletedEvent({
    required this.productId,
    required this.purchaseId,
  });
  final String productId;
  final String purchaseId;
}

/// A purchase was cancelled.
class PurchaseCancelledEvent extends BillingEvent {
  const PurchaseCancelledEvent(this.productId);
  final String productId;
}

/// A purchase failed with error.
class PurchaseErrorEvent extends BillingEvent {
  const PurchaseErrorEvent({
    required this.productId,
    required this.error,
  });
  final String? productId;
  final PurchaseError error;
}

/// Purchases were restored.
class PurchasesRestoredEvent extends BillingEvent {
  const PurchasesRestoredEvent(this.restoredPurchases);
  final List<PendingPurchase> restoredPurchases;
}

/// Billing service interface.
///
/// Abstracts platform-specific billing implementations (Google Play, App Store, Amazon).
/// Implementations should not leak platform-specific types to the domain layer.
abstract class BillingService {
  /// Stream of billing events.
  ///
  /// Listen to this stream to receive updates about:
  /// - Product loading results
  /// - Purchase status changes
  /// - Restore results
  Stream<BillingEvent> get billingEvents;

  /// Whether the billing service is available on this platform.
  Future<bool> isAvailable();

  /// Initializes the billing service.
  ///
  /// Must be called before any other operations.
  Future<void> initialize();

  /// Loads available products from the store.
  ///
  /// [productIds] - Set of product IDs to fetch.
  /// Returns list of products with pricing information.
  Future<List<Product>> loadProducts(Set<String> productIds);

  /// Starts a purchase flow for a product.
  ///
  /// [productId] - ID of the product to purchase.
  /// Returns immediately; purchase result is delivered via [billingEvents].
  Future<void> startPurchase(String productId);

  /// Restores previous purchases.
  ///
  /// Used to restore purchases on a new device or after reinstall.
  /// Results are delivered via [billingEvents].
  Future<void> restorePurchases();

  /// Completes a pending purchase.
  ///
  /// Must be called after server-side verification to acknowledge
  /// the purchase and prevent refunds.
  ///
  /// [purchaseId] - ID of the purchase to complete.
  Future<void> completePurchase(String purchaseId);

  /// Checks if a product has been purchased.
  ///
  /// [productId] - ID of the product to check.
  /// Note: For subscriptions, this checks current active status.
  Future<bool> isPurchased(String productId);

  /// Disposes resources used by the billing service.
  Future<void> dispose();
}

/// Result of purchase verification by the backend.
sealed class VerificationResult {
  const VerificationResult();
}

/// Verification succeeded, entitlement should be granted.
class VerificationSuccess extends VerificationResult {
  const VerificationSuccess({
    required this.productId,
    required this.purchaseId,
    this.expiresAt,
    this.isTrialPeriod = false,
    this.platform,
  });

  final String productId;
  final String purchaseId;
  final DateTime? expiresAt;
  final bool isTrialPeriod;
  final String? platform;
}

/// Verification failed, purchase should not be acknowledged.
class VerificationFailure extends VerificationResult {
  const VerificationFailure({
    required this.reason,
    this.shouldRetry = false,
  });

  final String reason;
  final bool shouldRetry;
}

/// Interface for backend purchase verification.
///
/// This should call a Cloud Function or backend endpoint to verify
/// the purchase receipt with the store and update entitlements.
abstract class PurchaseVerifier {
  /// Verifies a purchase with the backend.
  ///
  /// [purchase] - The pending purchase to verify.
  /// Returns verification result indicating success or failure.
  Future<VerificationResult> verifyPurchase(PendingPurchase purchase);
}
