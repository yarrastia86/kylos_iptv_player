// Kylos IPTV Player - IAP Billing Service
// Implementation of BillingService using in_app_purchase plugin.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart'
    hide PurchaseVerificationData;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart'
    as domain;
import 'package:kylos_iptv_player/features/monetization/domain/product_config.dart';

/// Implementation of BillingService using Flutter's in_app_purchase plugin.
///
/// Supports Google Play Billing and Apple StoreKit.
class IapBillingService implements BillingService {
  IapBillingService({
    InAppPurchase? inAppPurchase,
  }) : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final _eventController = StreamController<BillingEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _productDetails = [];
  bool _isInitialized = false;

  @override
  Stream<BillingEvent> get billingEvents => _eventController.stream;

  @override
  Future<bool> isAvailable() async {
    return _iap.isAvailable();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    final available = await isAvailable();
    if (!available) {
      if (kDebugMode) {
        print('IapBillingService: Store not available');
      }
      return;
    }

    // Configure platform-specific settings
    if (Platform.isIOS) {
      final iosPlatformAddition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(_PaymentQueueDelegate());
    }

    // Listen for purchase updates
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (error) {
        if (kDebugMode) {
          print('IapBillingService: Purchase stream error: $error');
        }
        _eventController.add(
          PurchaseErrorEvent(
            productId: null,
            error: domain.PurchaseError(
              code: domain.PurchaseError.storeError,
              message: 'Purchase stream error',
              details: error.toString(),
            ),
          ),
        );
      },
    );

    _isInitialized = true;

    if (kDebugMode) {
      print('IapBillingService: Initialized');
    }
  }

  @override
  Future<List<Product>> loadProducts(Set<String> productIds) async {
    try {
      final response = await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        if (kDebugMode) {
          print('IapBillingService: Product query error: ${response.error}');
        }
        _eventController.add(
          ProductsLoadError(response.error!.message),
        );
        return [];
      }

      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        print('IapBillingService: Products not found: ${response.notFoundIDs}');
      }

      _productDetails = response.productDetails;
      final products = _productDetails.map(_mapProductDetails).toList();

      _eventController.add(ProductsLoaded(products));

      if (kDebugMode) {
        print('IapBillingService: Loaded ${products.length} products');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('IapBillingService: Load products error: $e');
      }
      _eventController.add(ProductsLoadError(e.toString()));
      return [];
    }
  }

  @override
  Future<void> startPurchase(String productId) async {
    final productDetails = _productDetails.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      // Check if it's a subscription or non-consumable
      final isSubscription = ProductConfig.subscriptionProductIds.contains(productId);

      final success = isSubscription
          ? await _iap.buyNonConsumable(purchaseParam: purchaseParam)
          : await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success && kDebugMode) {
        print('IapBillingService: Purchase initiation returned false');
      }
    } catch (e) {
      if (kDebugMode) {
        print('IapBillingService: Start purchase error: $e');
      }
      _eventController.add(
        PurchaseErrorEvent(
          productId: productId,
          error: domain.PurchaseError(
            code: domain.PurchaseError.storeError,
            message: 'Failed to start purchase',
            details: e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();

      if (kDebugMode) {
        print('IapBillingService: Restore purchases initiated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('IapBillingService: Restore error: $e');
      }
      _eventController.add(
        PurchaseErrorEvent(
          productId: null,
          error: domain.PurchaseError(
            code: domain.PurchaseError.storeError,
            message: 'Failed to restore purchases',
            details: e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Future<void> completePurchase(String purchaseId) async {
    // Find the purchase in pending purchases
    // Note: The purchaseId here maps to the purchase details
    // In practice, you'd track pending purchases separately
    if (kDebugMode) {
      print('IapBillingService: Completing purchase: $purchaseId');
    }
  }

  @override
  Future<bool> isPurchased(String productId) async {
    // This requires checking the entitlement state
    // The actual verification happens server-side
    return false;
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _eventController.close();
    _isInitialized = false;
  }

  /// Handles purchase updates from the store.
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (kDebugMode) {
        print(
          'IapBillingService: Purchase update - '
          '${purchase.productID}, status: ${purchase.status}',
        );
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchase);

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);

        case PurchaseStatus.error:
          _handlePurchaseError(purchase);

        case PurchaseStatus.canceled:
          _eventController.add(PurchaseCancelledEvent(purchase.productID));
      }
    }
  }

  void _handlePendingPurchase(PurchaseDetails purchase) {
    final pendingPurchase = _mapToPendingPurchase(purchase);
    _eventController.add(PurchasePendingEvent(pendingPurchase));
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    final pendingPurchase = _mapToPendingPurchase(purchase);

    // Emit pending event for verification
    _eventController.add(PurchasePendingEvent(pendingPurchase));

    // Note: The purchase should be completed (acknowledged) only after
    // server-side verification. The MonetizationNotifier will call
    // completePurchase after verification succeeds.
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    final error = purchase.error;

    _eventController.add(
      PurchaseErrorEvent(
        productId: purchase.productID,
        error: domain.PurchaseError(
          code: _mapErrorCode(error),
          message: error?.message ?? 'Unknown purchase error',
          details: error?.details?.toString(),
        ),
      ),
    );

    // Complete the purchase to clear it from the queue
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  /// Marks a purchase as completed (acknowledged).
  Future<void> acknowledgePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);

      _eventController.add(
        PurchaseCompletedEvent(
          productId: purchase.productID,
          purchaseId: purchase.purchaseID ?? '',
        ),
      );

      if (kDebugMode) {
        print('IapBillingService: Purchase acknowledged: ${purchase.productID}');
      }
    }
  }

  /// Maps store product details to domain Product.
  Product _mapProductDetails(ProductDetails details) {
    final productType = ProductConfig.typeForProductId(details.id);
    final metadata = ProductConfig.fallbackMetadata[details.id];

    String? freeTrialDuration;
    String? billingPeriod;
    int? savingsPercent = metadata?.savingsPercent;

    // Extract subscription-specific info
    if (Platform.isAndroid && details is GooglePlayProductDetails) {
      final subscriptionOffers =
          details.productDetails.subscriptionOfferDetails;
      if (subscriptionOffers != null && subscriptionOffers.isNotEmpty) {
        final subscriptionOffer = subscriptionOffers.first;
        billingPeriod = _formatBillingPeriod(
          subscriptionOffer.basePlanId,
        );

        // Check for free trial in pricing phases
        for (final phase in subscriptionOffer.pricingPhases) {
          if (phase.priceAmountMicros == 0) {
            freeTrialDuration = _formatPeriod(phase.billingPeriod);
          }
        }
      }
    } else if (Platform.isIOS && details is AppStoreProductDetails) {
      final skProduct = details.skProduct;

      if (skProduct.subscriptionPeriod != null) {
        billingPeriod = _formatSKPeriod(skProduct.subscriptionPeriod!);
      }

      if (skProduct.introductoryPrice != null) {
        final intro = skProduct.introductoryPrice!;
        if (intro.price == '0' || intro.price == '0.00') {
          freeTrialDuration = _formatSKPeriod(intro.subscriptionPeriod);
        }
      }
    }

    return Product(
      id: details.id,
      type: productType,
      title: details.title,
      description: details.description,
      price: details.price,
      currencyCode: details.currencyCode,
      rawPrice: details.rawPrice,
      freeTrialDuration: freeTrialDuration,
      billingPeriod: billingPeriod ?? metadata?.billingPeriod,
      savingsPercent: savingsPercent,
    );
  }

  /// Maps PurchaseDetails to domain PendingPurchase.
  PendingPurchase _mapToPendingPurchase(PurchaseDetails purchase) {
    return PendingPurchase(
      productId: purchase.productID,
      purchaseId: purchase.purchaseID ?? DateTime.now().toIso8601String(),
      verificationData: PurchaseVerificationData(
        localVerificationData:
            purchase.verificationData.localVerificationData,
        serverVerificationData:
            purchase.verificationData.serverVerificationData,
        source: purchase.verificationData.source,
      ),
      transactionDate: purchase.transactionDate != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(purchase.transactionDate!),
            )
          : null,
      status: _mapPurchaseStatus(purchase.status),
    );
  }

  domain.PurchaseStatus _mapPurchaseStatus(PurchaseStatus status) {
    return switch (status) {
      PurchaseStatus.pending => domain.PurchaseStatus.pending,
      PurchaseStatus.purchased => domain.PurchaseStatus.verifying,
      PurchaseStatus.restored => domain.PurchaseStatus.restored,
      PurchaseStatus.error => domain.PurchaseStatus.error,
      PurchaseStatus.canceled => domain.PurchaseStatus.cancelled,
    };
  }

  String _mapErrorCode(IAPError? error) {
    if (error == null) return domain.PurchaseError.unknown;

    // Map common error codes
    final code = error.code;
    if (code.contains('NOT_FOUND')) return domain.PurchaseError.productNotFound;
    if (code.contains('NOT_ALLOWED')) return domain.PurchaseError.purchaseNotAllowed;
    if (code.contains('INVALID')) return domain.PurchaseError.paymentInvalid;
    if (code.contains('ALREADY_OWNED')) return domain.PurchaseError.alreadyOwned;
    if (code.contains('NETWORK')) return domain.PurchaseError.networkError;

    return domain.PurchaseError.storeError;
  }

  String _formatBillingPeriod(String basePlanId) {
    if (basePlanId.contains('monthly')) return '1 month';
    if (basePlanId.contains('annual') || basePlanId.contains('yearly')) {
      return '1 year';
    }
    return basePlanId;
  }

  String _formatPeriod(String isoPeriod) {
    // Parse ISO 8601 duration (e.g., P7D, P1M, P1Y)
    if (isoPeriod.startsWith('P')) {
      final period = isoPeriod.substring(1);
      if (period.endsWith('D')) {
        final days = int.tryParse(period.replaceAll('D', '')) ?? 0;
        return '$days days';
      }
      if (period.endsWith('M')) {
        final months = int.tryParse(period.replaceAll('M', '')) ?? 0;
        return '$months month${months > 1 ? 's' : ''}';
      }
      if (period.endsWith('Y')) {
        final years = int.tryParse(period.replaceAll('Y', '')) ?? 0;
        return '$years year${years > 1 ? 's' : ''}';
      }
    }
    return isoPeriod;
  }

  String _formatSKPeriod(SKProductSubscriptionPeriodWrapper period) {
    final count = period.numberOfUnits;
    return switch (period.unit) {
      SKSubscriptionPeriodUnit.day => '$count day${count > 1 ? 's' : ''}',
      SKSubscriptionPeriodUnit.week => '$count week${count > 1 ? 's' : ''}',
      SKSubscriptionPeriodUnit.month => '$count month${count > 1 ? 's' : ''}',
      SKSubscriptionPeriodUnit.year => '$count year${count > 1 ? 's' : ''}',
    };
  }
}

/// iOS StoreKit payment queue delegate.
class _PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
