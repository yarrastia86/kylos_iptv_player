// Kylos IPTV Player - Firebase Remote Config Service
// Implementation of RemoteConfigService using Firebase Remote Config.

import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/config/remote_config_service.dart';

/// Firebase implementation of RemoteConfigService.
///
/// Provides feature flags and app configuration from Firebase Remote Config.
class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService({
    required FirebaseRemoteConfig remoteConfig,
  }) : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig _remoteConfig;
  final StreamController<AppConfig> _configController =
      StreamController<AppConfig>.broadcast();

  AppConfig? _cachedConfig;

  @override
  AppConfig get config {
    _cachedConfig ??= _buildConfig();
    return _cachedConfig!;
  }

  @override
  bool getFeatureFlag(String key) {
    return _remoteConfig.getBool(key);
  }

  @override
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  @override
  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }

  @override
  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }

  @override
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();

      if (activated) {
        _cachedConfig = null; // Clear cache
        _configController.add(config);
      }

      if (kDebugMode) {
        print('Remote Config fetch: activated=$activated');
      }

      return activated;
    } catch (e) {
      if (kDebugMode) {
        print('Remote Config fetch failed: $e');
      }
      return false;
    }
  }

  @override
  Stream<AppConfig> get configChanges => _configController.stream;

  @override
  Future<void> initialize() async {
    // Configure fetch settings
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ),
    );

    // Set default values
    await _remoteConfig.setDefaults(_defaultValues);

    // Listen for real-time updates (if supported)
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      _cachedConfig = null;
      _configController.add(config);
    }).onError((e) {
      if (kDebugMode) {
        print('Remote Config update listener error: $e');
      }
    });

    // Initial fetch (non-blocking)
    fetchAndActivate();
  }

  /// Builds AppConfig from current Remote Config values.
  AppConfig _buildConfig() {
    return AppConfig(
      minAppVersion: {
        'android': getString('min_app_version_android'),
        'ios': getString('min_app_version_ios'),
        'android_tv': getString('min_app_version_android_tv'),
      },
      forceUpdate: getBool('force_update'),
      maintenanceMode: getBool('maintenance_mode'),
      maintenanceMessage: getString('maintenance_message').isEmpty
          ? null
          : getString('maintenance_message'),
      features: FeatureFlags(
        epgEnabled: getBool('epg_enabled'),
        vodEnabled: getBool('vod_enabled'),
        seriesEnabled: getBool('series_enabled'),
        catchUpEnabled: getBool('catch_up_enabled'),
        multiAudioEnabled: getBool('multi_audio_enabled'),
        subtitlesEnabled: getBool('subtitles_enabled'),
        parentalControlsEnabled: getBool('parental_controls_enabled'),
        cloudSyncEnabled: getBool('cloud_sync_enabled'),
        newPlayerEnabled: getBool('new_player_enabled'),
      ),
    );
  }

  /// Default values for Remote Config.
  static const Map<String, dynamic> _defaultValues = {
    // App version requirements
    'min_app_version_android': '1.0.0',
    'min_app_version_ios': '1.0.0',
    'min_app_version_android_tv': '1.0.0',

    // App status
    'force_update': false,
    'maintenance_mode': false,
    'maintenance_message': '',

    // Feature flags
    'epg_enabled': true,
    'vod_enabled': true,
    'series_enabled': true,
    'catch_up_enabled': false,
    'multi_audio_enabled': true,
    'subtitles_enabled': true,
    'parental_controls_enabled': true,
    'cloud_sync_enabled': true,
    'new_player_enabled': false,
  };

  /// Disposes resources.
  void dispose() {
    _configController.close();
  }
}

/// Offline-capable wrapper for RemoteConfigService.
///
/// Returns cached/default values when Firebase is unavailable.
class OfflineRemoteConfigService implements RemoteConfigService {
  OfflineRemoteConfigService({
    RemoteConfigService? delegate,
  }) : _delegate = delegate;

  final RemoteConfigService? _delegate;
  AppConfig _fallbackConfig = AppConfig.defaults();

  @override
  AppConfig get config {
    try {
      return _delegate?.config ?? _fallbackConfig;
    } catch (_) {
      return _fallbackConfig;
    }
  }

  @override
  bool getFeatureFlag(String key) {
    try {
      return _delegate?.getFeatureFlag(key) ?? _getDefaultBool(key);
    } catch (_) {
      return _getDefaultBool(key);
    }
  }

  @override
  String getString(String key) {
    try {
      return _delegate?.getString(key) ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  int getInt(String key) {
    try {
      return _delegate?.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  double getDouble(String key) {
    try {
      return _delegate?.getDouble(key) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  bool getBool(String key) {
    try {
      return _delegate?.getBool(key) ?? _getDefaultBool(key);
    } catch (_) {
      return _getDefaultBool(key);
    }
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      return await _delegate?.fetchAndActivate() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<AppConfig> get configChanges {
    return _delegate?.configChanges ?? Stream.value(_fallbackConfig);
  }

  @override
  Future<void> initialize() async {
    try {
      await _delegate?.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Remote Config initialization failed, using defaults: $e');
      }
    }
  }

  bool _getDefaultBool(String key) {
    return switch (key) {
      'epg_enabled' => true,
      'vod_enabled' => true,
      'series_enabled' => true,
      'multi_audio_enabled' => true,
      'subtitles_enabled' => true,
      'parental_controls_enabled' => true,
      'cloud_sync_enabled' => true,
      _ => false,
    };
  }
}
