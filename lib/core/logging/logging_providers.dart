// Kylos IPTV Player - Logging Providers
// Riverpod providers for logging services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/logging/app_logger.dart';

/// Provider for the application logger.
///
/// Returns the global logger instance.
/// Use AppLogger.tagged('FeatureName') for feature-specific loggers.
final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger.instance;
});

/// Provider for a tagged logger.
///
/// Creates a logger with a specific tag for component identification.
/// Usage: ref.watch(taggedLoggerProvider('MyFeature'))
final taggedLoggerProvider = Provider.family<AppLogger, String>((ref, tag) {
  return AppLogger.tagged(tag);
});
