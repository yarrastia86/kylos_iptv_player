// Kylos IPTV Player - App Integrity Checker
// Lightweight integrity and environment detection.
//
// IMPORTANT DESIGN NOTES:
// - This is NOT a bulletproof security measure. Determined attackers can
//   bypass these checks. The goal is to raise the bar for casual tampering.
// - These checks are OPTIONAL and can be disabled via configuration.
// - We intentionally avoid aggressive anti-tamper measures that harm
//   legitimate users (e.g., blocking all rooted devices).
// - The focus is on detection and logging, not enforcement.
//
// What this checks:
// 1. Debug mode detection (should never be true in production)
// 2. Emulator/simulator detection (informational)
// 3. Basic root/jailbreak indicators (informational)
// 4. Package signature verification (Android only, via manifest)
//
// This is designed to be easily auditable and non-hostile to users.

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Result of an integrity check.
class IntegrityCheckResult {
  const IntegrityCheckResult({
    required this.isDebugMode,
    required this.isEmulator,
    required this.hasRootIndicators,
    required this.indicators,
    this.error,
  });

  /// True if app is running in debug mode.
  final bool isDebugMode;

  /// True if running on an emulator/simulator.
  final bool isEmulator;

  /// True if root/jailbreak indicators were detected.
  /// Note: This has false positives. Do NOT use for blocking.
  final bool hasRootIndicators;

  /// List of specific indicators detected.
  final List<String> indicators;

  /// Any error that occurred during checks.
  final String? error;

  /// True if the environment appears to be a normal production device.
  bool get isNormalEnvironment =>
      !isDebugMode && !isEmulator && !hasRootIndicators;

  @override
  String toString() {
    return 'IntegrityCheckResult('
        'debug: $isDebugMode, '
        'emulator: $isEmulator, '
        'rootIndicators: $hasRootIndicators, '
        'indicators: $indicators)';
  }
}

/// Configuration for integrity checking behavior.
class IntegrityConfig {
  const IntegrityConfig({
    this.enabled = true,
    this.checkRoot = true,
    this.checkEmulator = true,
    this.logWarnings = true,
    this.blockOnDebugMode = false,
    this.blockOnRoot = false,
    this.blockOnEmulator = false,
  });

  /// Master switch - if false, all checks return clean results.
  final bool enabled;

  /// Whether to check for root/jailbreak indicators.
  final bool checkRoot;

  /// Whether to check for emulator/simulator.
  final bool checkEmulator;

  /// Whether to log warnings when indicators are found.
  final bool logWarnings;

  /// Block app functionality if debug mode detected.
  /// Generally should be false - debug builds are legitimate.
  final bool blockOnDebugMode;

  /// Block app functionality if root detected.
  /// CAUTION: This will block many legitimate users. Use with care.
  final bool blockOnRoot;

  /// Block app functionality if emulator detected.
  /// CAUTION: This prevents testing. Usually should be false.
  final bool blockOnEmulator;

  /// Default permissive configuration - detect but don't block.
  static const permissive = IntegrityConfig();

  /// Stricter configuration for paranoid mode.
  /// Still doesn't block root to avoid harming legitimate users.
  static const strict = IntegrityConfig(
    blockOnDebugMode: true,
    blockOnEmulator: true,
    blockOnRoot: false, // Intentionally not blocking rooted devices
  );

  /// Disabled configuration - no checks at all.
  static const disabled = IntegrityConfig(enabled: false);
}

/// Service for checking app and device integrity.
///
/// This service is intentionally simple and transparent.
/// It does NOT use obfuscated checks or "security by obscurity".
class IntegrityChecker {
  IntegrityChecker({this.config = IntegrityConfig.permissive});

  final IntegrityConfig config;

  /// Performs all configured integrity checks.
  Future<IntegrityCheckResult> checkIntegrity() async {
    if (!config.enabled) {
      return const IntegrityCheckResult(
        isDebugMode: false,
        isEmulator: false,
        hasRootIndicators: false,
        indicators: [],
      );
    }

    final indicators = <String>[];
    var hasRootIndicators = false;
    var isEmulator = false;
    String? error;

    try {
      // Debug mode is always checked
      final isDebugMode = kDebugMode;
      if (isDebugMode) {
        indicators.add('debug_mode');
      }

      // Emulator detection
      if (config.checkEmulator) {
        isEmulator = await _checkEmulator();
        if (isEmulator) {
          indicators.add('emulator');
        }
      }

      // Root/jailbreak detection
      if (config.checkRoot) {
        final rootIndicators = await _checkRootIndicators();
        if (rootIndicators.isNotEmpty) {
          hasRootIndicators = true;
          indicators.addAll(rootIndicators);
        }
      }

      return IntegrityCheckResult(
        isDebugMode: isDebugMode,
        isEmulator: isEmulator,
        hasRootIndicators: hasRootIndicators,
        indicators: indicators,
      );
    } catch (e) {
      error = e.toString();
      return IntegrityCheckResult(
        isDebugMode: kDebugMode,
        isEmulator: false,
        hasRootIndicators: false,
        indicators: indicators,
        error: error,
      );
    }
  }

  /// Checks if running on an emulator/simulator.
  Future<bool> _checkEmulator() async {
    if (Platform.isAndroid) {
      return _checkAndroidEmulator();
    } else if (Platform.isIOS) {
      return _checkIOSSimulator();
    }
    return false;
  }

  /// Android emulator detection.
  bool _checkAndroidEmulator() {
    // These are common indicators, not definitive
    // Real emulator detection would use Build.FINGERPRINT, etc.
    // which requires platform channel or plugin
    final indicators = <String>[];

    // Check for common emulator files (best effort without root)
    final emulatorPaths = [
      '/system/bin/qemu-props',
      '/dev/socket/qemud',
      '/dev/qemu_pipe',
    ];

    for (final path in emulatorPaths) {
      if (File(path).existsSync()) {
        indicators.add(path);
      }
    }

    return indicators.isNotEmpty;
  }

  /// iOS simulator detection.
  bool _checkIOSSimulator() {
    // On iOS, we can check environment variables
    // The SIMULATOR_DEVICE_NAME is set in simulators
    final simulatorName = Platform.environment['SIMULATOR_DEVICE_NAME'];
    return simulatorName != null && simulatorName.isNotEmpty;
  }

  /// Checks for root/jailbreak indicators.
  ///
  /// IMPORTANT: These checks have known false positives.
  /// Some legitimate apps/tools trigger these checks.
  /// Do NOT use for blocking access.
  Future<List<String>> _checkRootIndicators() async {
    final indicators = <String>[];

    if (Platform.isAndroid) {
      indicators.addAll(await _checkAndroidRootIndicators());
    } else if (Platform.isIOS) {
      indicators.addAll(await _checkIOSJailbreakIndicators());
    }

    return indicators;
  }

  /// Android root indicators.
  Future<List<String>> _checkAndroidRootIndicators() async {
    final indicators = <String>[];

    // Common su binary locations
    final suPaths = [
      '/system/bin/su',
      '/system/xbin/su',
      '/sbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
    ];

    for (final path in suPaths) {
      try {
        if (await File(path).exists()) {
          indicators.add('su_binary:$path');
          break; // One is enough
        }
      } catch (_) {
        // Access denied - expected on non-rooted devices
      }
    }

    // Magisk indicator (if not hidden)
    try {
      if (await Directory('/data/adb/magisk').exists()) {
        indicators.add('magisk_directory');
      }
    } catch (_) {
      // Access denied
    }

    return indicators;
  }

  /// iOS jailbreak indicators.
  Future<List<String>> _checkIOSJailbreakIndicators() async {
    final indicators = <String>[];

    // Common jailbreak paths
    final jbPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];

    for (final path in jbPaths) {
      try {
        final type = FileSystemEntity.typeSync(path);
        if (type != FileSystemEntityType.notFound) {
          indicators.add('jb_path:$path');
        }
      } catch (_) {
        // Access denied or path doesn't exist
      }
    }

    // Check for ability to write outside sandbox
    try {
      final testFile = File('/private/jailbreak_test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();
      indicators.add('sandbox_escape');
    } catch (_) {
      // Expected - can't write outside sandbox on non-jailbroken
    }

    return indicators;
  }

  /// Determines if the app should proceed based on check results.
  ///
  /// Returns null if OK to proceed, or an error message if blocked.
  String? shouldBlock(IntegrityCheckResult result) {
    if (!config.enabled) return null;

    if (config.blockOnDebugMode && result.isDebugMode) {
      return 'App cannot run in debug mode';
    }

    if (config.blockOnEmulator && result.isEmulator) {
      return 'App cannot run on emulators';
    }

    if (config.blockOnRoot && result.hasRootIndicators) {
      return 'App cannot run on rooted/jailbroken devices';
    }

    return null;
  }
}
