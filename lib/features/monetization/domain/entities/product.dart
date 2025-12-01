// Kylos IPTV Player - Product Entity
// Domain entity representing a purchasable product.

/// Type of product available for purchase.
enum ProductType {
  /// Monthly recurring subscription.
  monthlySubscription,

  /// Annual recurring subscription.
  annualSubscription,

  /// One-time lifetime purchase.
  lifetime,
}

/// Represents a product available for purchase.
///
/// This is a domain entity that abstracts away platform-specific
/// product details from Google Play or App Store.
class Product {
  const Product({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    this.rawPrice,
    this.freeTrialDuration,
    this.billingPeriod,
    this.introductoryPrice,
    this.introductoryPricePeriod,
    this.savingsPercent,
  });

  /// Unique product identifier (matches store product ID).
  final String id;

  /// Type of product.
  final ProductType type;

  /// Localized product title.
  final String title;

  /// Localized product description.
  final String description;

  /// Formatted price string (e.g., "$2.99").
  final String price;

  /// ISO 4217 currency code (e.g., "USD").
  final String currencyCode;

  /// Raw price value in micros or as double.
  final double? rawPrice;

  /// Free trial duration if available (e.g., "7 days").
  final String? freeTrialDuration;

  /// Billing period for subscriptions (e.g., "1 month", "1 year").
  final String? billingPeriod;

  /// Introductory price if available.
  final String? introductoryPrice;

  /// Introductory price period.
  final String? introductoryPricePeriod;

  /// Savings percentage compared to monthly (for annual plans).
  final int? savingsPercent;

  /// Whether this product is a subscription.
  bool get isSubscription =>
      type == ProductType.monthlySubscription ||
      type == ProductType.annualSubscription;

  /// Whether this product has a free trial.
  bool get hasFreeTrial => freeTrialDuration != null;

  /// Whether this product has an introductory offer.
  bool get hasIntroductoryOffer => introductoryPrice != null;

  /// Creates a copy with updated fields.
  Product copyWith({
    String? id,
    ProductType? type,
    String? title,
    String? description,
    String? price,
    String? currencyCode,
    double? rawPrice,
    String? freeTrialDuration,
    String? billingPeriod,
    String? introductoryPrice,
    String? introductoryPricePeriod,
    int? savingsPercent,
  }) {
    return Product(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      rawPrice: rawPrice ?? this.rawPrice,
      freeTrialDuration: freeTrialDuration ?? this.freeTrialDuration,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      introductoryPrice: introductoryPrice ?? this.introductoryPrice,
      introductoryPricePeriod:
          introductoryPricePeriod ?? this.introductoryPricePeriod,
      savingsPercent: savingsPercent ?? this.savingsPercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product($id, $type, $price)';
}
