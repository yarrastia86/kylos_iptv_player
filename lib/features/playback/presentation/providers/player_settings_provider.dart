// Kylos IPTV Player - Player Settings Provider
// Riverpod provider for player settings state management.

import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playback/domain/player_settings.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Notifier for player settings state.
class PlayerSettingsNotifier extends StateNotifier<PlayerSettings> {
  PlayerSettingsNotifier() : super(const PlayerSettings()) {
    _initBrightness();
  }

  double? _originalBrightness;

  /// Initialize brightness tracking.
  Future<void> _initBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
    } catch (_) {
      // Brightness control not available
    }
  }

  /// Set volume level (0.0 to 1.0).
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  /// Increase volume by percentage.
  void increaseVolume([double amount = 0.1]) {
    setVolume(state.volume + amount);
  }

  /// Decrease volume by percentage.
  void decreaseVolume([double amount = 0.1]) {
    setVolume(state.volume - amount);
  }

  /// Toggle mute state.
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Set mute state.
  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }

  /// Set screen brightness (0.0 to 1.0).
  Future<void> setBrightness(double brightness) async {
    final clamped = brightness.clamp(0.0, 1.0);
    state = state.copyWith(brightness: clamped);
    try {
      await ScreenBrightness().setScreenBrightness(clamped);
    } catch (_) {
      // Brightness control not available
    }
  }

  /// Increase brightness.
  Future<void> increaseBrightness([double amount = 0.1]) async {
    await setBrightness(state.brightness + amount);
  }

  /// Decrease brightness.
  Future<void> decreaseBrightness([double amount = 0.1]) async {
    await setBrightness(state.brightness - amount);
  }

  /// Set video aspect ratio.
  void setAspectRatio(VideoAspectRatio ratio) {
    state = state.copyWith(aspectRatio: ratio);
  }

  /// Cycle through aspect ratios.
  void cycleAspectRatio() {
    final values = VideoAspectRatio.values;
    final currentIndex = values.indexOf(state.aspectRatio);
    final nextIndex = (currentIndex + 1) % values.length;
    state = state.copyWith(aspectRatio: values[nextIndex]);
  }

  /// Set playback speed.
  void setPlaybackSpeed(PlaybackSpeed speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Cycle through playback speeds.
  void cyclePlaybackSpeed() {
    final values = PlaybackSpeed.values;
    final currentIndex = values.indexOf(state.playbackSpeed);
    final nextIndex = (currentIndex + 1) % values.length;
    state = state.copyWith(playbackSpeed: values[nextIndex]);
  }

  /// Set subtitle style.
  void setSubtitleStyle(SubtitleStyle style) {
    state = state.copyWith(subtitleStyle: style);
  }

  /// Set subtitle font size.
  void setSubtitleFontSize(double size) {
    state = state.copyWith(
      subtitleStyle: state.subtitleStyle.copyWith(fontSize: size),
    );
  }

  /// Set subtitle font color.
  void setSubtitleFontColor(Color color) {
    state = state.copyWith(
      subtitleStyle: state.subtitleStyle.copyWith(fontColor: color),
    );
  }

  /// Set subtitle background color.
  void setSubtitleBackgroundColor(Color color) {
    state = state.copyWith(
      subtitleStyle: state.subtitleStyle.copyWith(backgroundColor: color),
    );
  }

  /// Set subtitle delay (positive = delayed, negative = early).
  void setSubtitleDelay(Duration delay) {
    state = state.copyWith(subtitleDelay: delay);
  }

  /// Increase subtitle delay (subtitles appear later).
  void increaseSubtitleDelay([Duration amount = const Duration(milliseconds: 100)]) {
    state = state.copyWith(subtitleDelay: state.subtitleDelay + amount);
  }

  /// Decrease subtitle delay (subtitles appear earlier).
  void decreaseSubtitleDelay([Duration amount = const Duration(milliseconds: 100)]) {
    state = state.copyWith(subtitleDelay: state.subtitleDelay - amount);
  }

  /// Reset subtitle delay to zero.
  void resetSubtitleDelay() {
    state = state.copyWith(subtitleDelay: Duration.zero);
  }

  /// Set audio delay.
  void setAudioDelay(Duration delay) {
    state = state.copyWith(audioDelay: delay);
  }

  /// Set auto-play preference.
  void setAutoPlay(bool autoPlay) {
    state = state.copyWith(autoPlay: autoPlay);
  }

  /// Set remember position preference.
  void setRememberPosition(bool remember) {
    state = state.copyWith(rememberPosition: remember);
  }

  /// Reset settings to defaults.
  void resetToDefaults() {
    state = const PlayerSettings();
  }

  /// Restore original brightness when leaving player.
  Future<void> restoreBrightness() async {
    if (_originalBrightness != null) {
      try {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } catch (_) {
        // Ignore
      }
    }
  }

  @override
  void dispose() {
    restoreBrightness();
    super.dispose();
  }
}

/// Provider for player settings.
final playerSettingsProvider =
    StateNotifierProvider<PlayerSettingsNotifier, PlayerSettings>((ref) {
  return PlayerSettingsNotifier();
});

/// Convenience provider for volume.
final playerVolumeProvider = Provider<double>((ref) {
  return ref.watch(playerSettingsProvider).effectiveVolume;
});

/// Convenience provider for brightness.
final playerBrightnessProvider = Provider<double>((ref) {
  return ref.watch(playerSettingsProvider).brightness;
});

/// Convenience provider for aspect ratio.
final playerAspectRatioProvider = Provider<VideoAspectRatio>((ref) {
  return ref.watch(playerSettingsProvider).aspectRatio;
});

/// Convenience provider for subtitle style.
final playerSubtitleStyleProvider = Provider<SubtitleStyle>((ref) {
  return ref.watch(playerSettingsProvider).subtitleStyle;
});

/// Convenience provider for subtitle delay.
final playerSubtitleDelayProvider = Provider<Duration>((ref) {
  return ref.watch(playerSettingsProvider).subtitleDelay;
});
