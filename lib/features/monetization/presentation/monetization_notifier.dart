// Kylos IPTV Player - Monetization Notifier
// State management for monetization features.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';
import 'package:kylos_iptv_player/features/monetization/domain/product_config.dart';

/// Notifier for monetization state management.
///
/// Coordinates between:
/// - BillingService (platform IAP)
/// - PurchaseVerifier (backend verification)
/// - EntitlementRepository (user entitlements)
class MonetizationNotifier extends StateNotifier<MonetizationState> {
  MonetizationNotifier({
    required BillingService billingService,
    required PurchaseVerifier purchaseVerifier,
    required EntitlementRepository entitlementRepository,
    required String userId,
  })  : _billingService = billingService,
        _purchaseVerifier = purchaseVerifier,
        _entitlementRepository = entitlementRepository,
        _userId = userId,
        super(MonetizationState.initial()) {
    _initialize();
  }

  final BillingService _billingService;
  final PurchaseVerifier _purchaseVerifier;
  final EntitlementRepository _entitlementRepository;
  final String _userId;

  StreamSubscription<BillingEvent>? _billingSubscription;
  StreamSubscription<Entitlement?>? _entitlementSubscription;

  /// Initializes the monetization system.
  Future<void> _initialize() async {
    // Listen to billing events
    _billingSubscription = _billingService.billingEvents.listen(
      _handleBillingEvent,
      onError: (e) {
        if (kDebugMode) {
          print('MonetizationNotifier: Billing stream error: $e');
        }
      },
    );

    // Listen to entitlement changes
    _entitlementSubscription = _entitlementRepository
        .watchEntitlement(_userId)
        .listen(
          _handleEntitlementUpdate,
          onError: (e) {
            if (kDebugMode) {
              print('MonetizationNotifier: Entitlement stream error: $e');
            }
          },
        );

    // Initialize billing service
    await _billingService.initialize();

    // Load initial entitlement
    await _loadEntitlement();

    // Load available products
    await loadProducts();
  }

  /// Loads available products from the store.
  Future<void> loadProducts() async {
    state = state.copyWith(
      isLoadingProducts: true,
    );

    try {
      final products = await _billingService.loadProducts(
        ProductConfig.allProductIds,
      );

      state = state.copyWith(
        products: products,
        isLoadingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        productsError: e.toString(),
      );
    }
  }

  /// Loads the user's current entitlement.
  Future<void> _loadEntitlement() async {
    try {
      final entitlement = await _entitlementRepository.getEntitlement(_userId);
      state = state.copyWith(entitlement: entitlement);
    } catch (e) {
      if (kDebugMode) {
        print('MonetizationNotifier: Load entitlement error: $e');
      }
    }
  }

  /// Starts a purchase flow for the specified product.
  Future<void> purchase(String productId) async {
    if (state.isPurchasing) {
      if (kDebugMode) {
        print('MonetizationNotifier: Purchase already in progress');
      }
      return;
    }

    state = state.copyWith(
      purchaseStatus: PurchaseStatus.pending,
      currentPurchaseProductId: productId,
    );

    try {
      await _billingService.startPurchase(productId);
    } catch (e) {
      state = state.copyWith(
        purchaseStatus: PurchaseStatus.error,
        lastPurchaseResult: PurchaseError(
          code: PurchaseError.unknown,
          message: e.toString(),
        ),
      );
    }
  }

  /// Restores previous purchases.
  Future<void> restorePurchases() async {
    if (state.isRestoringPurchases) return;

    state = state.copyWith(
      isRestoringPurchases: true,
    );

    try {
      await _billingService.restorePurchases();
    } catch (e) {
      state = state.copyWith(
        isRestoringPurchases: false,
        lastPurchaseResult: PurchaseError(
          code: PurchaseError.unknown,
          message: 'Failed to restore purchases: ${e.toString()}',
        ),
      );
    }
  }

  /// Refreshes entitlement from the backend.
  Future<void> refreshEntitlement() async {
    try {
      final entitlement = await _entitlementRepository.refreshEntitlement(_userId);
      state = state.copyWith(entitlement: entitlement);
    } catch (e) {
      if (kDebugMode) {
        print('MonetizationNotifier: Refresh entitlement error: $e');
      }
    }
  }

  /// Handles billing events from the billing service.
  void _handleBillingEvent(BillingEvent event) {
    if (kDebugMode) {
      print('MonetizationNotifier: Billing event: $event');
    }

    switch (event) {
      case ProductsLoaded(:final products):
        state = state.copyWith(
          products: products,
          isLoadingProducts: false,
        );

      case ProductsLoadError(:final error):
        state = state.copyWith(
          isLoadingProducts: false,
          productsError: error,
        );

      case PurchasePendingEvent(:final purchase):
        _handlePendingPurchase(purchase);

      case PurchaseCompletedEvent(:final productId):
        state = state.copyWith(
          purchaseStatus: PurchaseStatus.completed,
          lastPurchaseResult: PurchaseSuccess(
            productId: productId,
            transactionId: '',
          ),
        );
        // Refresh entitlement after completion
        refreshEntitlement();

      case PurchaseCancelledEvent():
        state = state.copyWith(
          purchaseStatus: PurchaseStatus.cancelled,
          lastPurchaseResult: const PurchaseCancelled(),
        );

      case PurchaseErrorEvent(:final error):
        state = state.copyWith(
          purchaseStatus: PurchaseStatus.error,
          lastPurchaseResult: error,
        );

      case PurchasesRestoredEvent(:final restoredPurchases):
        _handleRestoredPurchases(restoredPurchases);
    }
  }

  /// Handles a pending purchase that needs verification.
  Future<void> _handlePendingPurchase(PendingPurchase purchase) async {
    state = state.copyWith(
      purchaseStatus: PurchaseStatus.verifying,
      currentPurchaseProductId: purchase.productId,
    );

    try {
      // Verify with backend
      final result = await _purchaseVerifier.verifyPurchase(purchase);

      switch (result) {
        case VerificationSuccess():
          // Mark purchase as completed in the store
          await _billingService.completePurchase(purchase.purchaseId);

          state = state.copyWith(
            purchaseStatus: PurchaseStatus.completed,
            lastPurchaseResult: PurchaseSuccess(
              productId: result.productId,
              transactionId: result.purchaseId,
            ),
          );

          // Refresh entitlement from backend
          await refreshEntitlement();

        case VerificationFailure(:final reason, :final shouldRetry):
          if (kDebugMode) {
            print('MonetizationNotifier: Verification failed: $reason');
          }

          state = state.copyWith(
            purchaseStatus: PurchaseStatus.error,
            lastPurchaseResult: PurchaseError(
              code: PurchaseError.verificationFailed,
              message: reason,
              details: shouldRetry ? 'Please try again later' : null,
            ),
          );
      }
    } catch (e) {
      state = state.copyWith(
        purchaseStatus: PurchaseStatus.error,
        lastPurchaseResult: PurchaseError(
          code: PurchaseError.verificationFailed,
          message: 'Verification error: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles restored purchases.
  Future<void> _handleRestoredPurchases(
    List<PendingPurchase> restoredPurchases,
  ) async {
    if (restoredPurchases.isEmpty) {
      state = state.copyWith(
        isRestoringPurchases: false,
        lastPurchaseResult: const PurchaseError(
          code: PurchaseError.productNotFound,
          message: 'No purchases to restore',
        ),
      );
      return;
    }

    // Verify each restored purchase
    for (final purchase in restoredPurchases) {
      await _handlePendingPurchase(purchase);
    }

    state = state.copyWith(isRestoringPurchases: false);
  }

  /// Handles entitlement updates from the backend.
  void _handleEntitlementUpdate(Entitlement? entitlement) {
    state = state.copyWith(entitlement: entitlement);
  }

  /// Clears the last purchase result (e.g., after showing error).
  void clearPurchaseResult() {
    state = state.copyWith(
      purchaseStatus: PurchaseStatus.idle,
    );
  }

  @override
  void dispose() {
    _billingSubscription?.cancel();
    _entitlementSubscription?.cancel();
    _billingService.dispose();
    super.dispose();
  }
}

/// Extension to check feature access based on entitlement.
extension MonetizationStateExtensions on MonetizationState {
  /// Whether the user can add more playlists.
  bool canAddPlaylist(int currentCount) {
    final limits = entitlement != null
        ? FeatureLimits.forTier(entitlement!.currentTier)
        : FeatureLimits.free;
    return currentCount < limits.maxPlaylists;
  }

  /// Whether the user can add more profiles.
  bool canAddProfile(int currentCount) {
    final limits = entitlement != null
        ? FeatureLimits.forTier(entitlement!.currentTier)
        : FeatureLimits.free;
    return currentCount < limits.maxProfiles;
  }

  /// Whether cloud sync is available.
  bool get canUseCloudSync {
    final limits = entitlement != null
        ? FeatureLimits.forTier(entitlement!.currentTier)
        : FeatureLimits.free;
    return limits.cloudSyncEnabled;
  }

  /// Maximum favorites allowed.
  int get maxFavorites {
    final limits = entitlement != null
        ? FeatureLimits.forTier(entitlement!.currentTier)
        : FeatureLimits.free;
    return limits.maxFavorites;
  }

  /// EPG days available.
  int get epgDaysAvailable {
    final limits = entitlement != null
        ? FeatureLimits.forTier(entitlement!.currentTier)
        : FeatureLimits.free;
    return limits.epgDaysAvailable;
  }
}
