// Kylos IPTV Player - Handoff Request Entity
// Represents a request to transfer playback to another device.

import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';

/// Status of a handoff request.
enum HandoffStatus {
  /// Request sent, waiting for response
  pending,

  /// Target device accepted the request
  accepted,

  /// Target device rejected the request
  rejected,

  /// Handoff completed successfully (playback started on target)
  completed,

  /// Request expired (no response within timeout)
  expired,

  /// Request was cancelled by sender
  cancelled,
}

/// A request to transfer playback from one device to another.
class HandoffRequest {
  const HandoffRequest({
    required this.id,
    required this.fromDeviceId,
    required this.fromDeviceName,
    required this.toDeviceId,
    required this.toDeviceName,
    required this.userId,
    required this.content,
    required this.position,
    required this.timestamp,
    required this.status,
    this.expiresAt,
    this.respondedAt,
    this.completedAt,
  });

  /// Unique request ID.
  final String id;

  /// Device ID of the sender.
  final String fromDeviceId;

  /// Display name of the sender device.
  final String fromDeviceName;

  /// Device ID of the target.
  final String toDeviceId;

  /// Display name of the target device.
  final String toDeviceName;

  /// User ID (must match on both devices).
  final String userId;

  /// Content to play on target device.
  final PlayableContent content;

  /// Playback position to resume from.
  final Duration position;

  /// When the request was created.
  final DateTime timestamp;

  /// Current status of the request.
  final HandoffStatus status;

  /// When the request expires (if not responded to).
  final DateTime? expiresAt;

  /// When the target device responded.
  final DateTime? respondedAt;

  /// When the handoff was completed.
  final DateTime? completedAt;

  /// Whether the request is still pending.
  bool get isPending => status == HandoffStatus.pending;

  /// Whether the request has been accepted.
  bool get isAccepted => status == HandoffStatus.accepted;

  /// Whether the request is complete or failed.
  bool get isFinished =>
      status == HandoffStatus.completed ||
      status == HandoffStatus.rejected ||
      status == HandoffStatus.expired ||
      status == HandoffStatus.cancelled;

  /// Whether the request has expired.
  bool get isExpired {
    if (status == HandoffStatus.expired) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Time until expiration.
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  HandoffRequest copyWith({
    String? id,
    String? fromDeviceId,
    String? fromDeviceName,
    String? toDeviceId,
    String? toDeviceName,
    String? userId,
    PlayableContent? content,
    Duration? position,
    DateTime? timestamp,
    HandoffStatus? status,
    DateTime? expiresAt,
    DateTime? respondedAt,
    DateTime? completedAt,
  }) {
    return HandoffRequest(
      id: id ?? this.id,
      fromDeviceId: fromDeviceId ?? this.fromDeviceId,
      fromDeviceName: fromDeviceName ?? this.fromDeviceName,
      toDeviceId: toDeviceId ?? this.toDeviceId,
      toDeviceName: toDeviceName ?? this.toDeviceName,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromDeviceId': fromDeviceId,
        'fromDeviceName': fromDeviceName,
        'toDeviceId': toDeviceId,
        'toDeviceName': toDeviceName,
        'userId': userId,
        'content': {
          'id': content.id,
          'title': content.title,
          'streamUrl': content.streamUrl,
          'type': content.type.name,
          'logoUrl': content.logoUrl,
          'categoryName': content.categoryName,
        },
        'position': position.inMilliseconds,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': status.name,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'respondedAt': respondedAt?.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  factory HandoffRequest.fromJson(Map<dynamic, dynamic> json) {
    final contentJson = json['content'] as Map<dynamic, dynamic>;

    return HandoffRequest(
      id: json['id'] as String,
      fromDeviceId: json['fromDeviceId'] as String,
      fromDeviceName: json['fromDeviceName'] as String,
      toDeviceId: json['toDeviceId'] as String,
      toDeviceName: json['toDeviceName'] as String? ?? 'Unknown',
      userId: json['userId'] as String,
      content: PlayableContent(
        id: contentJson['id'] as String,
        title: contentJson['title'] as String,
        streamUrl: contentJson['streamUrl'] as String,
        type: ContentType.values.firstWhere(
          (t) => t.name == contentJson['type'],
          orElse: () => ContentType.vod,
        ),
        logoUrl: contentJson['logoUrl'] as String?,
        categoryName: contentJson['categoryName'] as String?,
      ),
      position: Duration(milliseconds: json['position'] as int? ?? 0),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int? ?? 0,
      ),
      status: HandoffStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => HandoffStatus.pending,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['respondedAt'] as int)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandoffRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
