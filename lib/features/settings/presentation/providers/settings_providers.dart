// Kylos IPTV Player - Settings Providers
// Riverpod providers for app settings state management.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/settings/domain/app_settings.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:kylos_iptv_player/infrastructure/providers/infrastructure_providers.dart';

/// Storage key for app settings.
const _settingsStorageKey = 'app_settings';

/// Notifier for managing app settings.
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._storage) : super(const AppSettings()) {
    _loadSettings();
  }

  final LocalStorage _storage;

  void _loadSettings() {
    try {
      final jsonString = _storage.getString(_settingsStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
        debugPrint('[AppSettingsNotifier] Loaded settings');
      }
    } catch (e) {
      debugPrint('[AppSettingsNotifier] Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final jsonString = jsonEncode(state.toJson());
      await _storage.setString(_settingsStorageKey, jsonString);
      debugPrint('[AppSettingsNotifier] Saved settings');
    } catch (e) {
      debugPrint('[AppSettingsNotifier] Error saving settings: $e');
    }
  }

  /// Updates video quality setting.
  void setVideoQuality(VideoQuality quality) {
    state = state.copyWith(videoQuality: quality);
    _saveSettings();
  }

  /// Updates buffer size setting.
  void setBufferSize(BufferSize size) {
    state = state.copyWith(bufferSize: size);
    _saveSettings();
  }

  /// Updates auto play setting.
  void setAutoPlay(bool enabled) {
    state = state.copyWith(autoPlay: enabled);
    _saveSettings();
  }

  /// Updates theme mode setting.
  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  /// Updates show EPG setting.
  void setShowEpg(bool enabled) {
    state = state.copyWith(showEpg: enabled);
    _saveSettings();
  }

  /// Updates remember last channel setting.
  void setRememberLastChannel(bool enabled) {
    state = state.copyWith(rememberLastChannel: enabled);
    _saveSettings();
  }

  /// Updates default playback speed.
  void setDefaultPlaybackSpeed(double speed) {
    state = state.copyWith(defaultPlaybackSpeed: speed);
    _saveSettings();
  }

  /// Resets all settings to defaults.
  void resetToDefaults() {
    state = const AppSettings();
    _saveSettings();
  }
}

/// Provider for app settings notifier.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(localStorageProvider);
  return AppSettingsNotifier(storage);
});

/// Convenience provider for video quality.
final videoQualityProvider = Provider<VideoQuality>((ref) {
  return ref.watch(appSettingsProvider).videoQuality;
});

/// Convenience provider for buffer size.
final bufferSizeProvider = Provider<BufferSize>((ref) {
  return ref.watch(appSettingsProvider).bufferSize;
});

/// Convenience provider for auto play.
final autoPlayProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).autoPlay;
});

/// Convenience provider for theme mode.
final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(appSettingsProvider).themeMode;
});
