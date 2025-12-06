// Kylos IPTV Player - Pre-roll Ad Overlay
// Shows an ad before video playback starts.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// Pre-roll ad state
enum PrerollAdState {
  /// Checking if ad should be shown
  checking,

  /// Loading the ad
  loading,

  /// Showing the ad
  showing,

  /// Ad completed or skipped
  completed,

  /// Ad failed or not available
  failed,
}

/// Overlay that shows a pre-roll ad before video playback.
///
/// Use this widget to wrap your player screen or show it
/// as an overlay before starting playback.
class PrerollAdOverlay extends ConsumerStatefulWidget {
  const PrerollAdOverlay({
    super.key,
    required this.onAdComplete,
    this.onAdSkipped,
    this.contentTitle,
    this.contentPoster,
    this.skipDelay = const Duration(seconds: 5),
  });

  /// Called when the ad completes (or is skipped/fails).
  final VoidCallback onAdComplete;

  /// Called specifically when user skips the ad (optional).
  final VoidCallback? onAdSkipped;

  /// Title of the content about to play (for display).
  final String? contentTitle;

  /// Poster URL for the content (for display).
  final String? contentPoster;

  /// Delay before showing skip button.
  final Duration skipDelay;

  @override
  ConsumerState<PrerollAdOverlay> createState() => _PrerollAdOverlayState();
}

class _PrerollAdOverlayState extends ConsumerState<PrerollAdOverlay> {
  PrerollAdState _state = PrerollAdState.checking;
  Timer? _skipTimer;
  int _skipCountdown = 5;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowAd();
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowAd() async {
    final shouldShow = ref.read(shouldShowAdsProvider);

    if (!shouldShow) {
      // Pro user or ads not available - skip directly
      setState(() => _state = PrerollAdState.completed);
      widget.onAdComplete();
      return;
    }

    // Show loading state
    setState(() => _state = PrerollAdState.loading);

    // Start skip countdown
    _startSkipCountdown();

    // Attempt to show interstitial as pre-roll
    final controller = ref.read(adControllerProvider.notifier);

    // Give some time for ad to load if not ready
    if (!controller.adService.isInterstitialReady()) {
      await controller.preloadInterstitial();
      // Wait a bit for load
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    // Check again if ad is ready
    if (controller.adService.isInterstitialReady()) {
      setState(() => _state = PrerollAdState.showing);

      final result = await controller.showInterstitialIfAllowed(
        placement: AdPlacements.prerollVideo,
        customMinIntervalSeconds: 0, // Always show pre-roll if available
      );

      if (!mounted) return;

      // Ad shown or skipped
      setState(() => _state = PrerollAdState.completed);
      widget.onAdComplete();
    } else {
      // No ad available
      setState(() => _state = PrerollAdState.failed);
      widget.onAdComplete();
    }
  }

  void _startSkipCountdown() {
    _skipCountdown = widget.skipDelay.inSeconds;
    _skipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _skipCountdown--;
        if (_skipCountdown <= 0) {
          _canSkip = true;
          timer.cancel();
        }
      });
    });
  }

  void _skipAd() {
    _skipTimer?.cancel();
    setState(() => _state = PrerollAdState.completed);
    widget.onAdSkipped?.call();
    widget.onAdComplete();
  }

  @override
  Widget build(BuildContext context) {
    // If completed or failed, don't show anything
    if (_state == PrerollAdState.completed || _state == PrerollAdState.failed) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background with content preview
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Content poster placeholder
                if (widget.contentPoster != null)
                  Opacity(
                    opacity: 0.3,
                    child: Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(KylosRadius.m),
                        color: KylosColors.surfaceDark,
                      ),
                    ),
                  ),
                const SizedBox(height: KylosSpacing.m),
                // Content title
                if (widget.contentTitle != null)
                  Text(
                    widget.contentTitle!,
                    style: KylosTvTextStyles.sectionHeader.copyWith(
                      color: KylosColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          // Loading indicator or ad message
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_state == PrerollAdState.loading ||
                    _state == PrerollAdState.checking)
                  const CircularProgressIndicator(
                    color: KylosColors.tvAccent,
                  ),
                const SizedBox(height: KylosSpacing.m),
                Text(
                  _state == PrerollAdState.loading
                      ? 'Loading ad...'
                      : _state == PrerollAdState.showing
                          ? 'Advertisement'
                          : 'Preparing...',
                  style: KylosTvTextStyles.body.copyWith(
                    color: KylosColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Skip button
          Positioned(
            bottom: KylosSpacing.xl,
            right: KylosSpacing.xl,
            child: _buildSkipButton(),
          ),

          // "Your video will play after the ad" message
          Positioned(
            bottom: KylosSpacing.xl,
            left: KylosSpacing.xl,
            child: Text(
              'Your video will play shortly',
              style: KylosTvTextStyles.cardSubtitle.copyWith(
                color: KylosColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    if (_canSkip) {
      return TextButton.icon(
        onPressed: _skipAd,
        icon: const Icon(Icons.skip_next, color: Colors.white),
        label: const Text(
          'Skip Ad',
          style: TextStyle(color: Colors.white),
        ),
        style: TextButton.styleFrom(
          backgroundColor: KylosColors.surfaceLight,
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.m,
            vertical: KylosSpacing.s,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.m,
        vertical: KylosSpacing.s,
      ),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.s),
      ),
      child: Text(
        'Skip in $_skipCountdown',
        style: KylosTvTextStyles.cardSubtitle.copyWith(
          color: KylosColors.textSecondary,
        ),
      ),
    );
  }
}

/// A provider that manages pre-roll ad state for the player.
///
/// Use this to check if a pre-roll should be shown and track completion.
final prerollAdStateProvider = StateProvider<PrerollAdState>((ref) {
  return PrerollAdState.checking;
});

/// Check if pre-roll ad should be shown for this playback.
final shouldShowPrerollProvider = Provider<bool>((ref) {
  final shouldShowAds = ref.watch(shouldShowAdsProvider);
  // Could add more conditions here (e.g., only for certain content types)
  return shouldShowAds;
});
