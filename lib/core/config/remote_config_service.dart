// Kylos IPTV Player - Remote Config Service Interface
// Domain layer interface for feature flags and remote configuration.

/// Remote configuration values for the app.
class AppConfig {
  const AppConfig({
    required this.minAppVersion,
    required this.forceUpdate,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.features,
  });

  /// Minimum supported app version per platform.
  final Map<String, String> minAppVersion;

  /// Whether to force update for outdated versions.
  final bool forceUpdate;

  /// Whether the app is in maintenance mode.
  final bool maintenanceMode;

  /// Message to show during maintenance.
  final String? maintenanceMessage;

  /// Feature flags.
  final FeatureFlags features;

  /// Default configuration.
  factory AppConfig.defaults() {
    return AppConfig(
      minAppVersion: {
        'android': '1.0.0',
        'ios': '1.0.0',
        'android_tv': '1.0.0',
      },
      forceUpdate: false,
      maintenanceMode: false,
      maintenanceMessage: null,
      features: FeatureFlags.defaults(),
    );
  }
}

/// Feature flags for A/B testing and gradual rollouts.
class FeatureFlags {
  const FeatureFlags({
    required this.epgEnabled,
    required this.vodEnabled,
    required this.seriesEnabled,
    required this.catchUpEnabled,
    required this.multiAudioEnabled,
    required this.subtitlesEnabled,
    required this.parentalControlsEnabled,
    required this.cloudSyncEnabled,
    required this.newPlayerEnabled,
  });

  final bool epgEnabled;
  final bool vodEnabled;
  final bool seriesEnabled;
  final bool catchUpEnabled;
  final bool multiAudioEnabled;
  final bool subtitlesEnabled;
  final bool parentalControlsEnabled;
  final bool cloudSyncEnabled;
  final bool newPlayerEnabled;

  factory FeatureFlags.defaults() {
    return const FeatureFlags(
      epgEnabled: true,
      vodEnabled: true,
      seriesEnabled: true,
      catchUpEnabled: false,
      multiAudioEnabled: true,
      subtitlesEnabled: true,
      parentalControlsEnabled: true,
      cloudSyncEnabled: true,
      newPlayerEnabled: false,
    );
  }

  FeatureFlags copyWith({
    bool? epgEnabled,
    bool? vodEnabled,
    bool? seriesEnabled,
    bool? catchUpEnabled,
    bool? multiAudioEnabled,
    bool? subtitlesEnabled,
    bool? parentalControlsEnabled,
    bool? cloudSyncEnabled,
    bool? newPlayerEnabled,
  }) {
    return FeatureFlags(
      epgEnabled: epgEnabled ?? this.epgEnabled,
      vodEnabled: vodEnabled ?? this.vodEnabled,
      seriesEnabled: seriesEnabled ?? this.seriesEnabled,
      catchUpEnabled: catchUpEnabled ?? this.catchUpEnabled,
      multiAudioEnabled: multiAudioEnabled ?? this.multiAudioEnabled,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      parentalControlsEnabled:
          parentalControlsEnabled ?? this.parentalControlsEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      newPlayerEnabled: newPlayerEnabled ?? this.newPlayerEnabled,
    );
  }
}

/// Remote configuration service interface.
///
/// Provides feature flags and app configuration from Firebase Remote Config.
abstract class RemoteConfigService {
  /// Gets the current app configuration.
  AppConfig get config;

  /// Gets a specific feature flag value.
  bool getFeatureFlag(String key);

  /// Gets a string configuration value.
  String getString(String key);

  /// Gets an integer configuration value.
  int getInt(String key);

  /// Gets a double configuration value.
  double getDouble(String key);

  /// Gets a boolean configuration value.
  bool getBool(String key);

  /// Fetches and activates the latest configuration.
  ///
  /// Returns true if new values were activated.
  Future<bool> fetchAndActivate();

  /// Stream of configuration changes.
  Stream<AppConfig> get configChanges;

  /// Initializes the service with default values.
  Future<void> initialize();
}
