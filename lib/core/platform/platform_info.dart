// Kylos IPTV Player - Platform Info
// Runtime platform detection utilities.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';

/// Platform channel for native platform queries.
const _platformChannel = MethodChannel('com.kylos.iptvplayer/platform');

/// Utility class for detecting platform and form factor at runtime.
class PlatformInfo {
  PlatformInfo._();

  static FormFactor? _cachedFormFactor;
  static InputMode? _cachedInputMode;
  static bool? _isAndroidTVCached;
  static bool? _isFireTVCached;

  /// Detect form factor based on platform and screen size.
  ///
  /// For Android, also checks if running on Android TV via UI mode.
  /// Caches the result for subsequent calls.
  static Future<FormFactor> detectFormFactor(Size screenSize) async {
    if (_cachedFormFactor != null) return _cachedFormFactor!;

    if (kIsWeb) {
      _cachedFormFactor = FormFactor.web;
      return FormFactor.web;
    }

    if (Platform.isAndroid) {
      // Check if running on Android TV via platform channel
      final isTV = await isAndroidTV();
      if (isTV) {
        _cachedFormFactor = FormFactor.tv;
        return FormFactor.tv;
      }

      // Check screen size for phone vs tablet
      final shortestSide = screenSize.shortestSide;
      _cachedFormFactor =
          shortestSide < 600 ? FormFactor.mobile : FormFactor.tablet;
      return _cachedFormFactor!;
    }

    if (Platform.isIOS) {
      final shortestSide = screenSize.shortestSide;
      _cachedFormFactor =
          shortestSide < 600 ? FormFactor.mobile : FormFactor.tablet;
      return _cachedFormFactor!;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _cachedFormFactor = FormFactor.desktop;
      return FormFactor.desktop;
    }

    _cachedFormFactor = FormFactor.mobile;
    return FormFactor.mobile;
  }

  /// Check if running on Android TV / Fire TV.
  ///
  /// Returns true if the device is running Android TV or Fire TV OS.
  /// Results are cached for performance.
  static Future<bool> isAndroidTV() async {
    if (_isAndroidTVCached != null) return _isAndroidTVCached!;

    if (!Platform.isAndroid) {
      _isAndroidTVCached = false;
      return false;
    }

    try {
      final result = await _platformChannel.invokeMethod<bool>('isAndroidTV');
      _isAndroidTVCached = result ?? false;
      return _isAndroidTVCached!;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformInfo: Failed to detect Android TV: $e');
      }
      _isAndroidTVCached = false;
      return false;
    } on MissingPluginException {
      // Platform channel not implemented yet, return false
      _isAndroidTVCached = false;
      return false;
    }
  }

  /// Check if running on Amazon Fire TV.
  ///
  /// Returns true if the device is a Fire TV device.
  /// Results are cached for performance.
  static Future<bool> isFireTV() async {
    if (_isFireTVCached != null) return _isFireTVCached!;

    if (!Platform.isAndroid) {
      _isFireTVCached = false;
      return false;
    }

    try {
      final result = await _platformChannel.invokeMethod<bool>('isFireTV');
      _isFireTVCached = result ?? false;
      return _isFireTVCached!;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformInfo: Failed to detect Fire TV: $e');
      }
      _isFireTVCached = false;
      return false;
    } on MissingPluginException {
      // Platform channel not implemented yet, return false
      _isFireTVCached = false;
      return false;
    }
  }

  /// Detect primary input mode based on form factor.
  static InputMode detectInputMode(FormFactor formFactor) {
    if (_cachedInputMode != null) return _cachedInputMode!;

    switch (formFactor) {
      case FormFactor.mobile:
      case FormFactor.tablet:
        _cachedInputMode = InputMode.touch;
      case FormFactor.tv:
        _cachedInputMode = InputMode.dpad;
      case FormFactor.desktop:
      case FormFactor.web:
        _cachedInputMode = InputMode.keyboard;
    }

    return _cachedInputMode!;
  }

  /// Clear cached values (useful for testing).
  @visibleForTesting
  static void clearCache() {
    _cachedFormFactor = null;
    _cachedInputMode = null;
    _isAndroidTVCached = null;
    _isFireTVCached = null;
  }

  /// Force a specific form factor (useful for testing).
  @visibleForTesting
  static void setFormFactorForTesting(FormFactor formFactor) {
    _cachedFormFactor = formFactor;
    _cachedInputMode = detectInputMode(formFactor);
  }
}
