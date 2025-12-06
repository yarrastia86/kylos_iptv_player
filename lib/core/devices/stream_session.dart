// Kylos IPTV Player - Stream Session
// Represents an active streaming session for concurrent stream management.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';

/// Status of a streaming session.
enum StreamSessionStatus {
  /// Session is active and streaming.
  active,

  /// Session is paused (app backgrounded).
  paused,

  /// Session ended normally.
  ended,

  /// Session was terminated by server (limit exceeded).
  terminated,

  /// Session expired due to inactivity.
  expired,
}

/// Represents an active streaming session.
///
/// Used to track concurrent streams per user and enforce screen limits
/// based on subscription tier.
class StreamSession {
  const StreamSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.devicePlatform,
    required this.startedAt,
    required this.lastHeartbeatAt,
    this.endedAt,
    required this.status,
    this.contentId,
    this.contentTitle,
    this.contentType,
  });

  /// Unique session identifier.
  final String id;

  /// User who started the session.
  final String userId;

  /// Device where the session is active.
  final String deviceId;

  /// Device name for display.
  final String deviceName;

  /// Device platform.
  final DevicePlatform devicePlatform;

  /// When the stream started.
  final DateTime startedAt;

  /// Last heartbeat from the client (for activity tracking).
  final DateTime lastHeartbeatAt;

  /// When the stream ended (null if still active).
  final DateTime? endedAt;

  /// Current session status.
  final StreamSessionStatus status;

  /// ID of the content being streamed.
  final String? contentId;

  /// Title of the content being streamed.
  final String? contentTitle;

  /// Type of content (live, vod, series).
  final String? contentType;

  /// Whether this session is currently active.
  bool get isActive => status == StreamSessionStatus.active;

  /// Whether this session is paused (can be resumed).
  bool get isPaused => status == StreamSessionStatus.paused;

  /// Whether this session has ended.
  bool get hasEnded =>
      status == StreamSessionStatus.ended ||
      status == StreamSessionStatus.terminated ||
      status == StreamSessionStatus.expired;

  /// Duration of the session.
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Whether the session is stale (no heartbeat for > 2 minutes).
  bool get isStale {
    return DateTime.now().difference(lastHeartbeatAt).inMinutes > 2;
  }

  /// Display text for the session.
  String get displayText {
    if (contentTitle != null) {
      return '$deviceName: $contentTitle';
    }
    return deviceName;
  }

  /// Creates a StreamSession from Firestore document.
  factory StreamSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StreamSession.fromJson(data, doc.id);
  }

  /// Creates a StreamSession from JSON.
  factory StreamSession.fromJson(Map<String, dynamic> json, String id) {
    return StreamSession(
      id: id,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      devicePlatform: DevicePlatform.values.firstWhere(
        (p) => p.name == json['devicePlatform'],
        orElse: () => DevicePlatform.unknown,
      ),
      startedAt: (json['startedAt'] as Timestamp).toDate(),
      lastHeartbeatAt: (json['lastHeartbeatAt'] as Timestamp).toDate(),
      endedAt: json['endedAt'] != null
          ? (json['endedAt'] as Timestamp).toDate()
          : null,
      status: StreamSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StreamSessionStatus.ended,
      ),
      contentId: json['contentId'] as String?,
      contentTitle: json['contentTitle'] as String?,
      contentType: json['contentType'] as String?,
    );
  }

  /// Converts to JSON for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'devicePlatform': devicePlatform.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'lastHeartbeatAt': Timestamp.fromDate(lastHeartbeatAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'status': status.name,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'contentType': contentType,
    };
  }

  /// Creates a copy with updated fields.
  StreamSession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    DevicePlatform? devicePlatform,
    DateTime? startedAt,
    DateTime? lastHeartbeatAt,
    DateTime? endedAt,
    StreamSessionStatus? status,
    String? contentId,
    String? contentTitle,
    String? contentType,
  }) {
    return StreamSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      startedAt: startedAt ?? this.startedAt,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      contentType: contentType ?? this.contentType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StreamSession($id, $deviceName, $status)';
}

/// Result of attempting to start a stream.
sealed class StreamStartResult {
  const StreamStartResult();
}

/// Stream started successfully.
class StreamStartSuccess extends StreamStartResult {
  const StreamStartSuccess({required this.session});

  final StreamSession session;
}

/// Stream failed - concurrent limit exceeded.
class StreamLimitExceeded extends StreamStartResult {
  const StreamLimitExceeded({
    required this.maxStreams,
    required this.activeSessions,
  });

  final int maxStreams;
  final List<StreamSession> activeSessions;
}

/// Stream failed - device not registered.
class StreamDeviceNotRegistered extends StreamStartResult {
  const StreamDeviceNotRegistered();
}

/// Stream failed - other error.
class StreamStartError extends StreamStartResult {
  const StreamStartError({required this.message});

  final String message;
}

/// Configuration for stream limits per subscription tier.
class StreamLimits {
  const StreamLimits({
    required this.maxConcurrentStreams,
    required this.maxRegisteredDevices,
    this.allowDownloads = false,
    this.downloadLimit = 0,
  });

  /// Maximum simultaneous streams.
  final int maxConcurrentStreams;

  /// Maximum devices that can be registered.
  final int maxRegisteredDevices;

  /// Whether offline downloads are allowed.
  final bool allowDownloads;

  /// Maximum offline downloads (if allowed).
  final int downloadLimit;

  /// Free tier limits.
  static const free = StreamLimits(
    maxConcurrentStreams: 1,
    maxRegisteredDevices: 2,
    allowDownloads: false,
    downloadLimit: 0,
  );

  /// Pro tier limits (similar to Netflix Standard).
  static const pro = StreamLimits(
    maxConcurrentStreams: 2,
    maxRegisteredDevices: 5,
    allowDownloads: true,
    downloadLimit: 10,
  );

  /// Pro+ tier limits (similar to Netflix Premium).
  static const proPlus = StreamLimits(
    maxConcurrentStreams: 4,
    maxRegisteredDevices: 10,
    allowDownloads: true,
    downloadLimit: 25,
  );

  /// Family tier limits.
  static const family = StreamLimits(
    maxConcurrentStreams: 6,
    maxRegisteredDevices: 15,
    allowDownloads: true,
    downloadLimit: 50,
  );

  /// Get limits for a subscription tier.
  static StreamLimits forTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return pro;
      case 'pro_plus':
      case 'proplus':
        return proPlus;
      case 'family':
        return family;
      case 'free':
      default:
        return free;
    }
  }
}
