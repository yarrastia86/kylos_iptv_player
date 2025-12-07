// Kylos IPTV Player - TV Pairing Entity
// Represents a TV pairing session for QR code authentication.

/// Status of a TV pairing session.
enum TvPairingStatus {
  /// Pairing session created, waiting for mobile to scan
  pending,

  /// Mobile device scanned the QR code
  scanned,

  /// Pairing completed successfully
  completed,

  /// Pairing expired (not scanned within timeout)
  expired,

  /// Pairing cancelled by user
  cancelled,
}

/// Represents a TV pairing session.
class TvPairingSession {
  const TvPairingSession({
    required this.sessionId,
    required this.code,
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.pairedUserId,
    this.pairedAt,
  });

  /// Unique session ID.
  final String sessionId;

  /// Short numeric code for manual entry (6 digits).
  final String code;

  /// TV device ID requesting pairing.
  final String deviceId;

  /// TV device name for display.
  final String deviceName;

  /// When the session was created.
  final DateTime createdAt;

  /// When the session expires.
  final DateTime expiresAt;

  /// Current pairing status.
  final TvPairingStatus status;

  /// User ID that paired (set after successful scan).
  final String? pairedUserId;

  /// When pairing was completed.
  final DateTime? pairedAt;

  /// Whether the session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the session is still valid for scanning.
  bool get canBePaired =>
      status == TvPairingStatus.pending && !isExpired;

  /// Time remaining until expiry.
  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// QR code data (contains session ID for secure pairing).
  String get qrCodeData => 'kylos://pair?session=$sessionId';

  TvPairingSession copyWith({
    String? sessionId,
    String? code,
    String? deviceId,
    String? deviceName,
    DateTime? createdAt,
    DateTime? expiresAt,
    TvPairingStatus? status,
    String? pairedUserId,
    DateTime? pairedAt,
  }) {
    return TvPairingSession(
      sessionId: sessionId ?? this.sessionId,
      code: code ?? this.code,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      pairedUserId: pairedUserId ?? this.pairedUserId,
      pairedAt: pairedAt ?? this.pairedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'code': code,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'status': status.name,
        'pairedUserId': pairedUserId,
        'pairedAt': pairedAt?.millisecondsSinceEpoch,
      };

  factory TvPairingSession.fromJson(Map<dynamic, dynamic> json) {
    return TvPairingSession(
      sessionId: json['sessionId'] as String,
      code: json['code'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String? ?? 'TV',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        json['expiresAt'] as int,
      ),
      status: TvPairingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TvPairingStatus.pending,
      ),
      pairedUserId: json['pairedUserId'] as String?,
      pairedAt: json['pairedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['pairedAt'] as int)
          : null,
    );
  }
}
