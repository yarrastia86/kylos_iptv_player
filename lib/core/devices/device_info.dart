// Kylos IPTV Player - Device Info
// Utility to gather device information for registration.

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service to gather device information.
class DeviceInfoService {
  DeviceInfoService({
    DeviceInfoPlugin? deviceInfo,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  static const String _deviceIdKey = 'kylos_device_id';
  static const _uuid = Uuid();

  /// Gets the unique device ID (generated on first launch, persisted).
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('DeviceInfo: Generated new device ID: $deviceId');
    }

    return deviceId;
  }

  /// Gets detailed information about the current device.
  Future<DeviceDetails> getDeviceDetails() async {
    final deviceId = await getDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();

    DevicePlatform platform;
    DeviceFormFactor formFactor;
    String? model;
    String? osVersion;

    if (kIsWeb) {
      platform = DevicePlatform.web;
      formFactor = DeviceFormFactor.web;
      final webInfo = await _deviceInfo.webBrowserInfo;
      model = webInfo.browserName.name;
      osVersion = webInfo.userAgent;
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      // Detect Android TV
      if (_isAndroidTv(androidInfo)) {
        platform = DevicePlatform.androidTv;
        formFactor = DeviceFormFactor.tv;
      } else if (androidInfo.model.toLowerCase().contains('fire')) {
        // Fire TV detection
        platform = DevicePlatform.fireTv;
        formFactor = DeviceFormFactor.tv;
      } else if (_isTablet(androidInfo)) {
        platform = DevicePlatform.android;
        formFactor = DeviceFormFactor.tablet;
      } else {
        platform = DevicePlatform.android;
        formFactor = DeviceFormFactor.phone;
      }

      model = '${androidInfo.manufacturer} ${androidInfo.model}';
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;

      if (iosInfo.model.toLowerCase().contains('ipad')) {
        formFactor = DeviceFormFactor.tablet;
      } else {
        formFactor = DeviceFormFactor.phone;
      }

      platform = DevicePlatform.ios;
      model = iosInfo.utsname.machine;
      osVersion = 'iOS ${iosInfo.systemVersion}';
    } else if (Platform.isMacOS) {
      final macInfo = await _deviceInfo.macOsInfo;
      platform = DevicePlatform.macos;
      formFactor = DeviceFormFactor.desktop;
      model = macInfo.model;
      osVersion = 'macOS ${macInfo.osRelease}';
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      platform = DevicePlatform.windows;
      formFactor = DeviceFormFactor.desktop;
      model = windowsInfo.productName;
      osVersion = 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
    } else if (Platform.isLinux) {
      final linuxInfo = await _deviceInfo.linuxInfo;
      platform = DevicePlatform.linux;
      formFactor = DeviceFormFactor.desktop;
      model = linuxInfo.prettyName;
      osVersion = linuxInfo.versionId ?? 'Linux';
    } else {
      platform = DevicePlatform.unknown;
      formFactor = DeviceFormFactor.unknown;
    }

    final defaultName = _generateDefaultName(platform, formFactor);

    return DeviceDetails(
      id: deviceId,
      defaultName: defaultName,
      platform: platform,
      formFactor: formFactor,
      model: model,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }

  bool _isAndroidTv(AndroidDeviceInfo info) {
    // Check for TV features
    final features = info.systemFeatures;
    return features.contains('android.software.leanback') ||
        features.contains('android.hardware.type.television');
  }

  bool _isTablet(AndroidDeviceInfo info) {
    // Simple tablet detection based on device type
    // A more accurate detection would use actual screen dimensions
    // but device_info_plus doesn't provide them directly
    final model = info.model.toLowerCase();
    return model.contains('tablet') ||
        model.contains('pad') ||
        model.contains('tab');
  }

  String _generateDefaultName(DevicePlatform platform, DeviceFormFactor formFactor) {
    switch (platform) {
      case DevicePlatform.android:
        return formFactor == DeviceFormFactor.tablet
            ? 'Android Tablet'
            : 'Android Phone';
      case DevicePlatform.ios:
        return formFactor == DeviceFormFactor.tablet ? 'iPad' : 'iPhone';
      case DevicePlatform.macos:
        return 'Mac';
      case DevicePlatform.windows:
        return 'Windows PC';
      case DevicePlatform.linux:
        return 'Linux PC';
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
        return 'Device';
    }
  }
}

/// Detailed information about the current device.
class DeviceDetails {
  const DeviceDetails({
    required this.id,
    required this.defaultName,
    required this.platform,
    required this.formFactor,
    this.model,
    this.osVersion,
    this.appVersion,
    this.buildNumber,
  });

  /// Unique device identifier.
  final String id;

  /// Default device name.
  final String defaultName;

  /// Device platform.
  final DevicePlatform platform;

  /// Device form factor.
  final DeviceFormFactor formFactor;

  /// Device model.
  final String? model;

  /// OS version.
  final String? osVersion;

  /// App version.
  final String? appVersion;

  /// App build number.
  final String? buildNumber;

  @override
  String toString() =>
      'DeviceDetails($id, $defaultName, ${platform.name}, ${formFactor.name})';
}
