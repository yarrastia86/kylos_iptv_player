// Kylos IPTV Player - Fullscreen Player Screen
// Fullscreen video player with advanced controls.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/interstitial_ad_mixin.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/preroll_ad_overlay.dart';
import 'package:kylos_iptv_player/features/playback/domain/player_settings.dart';
import 'package:kylos_iptv_player/features/playback/presentation/providers/player_settings_provider.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/advanced_player_controls.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_error_view.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_loading_view.dart';

/// Fullscreen player screen with advanced controls.
///
/// Features:
/// - Volume and brightness gestures
/// - Seekable progress bar
/// - Skip forward/backward (10s, 30s)
/// - Playback speed control
/// - Aspect ratio selection
/// - Subtitle customization (track, color, size, sync)
/// - Audio track selection
/// - Screen lock
class FullscreenPlayerScreen extends ConsumerStatefulWidget {
  const FullscreenPlayerScreen({super.key});

  @override
  ConsumerState<FullscreenPlayerScreen> createState() =>
      _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends ConsumerState<FullscreenPlayerScreen>
    with InterstitialAdMixin {
  bool _showPrerollAd = true;
  bool _prerollCompleted = false;

  @override
  void initState() {
    super.initState();
    // Set landscape orientation for fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Check if user is Pro (no ads)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldShowAds = ref.read(shouldShowAdsProvider);
      if (!shouldShowAds) {
        setState(() {
          _showPrerollAd = false;
          _prerollCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handlePrerollComplete() {
    setState(() {
      _showPrerollAd = false;
      _prerollCompleted = true;
    });
  }

  Future<void> _handleBack() async {
    // Stop playback before navigating away
    ref.read(playbackNotifierProvider.notifier).stop();
    // Restore brightness before navigating away
    ref.read(playerSettingsProvider.notifier).restoreBrightness();

    // Show interstitial ad when exiting player (for free users)
    await showInterstitialAfterPlayer();

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final videoController = ref.watch(videoControllerProvider);
    final settings = ref.watch(playerSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer with aspect ratio support
          _buildVideoLayer(videoController, settings),

          // Loading indicator (only show if preroll completed)
          if (_prerollCompleted) _buildLoadingLayer(playbackState),

          // Error view
          _buildErrorLayer(playbackState),

          // Advanced controls overlay (only show if preroll completed)
          if (_prerollCompleted)
            AdvancedPlayerControls(
              onBack: _handleBack,
              autoHide: true,
              hideDelay: const Duration(seconds: 4),
            ),

          // Pre-roll ad overlay (shown before content plays)
          if (_showPrerollAd)
            PrerollAdOverlay(
              onAdComplete: _handlePrerollComplete,
              onAdSkipped: _handlePrerollComplete,
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer(VideoController? controller, PlayerSettings settings) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    // Determine the BoxFit based on aspect ratio setting
    BoxFit fit;
    double? aspectRatio;

    switch (settings.aspectRatio) {
      case VideoAspectRatio.fit:
        fit = BoxFit.contain;
        aspectRatio = null;
        break;
      case VideoAspectRatio.fill:
        fit = BoxFit.cover;
        aspectRatio = null;
        break;
      case VideoAspectRatio.original:
        fit = BoxFit.contain;
        aspectRatio = null;
        break;
      case VideoAspectRatio.ratio16x9:
      case VideoAspectRatio.ratio4x3:
      case VideoAspectRatio.ratio21x9:
      case VideoAspectRatio.ratio1x1:
      case VideoAspectRatio.ratio235x1:
        fit = BoxFit.contain;
        aspectRatio = settings.aspectRatio.ratio;
        break;
    }

    Widget videoWidget = Video(
      controller: controller,
      fit: fit,
      controls: (state) => const SizedBox.shrink(),
    );

    // Apply custom aspect ratio if set
    if (aspectRatio != null) {
      videoWidget = Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: videoWidget,
        ),
      );
    }

    return videoWidget;
  }

  Widget _buildLoadingLayer(PlaybackState state) {
    final status = state.status;
    final isLoading = status == PlaybackStatus.loading ||
        status == PlaybackStatus.buffering;

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return PlayerLoadingView(
      message: status == PlaybackStatus.loading ? 'Loading...' : 'Buffering...',
      channelName: state.content?.title,
      channelLogo: state.content?.logoUrl,
    );
  }

  Widget _buildErrorLayer(PlaybackState state) {
    if (state.status != PlaybackStatus.error) {
      return const SizedBox.shrink();
    }

    final error = state.error;
    return PlayerErrorView(
      message: error?.message ?? 'An error occurred',
      isRecoverable: error?.isRecoverable ?? true,
      onRetry: () => ref.read(playbackNotifierProvider.notifier).retry(),
      onBack: _handleBack,
    );
  }
}
