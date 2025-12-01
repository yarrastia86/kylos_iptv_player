// Kylos IPTV Player - Monetization Providers
// Riverpod providers for monetization features.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';
import 'package:kylos_iptv_player/features/monetization/infrastructure/firebase_purchase_verifier.dart';
import 'package:kylos_iptv_player/features/monetization/infrastructure/iap_billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_notifier.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firebase_providers.dart';

// =============================================================================
// Core Service Providers
// =============================================================================

/// Provider for the billing service.
final billingServiceProvider = Provider<BillingService>((ref) {
  final service = IapBillingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the purchase verifier.
final purchaseVerifierProvider = Provider<PurchaseVerifier>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);

  if (user == null) {
    // Return mock verifier if no user
    return MockPurchaseVerifier(shouldSucceed: false);
  }

  return FirebasePurchaseVerifier(
    firestore: firestore,
    userId: user.uid,
  );
});

// =============================================================================
// State Management Providers
// =============================================================================

/// Provider for the monetization notifier.
final monetizationNotifierProvider =
    StateNotifierProvider<MonetizationNotifier, MonetizationState>((ref) {
  final user = ref.watch(currentUserProvider);
  final billingService = ref.watch(billingServiceProvider);
  final purchaseVerifier = ref.watch(purchaseVerifierProvider);
  final entitlementRepo = ref.watch(entitlementRepositoryProvider);

  return MonetizationNotifier(
    billingService: billingService,
    purchaseVerifier: purchaseVerifier,
    entitlementRepository: entitlementRepo,
    userId: user?.uid ?? '',
  );
});

// =============================================================================
// Convenience Providers
// =============================================================================

/// Provider for current monetization state.
final monetizationStateProvider = Provider<MonetizationState>((ref) {
  return ref.watch(monetizationNotifierProvider);
});

/// Provider for available products.
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(monetizationNotifierProvider).products;
});

/// Provider for whether products are loading.
final isLoadingProductsProvider = Provider<bool>((ref) {
  return ref.watch(monetizationNotifierProvider).isLoadingProducts;
});

/// Provider for products load error.
final productsErrorProvider = Provider<String?>((ref) {
  return ref.watch(monetizationNotifierProvider).productsError;
});

/// Provider for current purchase status.
final purchaseStatusProvider = Provider<PurchaseStatus>((ref) {
  return ref.watch(monetizationNotifierProvider).purchaseStatus;
});

/// Provider for whether a purchase is in progress.
final isPurchasingProvider = Provider<bool>((ref) {
  return ref.watch(monetizationNotifierProvider).isPurchasing;
});

/// Provider for whether user has pro access.
final hasProAccessProvider = Provider<bool>((ref) {
  return ref.watch(monetizationNotifierProvider).hasPro;
});

/// Provider for current entitlement.
final currentEntitlementProvider = Provider<Entitlement?>((ref) {
  return ref.watch(monetizationNotifierProvider).entitlement;
});

/// Provider for monthly product.
final monthlyProductProvider = Provider<Product?>((ref) {
  return ref.watch(monetizationNotifierProvider).monthlyProduct;
});

/// Provider for annual product.
final annualProductProvider = Provider<Product?>((ref) {
  return ref.watch(monetizationNotifierProvider).annualProduct;
});

/// Provider for lifetime product.
final lifetimeProductProvider = Provider<Product?>((ref) {
  return ref.watch(monetizationNotifierProvider).lifetimeProduct;
});

// =============================================================================
// Feature Access Providers
// =============================================================================

/// Provider for feature limits.
final featureLimitsFromMonetizationProvider = Provider<FeatureLimits>((ref) {
  final entitlement = ref.watch(currentEntitlementProvider);
  if (entitlement == null) return FeatureLimits.free;
  return FeatureLimits.forTier(entitlement.currentTier);
});

/// Provider for checking if user can add more playlists.
Provider<bool> canAddPlaylistProvider(int currentCount) {
  return Provider<bool>((ref) {
    final state = ref.watch(monetizationNotifierProvider);
    return state.canAddPlaylist(currentCount);
  });
}

/// Provider for checking if user can add more profiles.
Provider<bool> canAddProfileProvider(int currentCount) {
  return Provider<bool>((ref) {
    final state = ref.watch(monetizationNotifierProvider);
    return state.canAddProfile(currentCount);
  });
}

/// Provider for cloud sync availability.
final canUseCloudSyncProvider = Provider<bool>((ref) {
  return ref.watch(monetizationNotifierProvider).canUseCloudSync;
});

/// Provider for max favorites count.
final maxFavoritesProvider = Provider<int>((ref) {
  return ref.watch(monetizationNotifierProvider).maxFavorites;
});

/// Provider for EPG days available.
final epgDaysAvailableProvider = Provider<int>((ref) {
  return ref.watch(monetizationNotifierProvider).epgDaysAvailable;
});

// =============================================================================
// Actions
// =============================================================================

/// Purchases the specified product.
Future<void> purchaseProduct(WidgetRef ref, String productId) async {
  await ref.read(monetizationNotifierProvider.notifier).purchase(productId);
}

/// Restores purchases.
Future<void> restorePurchases(WidgetRef ref) async {
  await ref.read(monetizationNotifierProvider.notifier).restorePurchases();
}

/// Refreshes products.
Future<void> refreshProducts(WidgetRef ref) async {
  await ref.read(monetizationNotifierProvider.notifier).loadProducts();
}

/// Clears the last purchase result.
void clearPurchaseResult(WidgetRef ref) {
  ref.read(monetizationNotifierProvider.notifier).clearPurchaseResult();
}
