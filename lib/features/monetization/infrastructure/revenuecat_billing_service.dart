// Kylos IPTV Player - RevenueCat Billing Service
// RevenueCat implementation of the BillingService interface.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';

/// RevenueCat configuration.
///
/// TODO: Replace these with your actual RevenueCat API keys.
abstract class RevenueCatConfig {
  RevenueCatConfig._();

  /// RevenueCat API key for Google Play.
  static const String apiKeyAndroid = 'YOUR_REVENUECAT_GOOGLE_API_KEY';

  /// RevenueCat API key for App Store.
  static const String apiKeyIOS = 'YOUR_REVENUECAT_APPLE_API_KEY';

  /// RevenueCat API key for Amazon Appstore.
  static const String apiKeyAmazon = 'YOUR_REVENUECAT_AMAZON_API_KEY';

  /// The entitlement identifier for Pro access.
  static const String proEntitlementId = 'pro';

  /// The default offering identifier.
  static const String defaultOfferingId = 'default';

  /// Get the API key for the current platform.
  static String get currentApiKey {
    if (kIsWeb) {
      throw UnsupportedError('RevenueCat is not supported on web');
    }
    if (Platform.isIOS) return apiKeyIOS;
    if (Platform.isAndroid) return apiKeyAndroid;
    throw UnsupportedError('RevenueCat is not supported on this platform');
  }
}

/// RevenueCat implementation of [BillingService].
///
/// Uses the RevenueCat SDK for cross-platform subscription management.
/// RevenueCat handles receipt validation, entitlement management, and
/// cross-device sync automatically.
class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService();

  final _billingEventsController = StreamController<BillingEvent>.broadcast();
  bool _isInitialized = false;
  List<Package>? _packages;
  CustomerInfo? _customerInfo;

  @override
  Stream<BillingEvent> get billingEvents => _billingEventsController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final available = await isAvailable();
      if (!available) {
        debugPrint('RevenueCat: Platform not supported');
        return;
      }

      // Configure RevenueCat
      final configuration = PurchasesConfiguration(RevenueCatConfig.currentApiKey);
      await Purchases.configure(configuration);

      // Enable debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      _isInitialized = true;
      debugPrint('RevenueCat: Initialized successfully');

      // Load initial customer info
      await _fetchCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat: Initialization failed: $e');
      _billingEventsController.add(ProductsLoadError('Failed to initialize: $e'));
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    debugPrint('RevenueCat: Customer info updated');
    _customerInfo = info;

    // Check if user has Pro entitlement
    final hasPro = info.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;
    debugPrint('RevenueCat: Has Pro entitlement: $hasPro');

    // Emit event if there's an active entitlement
    if (hasPro) {
      final entitlement = info.entitlements.all[RevenueCatConfig.proEntitlementId]!;
      _billingEventsController.add(PurchaseCompletedEvent(
        productId: entitlement.productIdentifier,
        purchaseId: entitlement.originalPurchaseDate ?? '',
      ));
    }
  }

  Future<void> _fetchCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat: Failed to fetch customer info: $e');
    }
  }

  @override
  Future<List<Product>> loadProducts(Set<String> productIds) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Fetch offerings from RevenueCat
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint('RevenueCat: No current offering');
        _billingEventsController.add(const ProductsLoadError('No offerings available'));
        return [];
      }

      _packages = offerings.current!.availablePackages;
      debugPrint('RevenueCat: Loaded ${_packages!.length} packages');

      // Convert to our Product model
      final products = _packages!.map((package) => _packageToProduct(package)).toList();

      _billingEventsController.add(ProductsLoaded(products));
      return products;
    } catch (e) {
      debugPrint('RevenueCat: Failed to load products: $e');
      _billingEventsController.add(ProductsLoadError('Failed to load products: $e'));
      return [];
    }
  }

  Product _packageToProduct(Package package) {
    final storeProduct = package.storeProduct;

    // Determine product type
    ProductType type;
    switch (package.packageType) {
      case PackageType.monthly:
        type = ProductType.monthlySubscription;
      case PackageType.annual:
        type = ProductType.annualSubscription;
      case PackageType.lifetime:
        type = ProductType.lifetime;
      default:
        type = ProductType.monthlySubscription;
    }

    // Parse intro offer if available
    String? introPrice;
    String? introPeriod;
    final introOffer = storeProduct.introductoryPrice;
    if (introOffer != null) {
      introPrice = introOffer.priceString;
      introPeriod = '${introOffer.periodNumberOfUnits} ${introOffer.periodUnit.name}';
    }

    // Determine billing period
    String? billingPeriod;
    final subscriptionPeriod = storeProduct.subscriptionPeriod;
    if (subscriptionPeriod != null) {
      billingPeriod = _formatPeriod(subscriptionPeriod);
    }

    return Product(
      id: storeProduct.identifier,
      title: storeProduct.title,
      description: storeProduct.description,
      price: storeProduct.priceString,
      rawPrice: storeProduct.price,
      currencyCode: storeProduct.currencyCode,
      type: type,
      introductoryPrice: introPrice,
      introductoryPricePeriod: introPeriod,
      billingPeriod: billingPeriod,
    );
  }

  String _formatPeriod(String period) {
    // RevenueCat returns period in ISO 8601 format like "P1M", "P1Y", etc.
    if (period.startsWith('P')) {
      final value = period.substring(1, period.length - 1);
      final unit = period[period.length - 1];
      switch (unit) {
        case 'D':
          return '$value day${value != '1' ? 's' : ''}';
        case 'W':
          return '$value week${value != '1' ? 's' : ''}';
        case 'M':
          return '$value month${value != '1' ? 's' : ''}';
        case 'Y':
          return '$value year${value != '1' ? 's' : ''}';
      }
    }
    return period;
  }

  @override
  Future<void> startPurchase(String productId) async {
    if (!_isInitialized) {
      _billingEventsController.add(PurchaseErrorEvent(
        productId: productId,
        error: const PurchaseError(
          code: 'not_initialized',
          message: 'Billing service not initialized',
        ),
      ));
      return;
    }

    // Find the package for this product
    final package = _packages?.firstWhere(
      (p) => p.storeProduct.identifier == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    if (package == null) {
      _billingEventsController.add(PurchaseErrorEvent(
        productId: productId,
        error: PurchaseError(
          code: 'product_not_found',
          message: 'Product not found: $productId',
        ),
      ));
      return;
    }

    try {
      debugPrint('RevenueCat: Starting purchase for $productId');

      // Use the new purchase API in v9 with factory constructor
      final result = await Purchases.purchase(PurchaseParams.package(package));

      // Get customer info after purchase
      final customerInfo = result.customerInfo;

      // Check if purchase was successful
      final hasPro = customerInfo.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;

      if (hasPro) {
        debugPrint('RevenueCat: Purchase successful');
        _customerInfo = customerInfo;
        _billingEventsController.add(PurchaseCompletedEvent(
          productId: productId,
          purchaseId: customerInfo.originalPurchaseDate ?? DateTime.now().toIso8601String(),
        ));
      } else {
        _billingEventsController.add(PurchaseCancelledEvent(productId));
      }
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: Purchase error: ${e.code}');
      _handlePlatformException(productId, e);
    } catch (e) {
      debugPrint('RevenueCat: Purchase failed: $e');
      _billingEventsController.add(PurchaseErrorEvent(
        productId: productId,
        error: PurchaseError(
          code: 'unknown',
          message: e.toString(),
        ),
      ));
    }
  }

  void _handlePurchaseError(String productId, PurchasesErrorCode errorCode) {
    String code;
    String message;
    bool isCancellation = false;

    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        isCancellation = true;
        code = 'cancelled';
        message = 'Purchase was cancelled';
      case PurchasesErrorCode.storeProblemError:
        code = 'store_error';
        message = 'There was a problem with the store';
      case PurchasesErrorCode.purchaseNotAllowedError:
        code = 'not_allowed';
        message = 'Purchases are not allowed on this device';
      case PurchasesErrorCode.purchaseInvalidError:
        code = 'invalid';
        message = 'The purchase was invalid';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        code = 'not_available';
        message = 'Product is not available for purchase';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        code = 'already_purchased';
        message = 'You already own this product';
      case PurchasesErrorCode.networkError:
        code = 'network';
        message = 'Network error. Please check your connection.';
      default:
        code = 'unknown';
        message = 'An error occurred during purchase';
    }

    if (isCancellation) {
      _billingEventsController.add(PurchaseCancelledEvent(productId));
    } else {
      _billingEventsController.add(PurchaseErrorEvent(
        productId: productId,
        error: PurchaseError(code: code, message: message),
      ));
    }
  }

  void _handlePlatformException(String productId, PlatformException e) {
    // Check for common error codes
    final errorCode = e.code;
    String code;
    String message;
    bool isCancellation = false;

    if (errorCode.contains('PURCHASE_CANCELLED') ||
        errorCode.contains('UserCancelledError') ||
        errorCode == '1') {
      isCancellation = true;
      code = 'cancelled';
      message = 'Purchase was cancelled';
    } else if (errorCode.contains('NETWORK') || errorCode.contains('network')) {
      code = 'network';
      message = 'Network error. Please check your connection.';
    } else if (errorCode.contains('STORE') || errorCode.contains('store')) {
      code = 'store_error';
      message = 'There was a problem with the store';
    } else if (errorCode.contains('ALREADY') || errorCode.contains('already')) {
      code = 'already_purchased';
      message = 'You already own this product';
    } else {
      code = errorCode;
      message = e.message ?? 'An error occurred during purchase';
    }

    if (isCancellation) {
      _billingEventsController.add(PurchaseCancelledEvent(productId));
    } else {
      _billingEventsController.add(PurchaseErrorEvent(
        productId: productId,
        error: PurchaseError(code: code, message: message),
      ));
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!_isInitialized) return;

    try {
      debugPrint('RevenueCat: Restoring purchases');
      final info = await Purchases.restorePurchases();
      _customerInfo = info;

      final hasPro = info.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;

      if (hasPro) {
        final entitlement = info.entitlements.all[RevenueCatConfig.proEntitlementId]!;
        _billingEventsController.add(PurchasesRestoredEvent([
          PendingPurchase(
            productId: entitlement.productIdentifier,
            purchaseId: entitlement.originalPurchaseDate ?? '',
            verificationData: const PurchaseVerificationData(
              localVerificationData: '',
              serverVerificationData: '',
              source: 'revenuecat',
            ),
            status: PurchaseStatus.completed,
          ),
        ]));
      } else {
        _billingEventsController.add(const PurchasesRestoredEvent([]));
      }

      debugPrint('RevenueCat: Restore complete, hasPro: $hasPro');
    } catch (e) {
      debugPrint('RevenueCat: Restore failed: $e');
      _billingEventsController.add(PurchaseErrorEvent(
        productId: null,
        error: PurchaseError(
          code: 'restore_failed',
          message: 'Failed to restore purchases: $e',
        ),
      ));
    }
  }

  @override
  Future<void> completePurchase(String purchaseId) async {
    // RevenueCat handles purchase completion automatically
    debugPrint('RevenueCat: completePurchase called (handled automatically)');
  }

  @override
  Future<bool> isPurchased(String productId) async {
    if (!_isInitialized) return false;

    try {
      _customerInfo ??= await Purchases.getCustomerInfo();
      return _customerInfo?.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat: Failed to check purchase status: $e');
      return false;
    }
  }

  /// Check if user has Pro entitlement.
  Future<bool> hasPro() async {
    return isPurchased(RevenueCatConfig.proEntitlementId);
  }

  /// Set the user ID for RevenueCat (for cross-device sync).
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;

    try {
      await Purchases.logIn(userId);
      debugPrint('RevenueCat: User logged in: $userId');
    } catch (e) {
      debugPrint('RevenueCat: Failed to log in user: $e');
    }
  }

  /// Log out the current user (reset to anonymous).
  Future<void> logOut() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
      debugPrint('RevenueCat: User logged out');
    } catch (e) {
      debugPrint('RevenueCat: Failed to log out: $e');
    }
  }

  @override
  Future<void> dispose() async {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    await _billingEventsController.close();
    _isInitialized = false;
  }
}
