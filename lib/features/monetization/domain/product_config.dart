// Kylos IPTV Player - Product Configuration
// Configuration constants for in-app purchase products.

import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';

/// Product configuration for in-app purchases.
///
/// Contains all product IDs and metadata used across the app.
/// Product IDs must match exactly with store configurations.
abstract class ProductConfig {
  ProductConfig._();

  // ===========================================================================
  // PRODUCT IDs
  // ===========================================================================
  //
  // TODO: Replace these placeholder IDs with your actual store product IDs.
  // These must match exactly with:
  // - Google Play Console subscription/product IDs
  // - App Store Connect product IDs
  // - Amazon Appstore product IDs (if applicable)
  //
  // ===========================================================================

  /// Monthly subscription product ID.
  ///
  /// Google Play: Create as "Subscription" with base plan "monthly-base"
  /// App Store: Create as "Auto-Renewable Subscription" in subscription group
  static const String monthlySubscriptionId = 'kylos_pro_monthly';

  /// Annual subscription product ID.
  ///
  /// Google Play: Create as "Subscription" with base plan "annual-base"
  /// App Store: Create as "Auto-Renewable Subscription" in subscription group
  static const String annualSubscriptionId = 'kylos_pro_annual';

  /// Lifetime (one-time) purchase product ID.
  ///
  /// Google Play: Create as "In-app product" (non-consumable)
  /// App Store: Create as "Non-Consumable" in-app purchase
  static const String lifetimeProductId = 'kylos_pro_lifetime';

  /// All product IDs to fetch from stores.
  static const Set<String> allProductIds = {
    monthlySubscriptionId,
    annualSubscriptionId,
    lifetimeProductId,
  };

  /// Subscription product IDs only.
  static const Set<String> subscriptionProductIds = {
    monthlySubscriptionId,
    annualSubscriptionId,
  };

  // ===========================================================================
  // PRODUCT METADATA
  // ===========================================================================
  //
  // Fallback display values used when store data is unavailable.
  // Actual prices are fetched from stores at runtime.
  //
  // ===========================================================================

  /// Product type mapping.
  static ProductType typeForProductId(String productId) {
    return switch (productId) {
      monthlySubscriptionId => ProductType.monthlySubscription,
      annualSubscriptionId => ProductType.annualSubscription,
      lifetimeProductId => ProductType.lifetime,
      _ => throw ArgumentError('Unknown product ID: $productId'),
    };
  }

  /// Fallback product metadata (used if store data unavailable).
  static const Map<String, ProductMetadata> fallbackMetadata = {
    monthlySubscriptionId: ProductMetadata(
      title: 'Kylos Pro Monthly',
      description: 'Unlock all premium features with monthly billing',
      fallbackPrice: r'$2.99',
      billingPeriod: '1 month',
    ),
    annualSubscriptionId: ProductMetadata(
      title: 'Kylos Pro Annual',
      description: 'Best value! Save 44% with annual billing',
      fallbackPrice: r'$19.99',
      billingPeriod: '1 year',
      savingsPercent: 44,
      freeTrialDays: 7,
    ),
    lifetimeProductId: ProductMetadata(
      title: 'Kylos Pro Lifetime',
      description: 'One-time purchase for lifetime access',
      fallbackPrice: r'$49.99',
    ),
  };

  // ===========================================================================
  // FEATURE LISTS (for UI display)
  // ===========================================================================

  /// Features available in the free tier.
  static const List<String> freeFeatures = [
    '1 playlist source',
    '2 profiles',
    '500 channels max',
    '1-day EPG guide',
    '50 favorites',
    'Local storage only',
  ];

  /// Features available in the Pro tier.
  static const List<String> proFeatures = [
    'Unlimited playlists',
    '10 profiles',
    'Unlimited channels',
    '7-day EPG guide',
    'Unlimited favorites',
    'Cloud backup & sync',
    'Multi-device restore',
    'Picture-in-Picture',
    'Chromecast support',
    'Priority support',
  ];

  /// Features unlocked by upgrading to Pro.
  static const List<String> upgradeHighlights = [
    'Unlimited playlists',
    'Cloud sync across devices',
    '7-day EPG guide',
    'Picture-in-Picture mode',
  ];
}

/// Metadata for a product (fallback values).
class ProductMetadata {
  const ProductMetadata({
    required this.title,
    required this.description,
    required this.fallbackPrice,
    this.billingPeriod,
    this.savingsPercent,
    this.freeTrialDays,
  });

  final String title;
  final String description;
  final String fallbackPrice;
  final String? billingPeriod;
  final int? savingsPercent;
  final int? freeTrialDays;
}

// =============================================================================
// AMAZON APPSTORE CONFIGURATION
// =============================================================================
//
// Amazon Appstore uses different product IDs and billing system.
// If targeting Fire TV, implement AmazonBillingService with these IDs.
//
// TODO: Configure Amazon product IDs when implementing Fire TV support.
//
// =============================================================================

/// Amazon-specific product configuration.
abstract class AmazonProductConfig {
  AmazonProductConfig._();

  // TODO: Replace with your Amazon Appstore product IDs
  static const String monthlySubscriptionId = 'kylos_pro_monthly_amazon';
  static const String annualSubscriptionId = 'kylos_pro_annual_amazon';
  static const String lifetimeProductId = 'kylos_pro_lifetime_amazon';

  static const Set<String> allProductIds = {
    monthlySubscriptionId,
    annualSubscriptionId,
    lifetimeProductId,
  };
}
