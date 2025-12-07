// Kylos IPTV Player - Device Presence Entity
// Represents an online device that can receive playback handoff.

import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';

/// Capabilities a device can have for handoff.
enum DeviceCapability {
  /// Can play content
  playback,

  /// Can receive handoff from another device
  receiveHandoff,

  /// Can send handoff to another device
  sendHandoff,

  /// Supports casting protocols (Chromecast, AirPlay)
  casting,
}

/// Current playback information for a device.
class CurrentPlayback {
  const CurrentPlayback({
    required this.contentId,
    required this.title,
    required this.type,
    required this.position,
    this.duration,
    this.posterUrl,
  });

  final String contentId;
  final String title;
  final ContentType type;
  final Duration position;
  final Duration? duration;
  final String? posterUrl;

  /// Progress as a value between 0.0 and 1.0.
  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'title': title,
        'type': type.name,
        'position': position.inMilliseconds,
        'duration': duration?.inMilliseconds,
        'posterUrl': posterUrl,
      };

  factory CurrentPlayback.fromJson(Map<String, dynamic> json) {
    return CurrentPlayback(
      contentId: json['contentId'] as String,
      title: json['title'] as String,
      type: ContentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ContentType.vod,
      ),
      position: Duration(milliseconds: json['position'] as int? ?? 0),
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      posterUrl: json['posterUrl'] as String?,
    );
  }

  factory CurrentPlayback.fromPlaybackState(PlaybackState state) {
    return CurrentPlayback(
      contentId: state.content!.id,
      title: state.content!.title,
      type: state.content!.type,
      position: state.position ?? Duration.zero,
      duration: state.duration,
      posterUrl: state.content!.logoUrl,
    );
  }
}

/// Represents an online device available for handoff.
class DevicePresence {
  const DevicePresence({
    required this.deviceId,
    required this.userId,
    required this.deviceName,
    required this.platform,
    required this.formFactor,
    required this.isOnline,
    required this.lastSeen,
    required this.capabilities,
    this.appVersion,
    this.currentContent,
    this.fcmToken,
    this.isCurrentDevice = false,
  });

  final String deviceId;
  final String userId;
  final String deviceName;
  final DevicePlatform platform;
  final DeviceFormFactor formFactor;
  final bool isOnline;
  final DateTime lastSeen;
  final List<DeviceCapability> capabilities;
  final String? appVersion;
  final CurrentPlayback? currentContent;
  final String? fcmToken;
  final bool isCurrentDevice;

  /// Whether this device can receive handoff requests.
  bool get canReceiveHandoff =>
      capabilities.contains(DeviceCapability.receiveHandoff) && isOnline;

  /// Whether this device can send handoff requests.
  bool get canSendHandoff =>
      capabilities.contains(DeviceCapability.sendHandoff);

  /// Whether this device is currently playing content.
  bool get isPlaying => currentContent != null;

  /// Whether this device was active recently (within last 2 minutes).
  bool get isRecentlyActive =>
      DateTime.now().difference(lastSeen).inMinutes < 2;

  /// Icon for this device type.
  String get iconName {
    switch (formFactor) {
      case DeviceFormFactor.tv:
        return 'tv';
      case DeviceFormFactor.tablet:
        return 'tablet';
      case DeviceFormFactor.phone:
        return 'phone_android';
      case DeviceFormFactor.desktop:
        return 'computer';
      case DeviceFormFactor.web:
        return 'web';
      case DeviceFormFactor.car:
        return 'directions_car';
      case DeviceFormFactor.unknown:
        return 'devices';
    }
  }

  /// Creates a presence with default capabilities based on platform.
  factory DevicePresence.create({
    required String deviceId,
    required String userId,
    required String deviceName,
    required DevicePlatform platform,
    required DeviceFormFactor formFactor,
    String? appVersion,
    String? fcmToken,
    bool isCurrentDevice = false,
  }) {
    // All devices can playback and receive/send handoff
    final capabilities = [
      DeviceCapability.playback,
      DeviceCapability.receiveHandoff,
      DeviceCapability.sendHandoff,
    ];

    // Add casting capability for mobile devices
    if (formFactor == DeviceFormFactor.phone ||
        formFactor == DeviceFormFactor.tablet) {
      capabilities.add(DeviceCapability.casting);
    }

    return DevicePresence(
      deviceId: deviceId,
      userId: userId,
      deviceName: deviceName,
      platform: platform,
      formFactor: formFactor,
      isOnline: true,
      lastSeen: DateTime.now(),
      capabilities: capabilities,
      appVersion: appVersion,
      fcmToken: fcmToken,
      isCurrentDevice: isCurrentDevice,
    );
  }

  DevicePresence copyWith({
    String? deviceId,
    String? userId,
    String? deviceName,
    DevicePlatform? platform,
    DeviceFormFactor? formFactor,
    bool? isOnline,
    DateTime? lastSeen,
    List<DeviceCapability>? capabilities,
    String? appVersion,
    CurrentPlayback? currentContent,
    String? fcmToken,
    bool? isCurrentDevice,
  }) {
    return DevicePresence(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      formFactor: formFactor ?? this.formFactor,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      capabilities: capabilities ?? this.capabilities,
      appVersion: appVersion ?? this.appVersion,
      currentContent: currentContent ?? this.currentContent,
      fcmToken: fcmToken ?? this.fcmToken,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'userId': userId,
        'deviceName': deviceName,
        'platform': platform.name,
        'formFactor': formFactor.name,
        'online': isOnline,
        'lastSeen': lastSeen.millisecondsSinceEpoch,
        'capabilities': capabilities.map((c) => c.name).toList(),
        'appVersion': appVersion,
        'currentContent': currentContent?.toJson(),
        'fcmToken': fcmToken,
      };

  factory DevicePresence.fromJson(String deviceId, Map<dynamic, dynamic> json) {
    return DevicePresence(
      deviceId: deviceId,
      userId: json['userId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      platform: DevicePlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => DevicePlatform.unknown,
      ),
      formFactor: DeviceFormFactor.values.firstWhere(
        (f) => f.name == json['formFactor'],
        orElse: () => DeviceFormFactor.unknown,
      ),
      isOnline: json['online'] as bool? ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        json['lastSeen'] as int? ?? 0,
      ),
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((c) => DeviceCapability.values.firstWhere(
                    (cap) => cap.name == c,
                    orElse: () => DeviceCapability.playback,
                  ))
              .toList() ??
          [DeviceCapability.playback],
      appVersion: json['appVersion'] as String?,
      currentContent: json['currentContent'] != null
          ? CurrentPlayback.fromJson(
              Map<String, dynamic>.from(json['currentContent'] as Map),
            )
          : null,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicePresence &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}
