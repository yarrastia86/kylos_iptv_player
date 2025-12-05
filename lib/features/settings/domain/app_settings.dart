// Kylos IPTV Player - App Settings
// Domain model for application settings.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Video quality options.
enum VideoQuality {
  auto,
  quality1080p,
  quality720p,
  quality480p,
  quality360p;

  String get displayName {
    switch (this) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.quality1080p:
        return '1080p';
      case VideoQuality.quality720p:
        return '720p';
      case VideoQuality.quality480p:
        return '480p';
      case VideoQuality.quality360p:
        return '360p';
    }
  }
}

/// Buffer size options.
enum BufferSize {
  low,
  normal,
  high;

  String get displayName {
    switch (this) {
      case BufferSize.low:
        return 'Low';
      case BufferSize.normal:
        return 'Normal';
      case BufferSize.high:
        return 'High';
    }
  }

  int get durationSeconds {
    switch (this) {
      case BufferSize.low:
        return 10;
      case BufferSize.normal:
        return 30;
      case BufferSize.high:
        return 60;
    }
  }
}

/// App theme options.
enum AppThemeMode {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

/// Application settings model.
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(VideoQuality.auto) VideoQuality videoQuality,
    @Default(BufferSize.normal) BufferSize bufferSize,
    @Default(true) bool autoPlay,
    @Default(AppThemeMode.dark) AppThemeMode themeMode,
    @Default(true) bool showEpg,
    @Default(true) bool rememberLastChannel,
    @Default(1.0) double defaultPlaybackSpeed,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
