// Kylos IPTV Player - Device Entity
// Represents a registered device for multi-device account management.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported device platforms.
enum DevicePlatform {
  /// Android phones and tablets
  android,

  /// iOS (iPhone, iPad)
  ios,

  /// macOS
  macos,

  /// Windows
  windows,

  /// Linux
  linux,

  /// Android TV
  androidTv,

  /// Amazon Fire TV
  fireTv,

  /// Apple TV
  appleTv,

  /// Roku
  roku,

  /// Android Auto
  androidAuto,

  /// CarPlay
  carPlay,

  /// Web browser
  web,

  /// Unknown platform
  unknown,
}

/// Extension for DevicePlatform.
extension DevicePlatformExtension on DevicePlatform {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case DevicePlatform.android:
        return 'Android';
      case DevicePlatform.ios:
        return 'iPhone/iPad';
      case DevicePlatform.macos:
        return 'Mac';
      case DevicePlatform.windows:
        return 'Windows';
      case DevicePlatform.linux:
        return 'Linux';
      case DevicePlatform.androidTv:
        return 'Android TV';
      case DevicePlatform.fireTv:
        return 'Fire TV';
      case DevicePlatform.appleTv:
        return 'Apple TV';
      case DevicePlatform.roku:
        return 'Roku';
      case DevicePlatform.androidAuto:
        return 'Android Auto';
      case DevicePlatform.carPlay:
        return 'CarPlay';
      case DevicePlatform.web:
        return 'Web Browser';
      case DevicePlatform.unknown:
        return 'Unknown Device';
    }
  }

  /// Icon name for the platform.
  String get iconName {
    switch (this) {
      case DevicePlatform.android:
      case DevicePlatform.androidTv:
      case DevicePlatform.androidAuto:
        return 'android';
      case DevicePlatform.ios:
      case DevicePlatform.macos:
      case DevicePlatform.appleTv:
      case DevicePlatform.carPlay:
        return 'apple';
      case DevicePlatform.windows:
        return 'windows';
      case DevicePlatform.linux:
        return 'linux';
      case DevicePlatform.fireTv:
        return 'fire_tv';
      case DevicePlatform.roku:
        return 'roku';
      case DevicePlatform.web:
        return 'web';
      case DevicePlatform.unknown:
        return 'device';
    }
  }

  /// Whether this is a TV/large screen device.
  bool get isTvDevice {
    return this == DevicePlatform.androidTv ||
        this == DevicePlatform.fireTv ||
        this == DevicePlatform.appleTv ||
        this == DevicePlatform.roku;
  }

  /// Whether this is a mobile device.
  bool get isMobileDevice {
    return this == DevicePlatform.android || this == DevicePlatform.ios;
  }

  /// Whether this is a desktop device.
  bool get isDesktopDevice {
    return this == DevicePlatform.macos ||
        this == DevicePlatform.windows ||
        this == DevicePlatform.linux;
  }

  /// Whether this is a car device.
  bool get isCarDevice {
    return this == DevicePlatform.androidAuto || this == DevicePlatform.carPlay;
  }
}

/// Device form factor.
enum DeviceFormFactor {
  /// Smartphone
  phone,

  /// Tablet
  tablet,

  /// Television
  tv,

  /// Desktop/laptop computer
  desktop,

  /// Car display
  car,

  /// Web browser
  web,

  /// Unknown form factor
  unknown,
}

/// Extension for DeviceFormFactor.
extension DeviceFormFactorExtension on DeviceFormFactor {
  String get displayName {
    switch (this) {
      case DeviceFormFactor.phone:
        return 'Phone';
      case DeviceFormFactor.tablet:
        return 'Tablet';
      case DeviceFormFactor.tv:
        return 'TV';
      case DeviceFormFactor.desktop:
        return 'Computer';
      case DeviceFormFactor.car:
        return 'Car';
      case DeviceFormFactor.web:
        return 'Browser';
      case DeviceFormFactor.unknown:
        return 'Device';
    }
  }
}

/// Represents a registered device in the user's account.
class Device {
  const Device({
    required this.id,
    required this.userId,
    required this.name,
    required this.platform,
    required this.formFactor,
    this.model,
    this.osVersion,
    this.appVersion,
    required this.createdAt,
    required this.lastActiveAt,
    this.lastStreamAt,
    this.isCurrentDevice = false,
    this.isTrusted = false,
  });

  /// Unique device identifier (generated on first launch).
  final String id;

  /// User ID this device belongs to.
  final String userId;

  /// User-friendly device name (e.g., "John's iPhone", "Living Room TV").
  final String name;

  /// Device platform.
  final DevicePlatform platform;

  /// Device form factor.
  final DeviceFormFactor formFactor;

  /// Device model (e.g., "iPhone 15 Pro", "Samsung Galaxy S24").
  final String? model;

  /// Operating system version.
  final String? osVersion;

  /// App version on this device.
  final String? appVersion;

  /// When this device was first registered.
  final DateTime createdAt;

  /// When this device was last active.
  final DateTime lastActiveAt;

  /// When this device last streamed content.
  final DateTime? lastStreamAt;

  /// Whether this is the current device making the request.
  final bool isCurrentDevice;

  /// Whether this device is marked as trusted (skip verification).
  final bool isTrusted;

  /// Display name combining device info.
  String get displayName {
    if (model != null) {
      return '$name ($model)';
    }
    return '$name (${platform.displayName})';
  }

  /// Short description for lists.
  String get shortDescription {
    final lastActive = _formatLastActive();
    return '${platform.displayName} • $lastActive';
  }

  String _formatLastActive() {
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);

    if (diff.inMinutes < 1) {
      return 'Active now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  /// Whether this device was recently active (within last 5 minutes).
  bool get isRecentlyActive {
    return DateTime.now().difference(lastActiveAt).inMinutes < 5;
  }

  /// Whether this device is currently streaming.
  bool get isCurrentlyStreaming {
    if (lastStreamAt == null) return false;
    return DateTime.now().difference(lastStreamAt!).inMinutes < 2;
  }

  /// Creates a Device from Firestore document.
  factory Device.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Device.fromJson(data, doc.id);
  }

  /// Creates a Device from JSON.
  factory Device.fromJson(Map<String, dynamic> json, String id) {
    return Device(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      platform: DevicePlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => DevicePlatform.unknown,
      ),
      formFactor: DeviceFormFactor.values.firstWhere(
        (f) => f.name == json['formFactor'],
        orElse: () => DeviceFormFactor.unknown,
      ),
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (json['lastActiveAt'] as Timestamp).toDate(),
      lastStreamAt: json['lastStreamAt'] != null
          ? (json['lastStreamAt'] as Timestamp).toDate()
          : null,
      isCurrentDevice: json['isCurrentDevice'] as bool? ?? false,
      isTrusted: json['isTrusted'] as bool? ?? false,
    );
  }

  /// Converts to JSON for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'platform': platform.name,
      'formFactor': formFactor.name,
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'lastStreamAt':
          lastStreamAt != null ? Timestamp.fromDate(lastStreamAt!) : null,
      'isTrusted': isTrusted,
    };
  }

  /// Creates a copy with the given fields replaced.
  Device copyWith({
    String? id,
    String? userId,
    String? name,
    DevicePlatform? platform,
    DeviceFormFactor? formFactor,
    String? model,
    String? osVersion,
    String? appVersion,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? lastStreamAt,
    bool? isCurrentDevice,
    bool? isTrusted,
  }) {
    return Device(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      formFactor: formFactor ?? this.formFactor,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastStreamAt: lastStreamAt ?? this.lastStreamAt,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Device($id, $name, ${platform.name})';
}

/// Represents the result of device registration.
sealed class DeviceRegistrationResult {
  const DeviceRegistrationResult();
}

/// Device registration succeeded.
class DeviceRegistrationSuccess extends DeviceRegistrationResult {
  const DeviceRegistrationSuccess({required this.device});

  final Device device;
}

/// Device registration failed - too many devices.
class DeviceRegistrationLimitExceeded extends DeviceRegistrationResult {
  const DeviceRegistrationLimitExceeded({
    required this.maxDevices,
    required this.currentCount,
    required this.existingDevices,
  });

  final int maxDevices;
  final int currentCount;
  final List<Device> existingDevices;
}

/// Device registration failed - other error.
class DeviceRegistrationError extends DeviceRegistrationResult {
  const DeviceRegistrationError({required this.message});

  final String message;
}
