// Kylos IPTV Player - Player Settings
// Models for player settings (subtitles, aspect ratio, brightness, etc.)

import 'package:flutter/material.dart';

/// Aspect ratio options for the video player.
enum VideoAspectRatio {
  /// Fit video within bounds (letterbox/pillarbox).
  fit('Fit', null),

  /// Fill the entire screen (may crop).
  fill('Fill', null),

  /// Original aspect ratio.
  original('Original', null),

  /// 16:9 widescreen.
  ratio16x9('16:9', 16 / 9),

  /// 4:3 standard.
  ratio4x3('4:3', 4 / 3),

  /// 21:9 ultrawide.
  ratio21x9('21:9', 21 / 9),

  /// 1:1 square.
  ratio1x1('1:1', 1.0),

  /// 2.35:1 cinemascope.
  ratio235x1('2.35:1', 2.35);

  const VideoAspectRatio(this.label, this.ratio);

  final String label;
  final double? ratio;
}

/// Playback speed options.
enum PlaybackSpeed {
  x025('0.25x', 0.25),
  x050('0.5x', 0.5),
  x075('0.75x', 0.75),
  x100('1x', 1.0),
  x125('1.25x', 1.25),
  x150('1.5x', 1.5),
  x175('1.75x', 1.75),
  x200('2x', 2.0);

  const PlaybackSpeed(this.label, this.speed);

  final String label;
  final double speed;
}

/// Subtitle style configuration.
class SubtitleStyle {
  const SubtitleStyle({
    this.fontSize = 18.0,
    this.fontColor = Colors.white,
    this.backgroundColor = Colors.black54,
    this.fontWeight = FontWeight.normal,
    this.shadowEnabled = true,
    this.shadowColor = Colors.black,
    this.shadowBlurRadius = 4.0,
  });

  /// Font size in logical pixels.
  final double fontSize;

  /// Subtitle text color.
  final Color fontColor;

  /// Background color behind subtitles.
  final Color backgroundColor;

  /// Font weight.
  final FontWeight fontWeight;

  /// Whether to show shadow behind text.
  final bool shadowEnabled;

  /// Shadow color.
  final Color shadowColor;

  /// Shadow blur radius.
  final double shadowBlurRadius;

  /// Available font sizes.
  static const List<double> availableSizes = [
    12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 28.0, 32.0, 36.0, 40.0
  ];

  /// Available colors for subtitles.
  static const List<Color> availableColors = [
    Colors.white,
    Colors.yellow,
    Colors.cyan,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.pink,
    Colors.purple,
  ];

  /// Available background colors.
  static const List<Color> availableBackgrounds = [
    Colors.transparent,
    Color(0x80000000), // 50% black
    Color(0xB3000000), // 70% black
    Colors.black,
    Color(0x80FFFFFF), // 50% white
  ];

  SubtitleStyle copyWith({
    double? fontSize,
    Color? fontColor,
    Color? backgroundColor,
    FontWeight? fontWeight,
    bool? shadowEnabled,
    Color? shadowColor,
    double? shadowBlurRadius,
  }) {
    return SubtitleStyle(
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleStyle &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          fontColor == other.fontColor &&
          backgroundColor == other.backgroundColor &&
          fontWeight == other.fontWeight &&
          shadowEnabled == other.shadowEnabled;

  @override
  int get hashCode => Object.hash(
        fontSize,
        fontColor,
        backgroundColor,
        fontWeight,
        shadowEnabled,
      );
}

/// Complete player settings.
class PlayerSettings {
  const PlayerSettings({
    this.volume = 1.0,
    this.isMuted = false,
    this.brightness = 1.0,
    this.aspectRatio = VideoAspectRatio.fit,
    this.playbackSpeed = PlaybackSpeed.x100,
    this.subtitleStyle = const SubtitleStyle(),
    this.subtitleDelay = Duration.zero,
    this.audioDelay = Duration.zero,
    this.autoPlay = true,
    this.rememberPosition = true,
    this.hardwareAcceleration = true,
  });

  /// Volume level (0.0 to 1.0).
  final double volume;

  /// Whether audio is muted.
  final bool isMuted;

  /// Screen brightness (0.0 to 1.0).
  final double brightness;

  /// Video aspect ratio.
  final VideoAspectRatio aspectRatio;

  /// Playback speed.
  final PlaybackSpeed playbackSpeed;

  /// Subtitle style configuration.
  final SubtitleStyle subtitleStyle;

  /// Subtitle sync delay (positive = delayed, negative = early).
  final Duration subtitleDelay;

  /// Audio sync delay.
  final Duration audioDelay;

  /// Auto-play when content is loaded.
  final bool autoPlay;

  /// Remember playback position for VOD content.
  final bool rememberPosition;

  /// Use hardware acceleration.
  final bool hardwareAcceleration;

  /// Effective volume considering mute state.
  double get effectiveVolume => isMuted ? 0.0 : volume;

  PlayerSettings copyWith({
    double? volume,
    bool? isMuted,
    double? brightness,
    VideoAspectRatio? aspectRatio,
    PlaybackSpeed? playbackSpeed,
    SubtitleStyle? subtitleStyle,
    Duration? subtitleDelay,
    Duration? audioDelay,
    bool? autoPlay,
    bool? rememberPosition,
    bool? hardwareAcceleration,
  }) {
    return PlayerSettings(
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      brightness: brightness ?? this.brightness,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      subtitleDelay: subtitleDelay ?? this.subtitleDelay,
      audioDelay: audioDelay ?? this.audioDelay,
      autoPlay: autoPlay ?? this.autoPlay,
      rememberPosition: rememberPosition ?? this.rememberPosition,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  @override
  String toString() => 'PlayerSettings(volume: $volume, muted: $isMuted, '
      'brightness: $brightness, aspect: ${aspectRatio.label})';
}

/// Skip duration options for seek operations.
enum SkipDuration {
  s5(Duration(seconds: 5), '5s'),
  s10(Duration(seconds: 10), '10s'),
  s15(Duration(seconds: 15), '15s'),
  s30(Duration(seconds: 30), '30s'),
  s60(Duration(seconds: 60), '1m'),
  s120(Duration(seconds: 120), '2m');

  const SkipDuration(this.duration, this.label);

  final Duration duration;
  final String label;
}
