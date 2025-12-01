// Kylos IPTV Player - Subscription Entity
// Domain entity representing a subscription tier.

/// Available subscription tiers.
enum SubscriptionTier {
  /// Free tier with limited features.
  free,

  /// Premium tier with all features.
  premium,
}

/// Represents a user's subscription status.
class Subscription {
  const Subscription({
    required this.tier,
    this.expiresAt,
    this.productId,
    this.purchaseToken,
    this.isAutoRenewing = false,
  });

  /// Current subscription tier.
  final SubscriptionTier tier;

  /// When the subscription expires (null for free tier).
  final DateTime? expiresAt;

  /// Store product ID for the subscription.
  final String? productId;

  /// Purchase verification token.
  final String? purchaseToken;

  /// Whether the subscription auto-renews.
  final bool isAutoRenewing;

  /// Whether the subscription is currently active.
  bool get isActive {
    if (tier == SubscriptionTier.free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Whether this is a premium subscription.
  bool get isPremium => tier == SubscriptionTier.premium && isActive;

  /// Factory for creating a free subscription.
  factory Subscription.free() {
    return const Subscription(tier: SubscriptionTier.free);
  }

  /// Creates a copy with the given fields replaced.
  Subscription copyWith({
    SubscriptionTier? tier,
    DateTime? expiresAt,
    String? productId,
    String? purchaseToken,
    bool? isAutoRenewing,
  }) {
    return Subscription(
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      productId: productId ?? this.productId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      isAutoRenewing: isAutoRenewing ?? this.isAutoRenewing,
    );
  }
}
