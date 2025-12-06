// Kylos IPTV Player - Promo Code Providers
// Riverpod providers for promo code functionality.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/promo_code.dart';
import 'package:kylos_iptv_player/features/monetization/infrastructure/promo_code_repository.dart';
import 'package:kylos_iptv_player/infrastructure/providers/infrastructure_providers.dart';

/// Provider for the promo code repository.
final promoCodeRepositoryProvider = Provider<PromoCodeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Use Firebase version if available, otherwise local
  return FirebasePromoCodeRepository(preferences: prefs);
});

/// Provider to check if user has premium from promo code.
final hasProFromPromoCodeProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(promoCodeRepositoryProvider);
  return repo.hasActivePremiumBenefit();
});

/// Provider to check if user has ad-free from promo code.
final hasAdFreeFromPromoCodeProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(promoCodeRepositoryProvider);
  return repo.hasActiveAdFreeBenefit();
});

/// Provider to get all redeemed promo codes.
final redeemedPromoCodesProvider = FutureProvider<List<RedeemedPromoCode>>((ref) async {
  final repo = ref.watch(promoCodeRepositoryProvider);
  return repo.getRedeemedCodes();
});

/// Provider to get active redeemed benefits.
final activePromoBenefitsProvider = FutureProvider<List<RedeemedPromoCode>>((ref) async {
  final codes = await ref.watch(redeemedPromoCodesProvider.future);
  return codes.where((c) => c.isActive).toList();
});
