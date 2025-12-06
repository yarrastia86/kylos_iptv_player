// Kylos IPTV Player - Analytics Service Interface
// Abstract interface for analytics tracking.

/// Abstract interface for analytics services.
///
/// Implementations handle specific analytics platforms (Firebase, Mixpanel, etc.).
abstract class AnalyticsService {
  /// Initialize the analytics service.
  Future<void> initialize();

  /// Log an event with optional parameters.
  Future<void> logEvent(String name, [Map<String, dynamic>? params]);

  /// Set a user property for segmentation.
  Future<void> setUserProperty(String name, String? value);

  /// Set the user ID for cross-device tracking.
  Future<void> setUserId(String? userId);

  /// Set the current screen for screen tracking.
  Future<void> setCurrentScreen(String screenName, {String? screenClass});

  /// Log a screen view event.
  Future<void> logScreenView(String screenName);

  /// Reset analytics data (e.g., on logout).
  Future<void> reset();
}

/// Mock analytics service for testing or platforms without analytics.
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> reset() async {}
}
