// Kylos IPTV Player - Promo Code Entity
// Domain entity for promotional codes.

/// Type of promo code benefit.
enum PromoCodeType {
  /// Grants premium/Pro status for a duration.
  premium,

  /// Disables ads for a duration.
  adFree,

  /// Discount on subscription purchase.
  discount,

  /// Extended free trial.
  freeTrial,
}

/// Represents a promotional code.
class PromoCode {
  const PromoCode({
    required this.code,
    required this.type,
    required this.durationDays,
    this.discountPercent,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    this.expiresAt,
    this.isActive = true,
    this.description,
  });

  /// The promo code string (case-insensitive).
  final String code;

  /// Type of benefit this code provides.
  final PromoCodeType type;

  /// Duration of the benefit in days (0 for permanent/one-time).
  final int durationDays;

  /// Discount percentage (for discount type codes).
  final int? discountPercent;

  /// Maximum number of times this code can be redeemed.
  final int? maxRedemptions;

  /// Current number of redemptions.
  final int currentRedemptions;

  /// When this code expires (null = never).
  final DateTime? expiresAt;

  /// Whether this code is active.
  final bool isActive;

  /// Human-readable description.
  final String? description;

  /// Check if this code is valid for redemption.
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (maxRedemptions != null && currentRedemptions >= maxRedemptions!) {
      return false;
    }
    return true;
  }

  /// Get the expiration date for the benefit when redeemed.
  DateTime get benefitExpiresAt {
    if (durationDays == 0) {
      // Permanent benefit - set far in future
      return DateTime.now().add(const Duration(days: 36500)); // ~100 years
    }
    return DateTime.now().add(Duration(days: durationDays));
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type.name,
      'durationDays': durationDays,
      'discountPercent': discountPercent,
      'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'description': description,
    };
  }

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: json['code'] as String,
      type: PromoCodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PromoCodeType.premium,
      ),
      durationDays: json['durationDays'] as int? ?? 30,
      discountPercent: json['discountPercent'] as int?,
      maxRedemptions: json['maxRedemptions'] as int?,
      currentRedemptions: json['currentRedemptions'] as int? ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }
}

/// Result of a promo code redemption attempt.
sealed class PromoCodeResult {
  const PromoCodeResult();
}

/// Successfully redeemed promo code.
class PromoCodeSuccess extends PromoCodeResult {
  const PromoCodeSuccess({
    required this.code,
    required this.benefitExpiresAt,
    required this.message,
  });

  final PromoCode code;
  final DateTime benefitExpiresAt;
  final String message;
}

/// Promo code redemption failed.
class PromoCodeError extends PromoCodeResult {
  const PromoCodeError(this.message);

  final String message;
}

/// User's redeemed promo code benefit.
class RedeemedPromoCode {
  const RedeemedPromoCode({
    required this.code,
    required this.type,
    required this.redeemedAt,
    required this.expiresAt,
  });

  final String code;
  final PromoCodeType type;
  final DateTime redeemedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type.name,
      'redeemedAt': redeemedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory RedeemedPromoCode.fromJson(Map<String, dynamic> json) {
    return RedeemedPromoCode(
      code: json['code'] as String,
      type: PromoCodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PromoCodeType.premium,
      ),
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
