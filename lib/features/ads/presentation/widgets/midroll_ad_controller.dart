// Kylos IPTV Player - Mid-roll Ad Controller
// Manages mid-roll ads during video playback (similar to YouTube).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';

/// Controller that monitors playback position and triggers mid-roll ads.
///
/// Usage:
/// ```dart
/// MidrollAdController(
///   currentPosition: position,
///   totalDuration: duration,
///   onAdTriggered: () => pauseVideo(),
///   onAdComplete: () => resumeVideo(),
///   child: VideoPlayer(),
/// )
/// ```
class MidrollAdController extends ConsumerStatefulWidget {
  const MidrollAdController({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onAdTriggered,
    required this.onAdComplete,
    required this.child,
    this.enabled = true,
  });

  /// Current playback position in seconds.
  final Duration currentPosition;

  /// Total video duration.
  final Duration totalDuration;

  /// Called when a mid-roll ad should be shown (pause video here).
  final VoidCallback onAdTriggered;

  /// Called when the mid-roll ad completes (resume video here).
  final VoidCallback onAdComplete;

  /// The video player widget.
  final Widget child;

  /// Whether mid-roll ads are enabled.
  final bool enabled;

  @override
  ConsumerState<MidrollAdController> createState() => _MidrollAdControllerState();
}

class _MidrollAdControllerState extends ConsumerState<MidrollAdController> {
  /// Set of ad break points that have already been shown (in seconds).
  final Set<int> _shownAdBreaks = {};

  /// Whether an ad is currently being shown.
  bool _isShowingAd = false;

  /// Get the ad break points for this video.
  List<int> _getAdBreakPoints() {
    final totalSeconds = widget.totalDuration.inSeconds;

    // Don't show mid-rolls for short videos
    if (totalSeconds < AdFrequencyCaps.midrollMinVideoDurationSeconds) {
      return [];
    }

    final breakPoints = <int>[];
    final interval = AdFrequencyCaps.midrollIntervalSeconds;

    // Generate break points at regular intervals
    // Start from first interval, not from 0 (pre-roll handles that)
    for (int i = interval; i < totalSeconds - 30; i += interval) {
      breakPoints.add(i);
    }

    return breakPoints;
  }

  void _checkForMidrollAd() {
    if (!widget.enabled || _isShowingAd) return;

    final shouldShowAds = ref.read(shouldShowAdsProvider);
    if (!shouldShowAds) return;

    final currentSeconds = widget.currentPosition.inSeconds;
    final breakPoints = _getAdBreakPoints();

    for (final breakPoint in breakPoints) {
      // Check if we've reached this break point (within 2 second window)
      if (currentSeconds >= breakPoint &&
          currentSeconds <= breakPoint + 2 &&
          !_shownAdBreaks.contains(breakPoint)) {
        _triggerMidrollAd(breakPoint);
        break;
      }
    }
  }

  Future<void> _triggerMidrollAd(int breakPoint) async {
    setState(() {
      _isShowingAd = true;
      _shownAdBreaks.add(breakPoint);
    });

    // Pause the video
    widget.onAdTriggered();

    // Show the interstitial ad
    final adController = ref.read(adControllerProvider.notifier);
    await adController.showInterstitialIfAllowed(
      placement: AdPlacements.midrollVideo,
      customMinIntervalSeconds: 0, // No minimum for mid-rolls
    );

    // Resume playback
    setState(() {
      _isShowingAd = false;
    });
    widget.onAdComplete();
  }

  @override
  void didUpdateWidget(MidrollAdController oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for mid-roll when position changes
    if (widget.currentPosition != oldWidget.currentPosition) {
      _checkForMidrollAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show ad overlay when mid-roll is playing
    if (_isShowingAd) {
      return Stack(
        children: [
          widget.child,
          const _MidrollAdOverlay(),
        ],
      );
    }

    return widget.child;
  }
}

/// Overlay shown during mid-roll ad loading.
class _MidrollAdOverlay extends StatelessWidget {
  const _MidrollAdOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Ad break',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Video will resume after the ad',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider to track mid-roll ad state for the current video.
class MidrollAdState {
  const MidrollAdState({
    this.shownBreakPoints = const {},
    this.isShowingAd = false,
    this.lastAdTime,
  });

  final Set<int> shownBreakPoints;
  final bool isShowingAd;
  final DateTime? lastAdTime;

  MidrollAdState copyWith({
    Set<int>? shownBreakPoints,
    bool? isShowingAd,
    DateTime? lastAdTime,
  }) {
    return MidrollAdState(
      shownBreakPoints: shownBreakPoints ?? this.shownBreakPoints,
      isShowingAd: isShowingAd ?? this.isShowingAd,
      lastAdTime: lastAdTime ?? this.lastAdTime,
    );
  }
}

/// Notifier to manage mid-roll ad state.
class MidrollAdNotifier extends StateNotifier<MidrollAdState> {
  MidrollAdNotifier() : super(const MidrollAdState());

  void markBreakPointShown(int breakPoint) {
    state = state.copyWith(
      shownBreakPoints: {...state.shownBreakPoints, breakPoint},
      lastAdTime: DateTime.now(),
    );
  }

  void setShowingAd(bool showing) {
    state = state.copyWith(isShowingAd: showing);
  }

  void resetForNewVideo() {
    state = const MidrollAdState();
  }
}

/// Provider for mid-roll ad state.
final midrollAdProvider = StateNotifierProvider<MidrollAdNotifier, MidrollAdState>(
  (ref) => MidrollAdNotifier(),
);
