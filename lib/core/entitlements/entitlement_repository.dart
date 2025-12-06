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
///
/// Multi-device support:
/// - Free tier: 1 concurrent stream, 2 devices
/// - Pro tier: 2 concurrent streams, 5 devices (like Netflix Standard)
/// - Pro+ tier: 4 concurrent streams, 10 devices (like Netflix Premium)
/// - Family tier: 6 concurrent streams, 15 devices
class FeatureLimits {
  const FeatureLimits({
    required this.maxProfiles,
    required this.maxPlaylists,
    required this.maxFavorites,
    required this.epgDaysAvailable,
    required this.cloudSyncEnabled,
    required this.maxConcurrentStreams,
    required this.maxRegisteredDevices,
    this.allowDownloads = false,
    this.maxDownloads = 0,
  });

  final int maxProfiles;
  final int maxPlaylists;
  final int maxFavorites;
  final int epgDaysAvailable;
  final bool cloudSyncEnabled;

  /// Maximum simultaneous streams across all devices.
  final int maxConcurrentStreams;

  /// Maximum devices that can be registered to this account.
  final int maxRegisteredDevices;

  /// Whether offline downloads are allowed.
  final bool allowDownloads;

  /// Maximum number of offline downloads.
  final int maxDownloads;

  /// Default free tier limits.
  /// Like Netflix Basic with ads: 1 screen, limited devices.
  static const free = FeatureLimits(
    maxProfiles: 2,
    maxPlaylists: 1,
    maxFavorites: 50,
    epgDaysAvailable: 1,
    cloudSyncEnabled: false,
    maxConcurrentStreams: 1,
    maxRegisteredDevices: 2,
    allowDownloads: false,
    maxDownloads: 0,
  );

  /// Default pro tier limits.
  /// Like Netflix Standard: 2 screens, more devices.
  static const pro = FeatureLimits(
    maxProfiles: 5,
    maxPlaylists: 10,
    maxFavorites: 500,
    epgDaysAvailable: 7,
    cloudSyncEnabled: true,
    maxConcurrentStreams: 2,
    maxRegisteredDevices: 5,
    allowDownloads: true,
    maxDownloads: 10,
  );

  /// Pro+ tier limits.
  /// Like Netflix Premium: 4 screens, more devices, 4K.
  static const proPlus = FeatureLimits(
    maxProfiles: 8,
    maxPlaylists: 25,
    maxFavorites: 1000,
    epgDaysAvailable: 14,
    cloudSyncEnabled: true,
    maxConcurrentStreams: 4,
    maxRegisteredDevices: 10,
    allowDownloads: true,
    maxDownloads: 25,
  );

  /// Family tier limits.
  /// Maximum sharing: 6 screens for large families.
  static const family = FeatureLimits(
    maxProfiles: 10,
    maxPlaylists: 50,
    maxFavorites: 2000,
    epgDaysAvailable: 14,
    cloudSyncEnabled: true,
    maxConcurrentStreams: 6,
    maxRegisteredDevices: 15,
    allowDownloads: true,
    maxDownloads: 50,
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

  /// Gets limits by tier name string.
  static FeatureLimits forTierName(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'pro':
        return pro;
      case 'pro_plus':
      case 'proplus':
        return proPlus;
      case 'family':
        return family;
      case 'free':
      default:
        return free;
    }
  }

  /// Display text for concurrent streams limit.
  String get streamsDisplayText {
    if (maxConcurrentStreams == 1) {
      return '1 screen at a time';
    }
    return '$maxConcurrentStreams screens at a time';
  }

  /// Display text for device limit.
  String get devicesDisplayText {
    return 'Up to $maxRegisteredDevices devices';
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
