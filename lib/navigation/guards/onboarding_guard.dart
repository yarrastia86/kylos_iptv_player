// Kylos IPTV Player - Onboarding Guard
// Guard to check if user has completed onboarding.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';

/// Provider for the onboarding guard.
///
/// Checks if the user has completed the initial onboarding flow
/// (added at least one playlist).
final onboardingGuardProvider = Provider<OnboardingGuard>((ref) {
  // Onboarding is complete if user has at least one playlist
  final hasPlaylists = ref.watch(hasPlaylistsProvider);
  return OnboardingGuard(isComplete: hasPlaylists);
});

/// Guard to check onboarding completion status.
class OnboardingGuard {
  const OnboardingGuard({required this.isComplete});

  /// Whether the user has completed onboarding.
  final bool isComplete;
}
