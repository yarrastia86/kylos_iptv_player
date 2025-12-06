// Kylos IPTV Player - Firebase Analytics Service
// Firebase Analytics implementation of AnalyticsService.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/analytics/analytics_service.dart';

/// Firebase Analytics implementation of [AnalyticsService].
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  bool _isInitialized = false;

  /// Get the analytics observer for GoRouter navigation tracking.
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
        analytics: _analytics,
        nameExtractor: (settings) => settings.name ?? 'unknown',
      );

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Set default event parameters
      await _analytics.setDefaultEventParameters({
        'app_name': 'kylos_iptv_player',
      });

      _isInitialized = true;
      debugPrint('FirebaseAnalytics: Initialized');
    } catch (e) {
      debugPrint('FirebaseAnalytics: Initialization failed: $e');
    }
  }

  @override
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    if (!_isInitialized) return;

    try {
      // Sanitize parameters for Firebase (no null values, limited types)
      final sanitizedParams = _sanitizeParams(params);

      await _analytics.logEvent(
        name: _sanitizeEventName(name),
        parameters: sanitizedParams,
      );

      if (kDebugMode) {
        debugPrint('FirebaseAnalytics: Event logged: $name, params: $sanitizedParams');
      }
    } catch (e) {
      debugPrint('FirebaseAnalytics: Failed to log event "$name": $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (!_isInitialized) return;

    try {
      await _analytics.setUserProperty(
        name: _sanitizePropertyName(name),
        value: value,
      );

      if (kDebugMode) {
        debugPrint('FirebaseAnalytics: User property set: $name = $value');
      }
    } catch (e) {
      debugPrint('FirebaseAnalytics: Failed to set user property "$name": $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) return;

    try {
      await _analytics.setUserId(id: userId);
      debugPrint('FirebaseAnalytics: User ID set: ${userId != null ? "[set]" : "[cleared]"}');
    } catch (e) {
      debugPrint('FirebaseAnalytics: Failed to set user ID: $e');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {
    if (!_isInitialized) return;

    try {
      // Use logScreenView instead of deprecated setCurrentScreen
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('FirebaseAnalytics: Failed to set current screen: $e');
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {
      'screen_name': screenName,
    });
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;

    try {
      await _analytics.resetAnalyticsData();
      debugPrint('FirebaseAnalytics: Analytics data reset');
    } catch (e) {
      debugPrint('FirebaseAnalytics: Failed to reset analytics: $e');
    }
  }

  /// Sanitize event name for Firebase (lowercase, underscores, max 40 chars).
  String _sanitizeEventName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .substring(0, name.length > 40 ? 40 : name.length);
  }

  /// Sanitize property name for Firebase (lowercase, underscores, max 24 chars).
  String _sanitizePropertyName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .substring(0, name.length > 24 ? 24 : name.length);
  }

  /// Sanitize parameters for Firebase Analytics.
  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;

    final sanitized = <String, Object>{};
    for (final entry in params.entries) {
      final key = _sanitizePropertyName(entry.key);
      final value = entry.value;

      if (value == null) continue;

      // Firebase accepts String, int, double
      if (value is String) {
        // Truncate strings to 100 chars
        sanitized[key] = value.length > 100 ? value.substring(0, 100) : value;
      } else if (value is int) {
        sanitized[key] = value;
      } else if (value is double) {
        sanitized[key] = value;
      } else if (value is bool) {
        sanitized[key] = value ? 1 : 0;
      } else {
        // Convert other types to string
        sanitized[key] = value.toString();
      }
    }

    return sanitized.isEmpty ? null : sanitized;
  }

  // ============================================================
  // CONVENIENCE METHODS FOR COMMON EVENTS
  // ============================================================

  /// Log when user signs in.
  Future<void> logSignIn(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log when user signs up.
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Log purchase event.
  Future<void> logPurchase({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          price: price,
        ),
      ],
    );
  }

  /// Log view of promotional content.
  Future<void> logViewPromotion(String promotionId, String promotionName) async {
    await _analytics.logViewPromotion(
      promotionId: promotionId,
      promotionName: promotionName,
    );
  }

  /// Log search event.
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  /// Log content selection.
  Future<void> logSelectContent(String contentType, String itemId) async {
    await _analytics.logSelectContent(
      contentType: contentType,
      itemId: itemId,
    );
  }
}
