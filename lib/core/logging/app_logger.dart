// Kylos IPTV Player - Application Logger
// Structured logging with privacy controls.
//
// PRIVACY GUIDELINES - What MUST NOT be logged:
// - User passwords (IPTV provider, Firebase, any auth)
// - Full authentication tokens (only log last 4 chars if needed)
// - Playlist URLs (may contain credentials in query params)
// - User IP addresses (unless anonymized)
// - Device identifiers that could track users
// - Full email addresses (use anonymized form: j***@example.com)
// - Any PII without explicit user consent
//
// What MAY be logged:
// - Error codes and types (not full error messages with user data)
// - Feature usage events (anonymized)
// - Performance metrics
// - App lifecycle events
// - Non-sensitive configuration values
// - Anonymized user identifiers (Firebase UID is OK)

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Log levels in order of severity.
enum LogLevel {
  /// Detailed debugging information.
  debug,

  /// General information about app operation.
  info,

  /// Potentially problematic situations.
  warning,

  /// Errors that don't crash the app.
  error,

  /// Critical errors that may crash the app.
  fatal,
}

/// A structured log entry.
class LogEntry {
  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('[${timestamp.toIso8601String()}] ')
      ..write('[${level.name.toUpperCase()}] ');

    if (tag != null) {
      buffer.write('[$tag] ');
    }

    buffer.write(message);

    if (error != null) {
      buffer
        ..write('\nError: ')
        ..write(error);
    }

    if (stackTrace != null) {
      buffer
        ..write('\nStackTrace:\n')
        ..write(stackTrace);
    }

    return buffer.toString();
  }
}

/// Interface for log output destinations.
abstract class LogOutput {
  /// Outputs a log entry.
  void output(LogEntry entry);

  /// Flushes any buffered logs.
  Future<void> flush();

  /// Disposes resources.
  Future<void> dispose();
}

/// Console log output (for development).
class ConsoleLogOutput implements LogOutput {
  @override
  void output(LogEntry entry) {
    // Use debugPrint which handles long messages properly
    // and doesn't get truncated in debug console
    debugPrint(entry.toString());
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}

/// Crashlytics log output placeholder.
///
/// TODO: Implement actual Firebase Crashlytics integration.
/// This requires adding firebase_crashlytics to pubspec.yaml
/// and initializing Crashlytics in bootstrap.dart.
class CrashlyticsLogOutput implements LogOutput {
  @override
  void output(LogEntry entry) {
    // TODO: Implement Crashlytics integration
    // For non-fatal errors:
    // if (entry.level == LogLevel.error || entry.level == LogLevel.fatal) {
    //   FirebaseCrashlytics.instance.recordError(
    //     entry.error ?? entry.message,
    //     entry.stackTrace,
    //     reason: entry.message,
    //     fatal: entry.level == LogLevel.fatal,
    //   );
    // }
    //
    // For breadcrumb logs:
    // FirebaseCrashlytics.instance.log(entry.message);
  }

  @override
  Future<void> flush() async {
    // TODO: Flush Crashlytics queue if needed
  }

  @override
  Future<void> dispose() async {}
}

/// Logger configuration.
class LoggerConfig {
  const LoggerConfig({
    this.minLevel = LogLevel.info,
    this.enableConsole = true,
    this.enableCrashlytics = false,
    this.enablePrivacyFilter = true,
  });

  /// Minimum level to log. Lower severity logs are ignored.
  final LogLevel minLevel;

  /// Enable console output.
  final bool enableConsole;

  /// Enable Crashlytics output.
  final bool enableCrashlytics;

  /// Enable privacy filtering (redact sensitive data).
  final bool enablePrivacyFilter;

  /// Development configuration - verbose console logging.
  static const development = LoggerConfig(
    minLevel: LogLevel.debug,
    enableConsole: true,
    enableCrashlytics: false,
  );

  /// Production configuration - errors only, with Crashlytics.
  static const production = LoggerConfig(
    minLevel: LogLevel.warning,
    enableConsole: false,
    enableCrashlytics: true,
  );
}

/// Main application logger.
///
/// Provides structured logging with privacy controls and multiple outputs.
/// Use the static instance or create tagged loggers for specific features.
class AppLogger {
  AppLogger._({
    required LoggerConfig config,
    String? tag,
  })  : _config = config,
        _tag = tag {
    if (config.enableConsole) {
      _outputs.add(ConsoleLogOutput());
    }
    if (config.enableCrashlytics) {
      _outputs.add(CrashlyticsLogOutput());
    }
  }

  final LoggerConfig _config;
  final String? _tag;
  final List<LogOutput> _outputs = [];

  static AppLogger? _instance;

  /// Initializes the global logger instance.
  ///
  /// Should be called once during app startup.
  static void initialize({LoggerConfig? config}) {
    final effectiveConfig = config ??
        (kDebugMode ? LoggerConfig.development : LoggerConfig.production);
    _instance = AppLogger._(config: effectiveConfig);
  }

  /// Gets the global logger instance.
  static AppLogger get instance {
    if (_instance == null) {
      // Auto-initialize with defaults if not explicitly initialized
      initialize();
    }
    return _instance!;
  }

  /// Creates a tagged logger for a specific feature/component.
  static AppLogger tagged(String tag) {
    return AppLogger._(
      config: instance._config,
      tag: tag,
    );
  }

  /// Logs a debug message.
  void debug(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.debug, message, metadata: metadata);
  }

  /// Logs an info message.
  void info(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.info, message, metadata: metadata);
  }

  /// Logs a warning message.
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Logs an error message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Logs a fatal error message.
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // Check minimum level
    if (level.index < _config.minLevel.index) {
      return;
    }

    // Apply privacy filter
    final safeMessage =
        _config.enablePrivacyFilter ? _sanitize(message) : message;
    final safeMetadata = _config.enablePrivacyFilter && metadata != null
        ? _sanitizeMetadata(metadata)
        : metadata;

    final entry = LogEntry(
      level: level,
      message: safeMessage,
      timestamp: DateTime.now(),
      tag: _tag,
      error: error,
      stackTrace: stackTrace,
      metadata: safeMetadata,
    );

    for (final output in _outputs) {
      output.output(entry);
    }
  }

  /// Sanitizes a message to remove potentially sensitive data.
  String _sanitize(String message) {
    var result = message;

    // Redact anything that looks like a password parameter
    result = result.replaceAllMapped(
      RegExp(r'password[=:]\s*[^\s&]+', caseSensitive: false),
      (m) => 'password=[REDACTED]',
    );

    // Redact authorization headers
    result = result.replaceAllMapped(
      RegExp(r'(authorization|bearer)\s*[=:]\s*[^\s]+', caseSensitive: false),
      (m) => '${m.group(1)}=[REDACTED]',
    );

    // Redact tokens (anything that looks like a JWT or long alphanumeric)
    result = result.replaceAllMapped(
      RegExp(r'token[=:]\s*[A-Za-z0-9._-]{20,}', caseSensitive: false),
      (m) => 'token=[REDACTED]',
    );

    // Redact URLs with credentials
    result = result.replaceAllMapped(
      RegExp(r'https?://[^:]+:[^@]+@', caseSensitive: false),
      (m) => 'https://[REDACTED]@',
    );

    return result;
  }

  /// Sanitizes metadata map.
  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final result = <String, dynamic>{};

    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      if (_sensitiveKeys.contains(key)) {
        result[entry.key] = '[REDACTED]';
      } else if (entry.value is String) {
        result[entry.key] = _sanitize(entry.value as String);
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] =
            _sanitizeMetadata(entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  static const _sensitiveKeys = {
    'password',
    'secret',
    'token',
    'apikey',
    'api_key',
    'authorization',
    'credential',
    'credentials',
  };

  /// Flushes all log outputs.
  Future<void> flush() async {
    for (final output in _outputs) {
      await output.flush();
    }
  }

  /// Disposes all log outputs.
  Future<void> dispose() async {
    for (final output in _outputs) {
      await output.dispose();
    }
    _outputs.clear();
  }
}

/// Convenience mixin for classes that need logging.
mixin Loggable {
  /// Logger instance for this class.
  /// Override the tag to customize.
  AppLogger get logger => AppLogger.tagged(runtimeType.toString());
}
