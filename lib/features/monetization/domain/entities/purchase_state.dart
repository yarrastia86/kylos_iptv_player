// Kylos IPTV Player - Purchase State
// Domain entities representing purchase flow state.

import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';

/// Status of a purchase operation.
enum PurchaseStatus {
  /// No purchase in progress.
  idle,

  /// Purchase flow is starting.
  pending,

  /// Waiting for user action in store UI.
  purchasing,

  /// Purchase completed, awaiting verification.
  verifying,

  /// Purchase verified and entitlement granted.
  completed,

  /// Purchase was cancelled by user.
  cancelled,

  /// Purchase failed with error.
  error,

  /// Purchase restored from previous transaction.
  restored,
}

/// Represents the result of a purchase operation.
sealed class PurchaseResult {
  const PurchaseResult();
}

/// Purchase completed successfully.
class PurchaseSuccess extends PurchaseResult {
  const PurchaseSuccess({
    required this.productId,
    required this.transactionId,
    this.platform,
  });

  final String productId;
  final String transactionId;
  final PurchasePlatform? platform;
}

/// Purchase was cancelled by user.
class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();
}

/// Purchase failed with error.
class PurchaseError extends PurchaseResult {
  const PurchaseError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final String? details;

  /// Common error codes.
  static const String productNotFound = 'product_not_found';
  static const String purchaseNotAllowed = 'purchase_not_allowed';
  static const String paymentInvalid = 'payment_invalid';
  static const String paymentDeclined = 'payment_declined';
  static const String networkError = 'network_error';
  static const String storeError = 'store_error';
  static const String verificationFailed = 'verification_failed';
  static const String alreadyOwned = 'already_owned';
  static const String unknown = 'unknown';
}

/// Purchase is pending (deferred payment).
class PurchasePending extends PurchaseResult {
  const PurchasePending({
    required this.productId,
  });

  final String productId;
}

/// Represents the overall monetization state.
class MonetizationState {
  const MonetizationState({
    this.products = const [],
    this.isLoadingProducts = false,
    this.productsError,
    this.purchaseStatus = PurchaseStatus.idle,
    this.currentPurchaseProductId,
    this.lastPurchaseResult,
    this.isRestoringPurchases = false,
    this.entitlement,
  });

  /// Available products for purchase.
  final List<Product> products;

  /// Whether products are being loaded.
  final bool isLoadingProducts;

  /// Error message if product loading failed.
  final String? productsError;

  /// Current purchase operation status.
  final PurchaseStatus purchaseStatus;

  /// Product ID of current purchase (if any).
  final String? currentPurchaseProductId;

  /// Result of last purchase operation.
  final PurchaseResult? lastPurchaseResult;

  /// Whether purchases are being restored.
  final bool isRestoringPurchases;

  /// Current user entitlement.
  final Entitlement? entitlement;

  /// Whether the user has pro access.
  bool get hasPro => entitlement?.hasPro ?? false;

  /// Whether a purchase is in progress.
  bool get isPurchasing =>
      purchaseStatus == PurchaseStatus.pending ||
      purchaseStatus == PurchaseStatus.purchasing ||
      purchaseStatus == PurchaseStatus.verifying;

  /// Whether products have been loaded successfully.
  bool get hasProducts => products.isNotEmpty && productsError == null;

  /// Gets the monthly subscription product.
  Product? get monthlyProduct => products
      .where((p) => p.type == ProductType.monthlySubscription)
      .firstOrNull;

  /// Gets the annual subscription product.
  Product? get annualProduct => products
      .where((p) => p.type == ProductType.annualSubscription)
      .firstOrNull;

  /// Gets the lifetime product.
  Product? get lifetimeProduct =>
      products.where((p) => p.type == ProductType.lifetime).firstOrNull;

  /// Creates a copy with updated fields.
  MonetizationState copyWith({
    List<Product>? products,
    bool? isLoadingProducts,
    String? productsError,
    PurchaseStatus? purchaseStatus,
    String? currentPurchaseProductId,
    PurchaseResult? lastPurchaseResult,
    bool? isRestoringPurchases,
    Entitlement? entitlement,
  }) {
    return MonetizationState(
      products: products ?? this.products,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      productsError: productsError ?? this.productsError,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      currentPurchaseProductId:
          currentPurchaseProductId ?? this.currentPurchaseProductId,
      lastPurchaseResult: lastPurchaseResult ?? this.lastPurchaseResult,
      isRestoringPurchases: isRestoringPurchases ?? this.isRestoringPurchases,
      entitlement: entitlement ?? this.entitlement,
    );
  }

  /// Creates initial state.
  factory MonetizationState.initial() => const MonetizationState();

  @override
  String toString() =>
      'MonetizationState(products: ${products.length}, status: $purchaseStatus, hasPro: $hasPro)';
}
