// Kylos IPTV Player - Fullscreen Player Screen
// Fullscreen video player with advanced controls and aggressive ad monetization.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_providers.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/interstitial_ad_mixin.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/midroll_ad_controller.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/preroll_ad_overlay.dart';
import 'package:kylos_iptv_player/features/playback/domain/player_settings.dart';
import 'package:kylos_iptv_player/features/playback/presentation/providers/player_settings_provider.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/widgets/incoming_handoff_dialog.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/advanced_player_controls.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_error_view.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/player_loading_view.dart';
import 'package:kylos_iptv_player/features/playback/presentation/widgets/stream_limit_dialog.dart';

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
    with InterstitialAdMixin, WidgetsBindingObserver {
  bool _showPrerollAd = true;
  bool _prerollCompleted = false;
  String? _lastContentId;
  bool _isMidrollAdShowing = false;
  bool _streamLimitExceeded = false;
  bool _isCheckingStreamLimit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set landscape orientation for fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize device registration and stream session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStreamSession();

      // Check if user is Pro (no ads)
      final shouldShowAds = ref.read(shouldShowAdsProvider);
      if (!shouldShowAds) {
        setState(() {
          _showPrerollAd = false;
          _prerollCompleted = true;
        });
      }
    });
  }

  int _retryCount = 0;
  static const int _maxRetries = 2;

  Future<void> _initializeStreamSession() async {
    try {
      // First, ensure device is registered
      final regResult = await ref.read(deviceManagerProvider.notifier).registerCurrentDevice();

      // If registration failed with error, allow playback anyway (graceful degradation)
      if (regResult is DeviceRegistrationError) {
        debugPrint('Device registration error: ${regResult.message}');
        // Allow playback without multi-device tracking
        if (mounted) {
          setState(() {
            _isCheckingStreamLimit = false;
          });
        }
        return;
      }

      // Then start stream session
      final playbackState = ref.read(playbackNotifierProvider);
      final content = playbackState.content;

      final result = await ref.read(streamSessionManagerProvider.notifier).startStream(
        contentId: content?.id,
        contentTitle: content?.title,
        contentType: content?.type.name,
      );

      if (!mounted) return;

      if (result is StreamLimitExceeded) {
        // Show limit exceeded dialog
        final shouldContinue = await StreamLimitDialog.show(
          context,
          maxStreams: result.maxStreams,
          activeSessions: result.activeSessions,
        );

        if (shouldContinue && mounted) {
          // Retry starting stream
          _retryCount = 0;
          await _initializeStreamSession();
        } else if (mounted) {
          setState(() {
            _streamLimitExceeded = true;
            _isCheckingStreamLimit = false;
          });
        }
      } else if (result is StreamDeviceNotRegistered) {
        // Device not registered, try again (with retry limit)
        _retryCount++;
        if (_retryCount < _maxRetries && mounted) {
          await ref.read(deviceManagerProvider.notifier).registerCurrentDevice();
          await _initializeStreamSession();
        } else if (mounted) {
          // Allow playback without stream tracking after max retries
          setState(() {
            _isCheckingStreamLimit = false;
          });
        }
      } else if (result is StreamStartError) {
        // On error, allow playback anyway (graceful degradation)
        debugPrint('Stream session error: ${result.message}');
        if (mounted) {
          setState(() {
            _isCheckingStreamLimit = false;
          });
        }
      } else {
        setState(() {
          _isCheckingStreamLimit = false;
        });
      }
    } catch (e) {
      // On any exception, allow playback (graceful degradation)
      debugPrint('Stream session initialization error: $e');
      if (mounted) {
        setState(() {
          _isCheckingStreamLimit = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle for stream session
    if (state == AppLifecycleState.paused) {
      ref.read(streamSessionManagerProvider.notifier).pauseSession();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(streamSessionManagerProvider.notifier).resumeSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // End stream session
    ref.read(streamSessionManagerProvider.notifier).endSession();

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

  void _checkForNewContent(PlaybackState playbackState) {
    final currentContentId = playbackState.content?.id;

    // If content changed, reset pre-roll state to show ad for new video
    if (currentContentId != null && currentContentId != _lastContentId) {
      _lastContentId = currentContentId;

      // Check if we should show ads
      final shouldShowAds = ref.read(shouldShowAdsProvider);
      if (shouldShowAds) {
        setState(() {
          _showPrerollAd = true;
          _prerollCompleted = false;
        });
        // Reset mid-roll state for new video
        ref.read(midrollAdProvider.notifier).resetForNewVideo();
      }
    }
  }

  void _onMidrollAdTriggered() {
    setState(() {
      _isMidrollAdShowing = true;
    });
    // Pause the video
    ref.read(playbackNotifierProvider.notifier).pause();
  }

  void _onMidrollAdComplete() {
    setState(() {
      _isMidrollAdShowing = false;
    });
    // Resume the video
    ref.read(playbackNotifierProvider.notifier).resume();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final videoController = ref.watch(videoControllerProvider);
    final settings = ref.watch(playerSettingsProvider);
    final maxStreams = ref.watch(maxConcurrentStreamsProvider);

    // Check if content changed to show pre-roll for every video
    _checkForNewContent(playbackState);

    // Show stream limit overlay if exceeded
    if (_streamLimitExceeded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: StreamLimitOverlay(
          maxStreams: maxStreams,
          onManageDevices: () {
            // Navigate to device management
            context.pop();
            // TODO: Navigate to device management screen
          },
          onUpgrade: () {
            // Navigate to paywall
            context.pop();
            // TODO: Navigate to paywall
          },
          onBack: () => context.pop(),
        ),
      );
    }

    // Show loading while checking stream limit
    if (_isCheckingStreamLimit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Checking stream availability...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: IncomingHandoffListener(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Video layer with aspect ratio support and mid-roll ads
              _buildVideoLayerWithMidroll(videoController, settings, playbackState),

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
        ),
      ),
    );
  }

  Widget _buildVideoLayerWithMidroll(
    VideoController? controller,
    PlayerSettings settings,
    PlaybackState playbackState,
  ) {
    final videoWidget = _buildVideoLayer(controller, settings);

    // Only wrap with mid-roll controller for VOD content (not live)
    // and when pre-roll is completed
    if (!_prerollCompleted ||
        playbackState.isLive ||
        playbackState.position == null ||
        playbackState.duration == null) {
      return videoWidget;
    }

    final shouldShowAds = ref.watch(shouldShowAdsProvider);
    if (!shouldShowAds) {
      return videoWidget;
    }

    return MidrollAdController(
      currentPosition: playbackState.position!,
      totalDuration: playbackState.duration!,
      onAdTriggered: _onMidrollAdTriggered,
      onAdComplete: _onMidrollAdComplete,
      enabled: !_isMidrollAdShowing, // Prevent recursive triggers
      child: videoWidget,
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
