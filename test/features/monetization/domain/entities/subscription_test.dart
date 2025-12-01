// Kylos IPTV Player - Subscription Entity Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/subscription.dart';

void main() {
  group('Subscription', () {
    test('free subscription should always be active', () {
      final subscription = Subscription.free();

      expect(subscription.tier, SubscriptionTier.free);
      expect(subscription.isActive, true);
      expect(subscription.isPremium, false);
    });

    test('premium subscription should be active if not expired', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final subscription = Subscription(
        tier: SubscriptionTier.premium,
        expiresAt: futureDate,
      );

      expect(subscription.isActive, true);
      expect(subscription.isPremium, true);
    });

    test('premium subscription should be inactive if expired', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final subscription = Subscription(
        tier: SubscriptionTier.premium,
        expiresAt: pastDate,
      );

      expect(subscription.isActive, false);
      expect(subscription.isPremium, false);
    });

    test('premium subscription without expiry should be inactive', () {
      const subscription = Subscription(
        tier: SubscriptionTier.premium,
      );

      expect(subscription.isActive, false);
      expect(subscription.isPremium, false);
    });

    test('copyWith should create copy with updated fields', () {
      final subscription = Subscription.free();
      final updated = subscription.copyWith(
        tier: SubscriptionTier.premium,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(updated.tier, SubscriptionTier.premium);
      expect(subscription.tier, SubscriptionTier.free);
    });
  });

  group('SubscriptionTier', () {
    test('should have two tiers', () {
      expect(SubscriptionTier.values.length, 2);
      expect(SubscriptionTier.values, contains(SubscriptionTier.free));
      expect(SubscriptionTier.values, contains(SubscriptionTier.premium));
    });
  });
}
