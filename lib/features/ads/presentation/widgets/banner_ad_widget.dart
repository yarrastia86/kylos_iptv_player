// Kylos IPTV Player - Banner Ad Widget
// Displays a banner ad for the ad-supported free tier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';

/// A banner ad widget that automatically loads and displays ads.
///
/// Only shows ads for free tier users on mobile platforms.
/// Automatically hides if ads are not available or user is Pro.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.placement,
    this.backgroundColor,
  });

  /// The placement identifier for this banner (for analytics).
  final String placement;

  /// Optional background color for the ad container.
  final Color? backgroundColor;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final shouldShow = ref.read(shouldShowAdsProvider);
    final supportsBanners = ref.read(supportsBannerAdsProvider);

    if (!shouldShow || !supportsBanners) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      await ref.read(loadBannerProvider)(widget.placement);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = ref.watch(shouldShowAdsProvider);
    final supportsBanners = ref.watch(supportsBannerAdsProvider);

    // Don't show anything if ads shouldn't be displayed
    if (!shouldShow || !supportsBanners || _hasError) {
      return const SizedBox.shrink();
    }

    final bannerWidget = ref.watch(bannerWidgetProvider(widget.placement));

    if (_isLoading || bannerWidget == null) {
      // Show placeholder while loading
      return Container(
        height: 50,
        color: widget.backgroundColor ?? Colors.transparent,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      color: widget.backgroundColor ?? Colors.transparent,
      child: Center(
        child: bannerWidget,
      ),
    );
  }
}

/// A convenience widget for showing a banner at the bottom of a screen.
///
/// Includes safe area padding and proper positioning.
class BottomBannerAd extends StatelessWidget {
  const BottomBannerAd({
    super.key,
    this.placement = AdPlacements.settingsBanner,
  });

  final String placement;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BannerAdWidget(
        placement: placement,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

/// A layout helper that shows content with a banner ad at the bottom.
///
/// Use this to easily add a banner to any screen.
class ScreenWithBannerAd extends ConsumerWidget {
  const ScreenWithBannerAd({
    super.key,
    required this.child,
    this.placement = AdPlacements.settingsBanner,
  });

  /// The main content of the screen.
  final Widget child;

  /// The placement identifier for the banner.
  final String placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowAdsProvider);
    final supportsBanners = ref.watch(supportsBannerAdsProvider);

    return Column(
      children: [
        Expanded(child: child),
        if (shouldShow && supportsBanners)
          BottomBannerAd(placement: placement),
      ],
    );
  }
}
