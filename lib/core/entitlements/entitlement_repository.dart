// Kylos IPTV Player - Entitlement Repository Interface
// Domain layer interface for entitlement/subscription operations.

/// Subscription tier levels.
enum SubscriptionTier {
  /// Free tier with limited features.
  free,

  /// Pro tier with full features.
  pro,
}

/// Purchase platform.
enum PurchasePlatform {
  googlePlay,
  appStore,
  amazon,
}

/// Subscription state.
enum SubscriptionState {
  active,
  cancelled,
  expired,
  gracePeriod,
  paused,
}

/// Represents a user's entitlement/subscription status.
class Entitlement {
  const Entitlement({
    required this.userId,
    required this.currentTier,
    this.currentPlatform,
    this.expiresAt,
    this.graceEndAt,
    this.hasLifetime = false,
    this.isTrial = false,
    this.trialUsed = false,
    this.updatedAt,
  });

  /// User ID this entitlement belongs to.
  final String userId;

  /// Current subscription tier.
  final SubscriptionTier currentTier;

  /// Platform where the subscription was purchased.
  final PurchasePlatform? currentPlatform;

  /// When the subscription expires.
  final DateTime? expiresAt;

  /// End of grace period if payment failed.
  final DateTime? graceEndAt;

  /// Whether user has lifetime access.
  final bool hasLifetime;

  /// Whether currently on trial.
  final bool isTrial;

  /// Whether trial has been used.
  final bool trialUsed;

  /// When this entitlement was last updated.
  final DateTime? updatedAt;

  /// Whether the subscription is currently active.
  bool get isActive {
    if (hasLifetime) return true;
    if (currentTier == SubscriptionTier.free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Whether the user is in grace period.
  bool get isInGracePeriod {
    if (graceEndAt == null) return false;
    return DateTime.now().isBefore(graceEndAt!);
  }

  /// Whether the user has pro features.
  bool get hasPro => currentTier == SubscriptionTier.pro && isActive;

  /// Creates a free tier entitlement.
  factory Entitlement.free(String userId) {
    return Entitlement(
      userId: userId,
      currentTier: SubscriptionTier.free,
    );
  }

  Entitlement copyWith({
    String? userId,
    SubscriptionTier? currentTier,
    PurchasePlatform? currentPlatform,
    DateTime? expiresAt,
    DateTime? graceEndAt,
    bool? hasLifetime,
    bool? isTrial,
    bool? trialUsed,
    DateTime? updatedAt,
  }) {
    return Entitlement(
      userId: userId ?? this.userId,
      currentTier: currentTier ?? this.currentTier,
      currentPlatform: currentPlatform ?? this.currentPlatform,
      expiresAt: expiresAt ?? this.expiresAt,
      graceEndAt: graceEndAt ?? this.graceEndAt,
      hasLifetime: hasLifetime ?? this.hasLifetime,
      isTrial: isTrial ?? this.isTrial,
      trialUsed: trialUsed ?? this.trialUsed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Entitlement($userId, $currentTier, pro: $hasPro)';
}

/// Represents a single purchase record.
class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.platform,
    required this.productId,
    required this.purchasedAt,
    this.expiresAt,
    required this.state,
    this.autoRenew = false,
    this.price,
    this.currency,
  });

  final String id;
  final PurchasePlatform platform;
  final String productId;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final SubscriptionState state;
  final bool autoRenew;
  final double? price;
  final String? currency;

  @override
  String toString() => 'PurchaseRecord($id, $productId, $state)';
}

/// Feature limits based on subscription tier.
class FeatureLimits {
  const FeatureLimits({
    required this.maxProfiles,
    required this.maxPlaylists,
    required this.maxFavorites,
    required this.epgDaysAvailable,
    required this.cloudSyncEnabled,
  });

  final int maxProfiles;
  final int maxPlaylists;
  final int maxFavorites;
  final int epgDaysAvailable;
  final bool cloudSyncEnabled;

  /// Default free tier limits.
  static const free = FeatureLimits(
    maxProfiles: 2,
    maxPlaylists: 1,
    maxFavorites: 50,
    epgDaysAvailable: 1,
    cloudSyncEnabled: false,
  );

  /// Default pro tier limits.
  static const pro = FeatureLimits(
    maxProfiles: 10,
    maxPlaylists: 10,
    maxFavorites: 500,
    epgDaysAvailable: 7,
    cloudSyncEnabled: true,
  );

  /// Gets limits for a given tier.
  static FeatureLimits forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.pro:
        return pro;
    }
  }
}

/// Repository interface for entitlement operations.
///
/// Entitlements are read-only from the client - modifications happen
/// via Cloud Functions after purchase verification.
abstract class EntitlementRepository {
  /// Gets the current user's entitlement.
  Future<Entitlement?> getEntitlement(String userId);

  /// Stream of entitlement changes for real-time updates.
  Stream<Entitlement?> watchEntitlement(String userId);

  /// Gets purchase history for the user.
  Future<List<PurchaseRecord>> getPurchaseHistory(String userId);

  /// Gets feature limits for the user's current tier.
  Future<FeatureLimits> getFeatureLimits(String userId);

  /// Refreshes entitlement from server.
  ///
  /// Used after a purchase to get updated status.
  Future<Entitlement?> refreshEntitlement(String userId);
}
