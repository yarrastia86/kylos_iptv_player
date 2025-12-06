// Kylos IPTV Player - Analytics Events
// Constants for analytics event names and parameters.

/// Analytics event names.
///
/// Use these constants to ensure consistent event naming across the app.
abstract class AnalyticsEvents {
  AnalyticsEvents._();

  // ============================================================
  // APP LIFECYCLE EVENTS
  // ============================================================

  /// App opened (session start).
  static const String appOpen = 'app_open';

  /// App backgrounded.
  static const String appBackground = 'app_background';

  /// App resumed from background.
  static const String appResume = 'app_resume';

  // ============================================================
  // CONTENT EVENTS
  // ============================================================

  /// Content playback started.
  static const String contentPlayed = 'content_played';

  /// Content playback completed (>90% watched).
  static const String contentCompleted = 'content_completed';

  /// Content playback paused.
  static const String contentPaused = 'content_paused';

  /// Content playback resumed.
  static const String contentResumed = 'content_resumed';

  /// Content playback stopped before completion.
  static const String contentStopped = 'content_stopped';

  /// Content added to favorites.
  static const String favoriteAdded = 'favorite_added';

  /// Content removed from favorites.
  static const String favoriteRemoved = 'favorite_removed';

  /// Content searched.
  static const String searchPerformed = 'search_performed';

  // ============================================================
  // NAVIGATION EVENTS
  // ============================================================

  /// Section changed (Live TV, Movies, Series).
  static const String sectionChanged = 'section_changed';

  /// Category selected.
  static const String categorySelected = 'category_selected';

  // ============================================================
  // FEATURE USAGE EVENTS
  // ============================================================

  /// Feature used (for tracking feature adoption).
  static const String featureUsed = 'feature_used';

  /// Playlist added.
  static const String playlistAdded = 'playlist_added';

  /// Playlist removed.
  static const String playlistRemoved = 'playlist_removed';

  /// Profile created.
  static const String profileCreated = 'profile_created';

  /// Profile switched.
  static const String profileSwitched = 'profile_switched';

  /// EPG guide viewed.
  static const String epgViewed = 'epg_viewed';

  /// Settings changed.
  static const String settingsChanged = 'settings_changed';

  // ============================================================
  // MONETIZATION EVENTS
  // ============================================================

  /// Paywall viewed.
  static const String paywallViewed = 'paywall_viewed';

  /// Subscription started.
  static const String subscriptionStarted = 'subscription_started';

  /// Subscription cancelled.
  static const String subscriptionCancelled = 'subscription_cancelled';

  /// Purchase failed.
  static const String purchaseFailed = 'purchase_failed';

  /// Purchases restored.
  static const String purchasesRestored = 'purchases_restored';

  /// Upgrade prompt shown.
  static const String upgradePromptShown = 'upgrade_prompt_shown';

  /// Upgrade prompt dismissed.
  static const String upgradePromptDismissed = 'upgrade_prompt_dismissed';

  /// Upgrade prompt accepted (user went to paywall).
  static const String upgradePromptAccepted = 'upgrade_prompt_accepted';

  // ============================================================
  // AD EVENTS
  // ============================================================

  /// Ad shown to user.
  static const String adShown = 'ad_shown';

  /// Ad clicked.
  static const String adClicked = 'ad_clicked';

  /// Ad failed to load.
  static const String adFailed = 'ad_failed';

  /// Ad skipped by user.
  static const String adSkipped = 'ad_skipped';

  /// Rewarded ad completed.
  static const String rewardedAdCompleted = 'rewarded_ad_completed';

  // ============================================================
  // AUTH EVENTS
  // ============================================================

  /// User signed in.
  static const String signIn = 'sign_in';

  /// User signed out.
  static const String signOut = 'sign_out';

  /// User registered.
  static const String signUp = 'sign_up';

  /// Anonymous user upgraded to full account.
  static const String accountUpgraded = 'account_upgraded';

  // ============================================================
  // ERROR EVENTS
  // ============================================================

  /// Playback error occurred.
  static const String playbackError = 'playback_error';

  /// Network error occurred.
  static const String networkError = 'network_error';

  /// General error occurred.
  static const String errorOccurred = 'error_occurred';
}

/// Analytics parameter keys.
///
/// Use these constants for consistent parameter naming.
abstract class AnalyticsParams {
  AnalyticsParams._();

  // ============================================================
  // CONTENT PARAMETERS
  // ============================================================

  /// Type of content (liveChannel, vod, episode).
  static const String contentType = 'content_type';

  /// ID of the content.
  static const String contentId = 'content_id';

  /// Name/title of the content.
  static const String contentName = 'content_name';

  /// Duration of content in seconds.
  static const String duration = 'duration';

  /// Watch time in seconds.
  static const String watchTime = 'watch_time';

  /// Completion percentage (0-100).
  static const String completionPercent = 'completion_percent';

  /// Category ID.
  static const String categoryId = 'category_id';

  /// Category name.
  static const String categoryName = 'category_name';

  // ============================================================
  // SECTION PARAMETERS
  // ============================================================

  /// Section name (live_tv, movies, series).
  static const String sectionName = 'section_name';

  /// Previous section name.
  static const String fromSection = 'from_section';

  // ============================================================
  // FEATURE PARAMETERS
  // ============================================================

  /// Name of the feature.
  static const String featureName = 'feature_name';

  /// User's subscription tier.
  static const String tier = 'tier';

  /// Whether feature is premium.
  static const String isPremium = 'is_premium';

  // ============================================================
  // MONETIZATION PARAMETERS
  // ============================================================

  /// Product ID.
  static const String productId = 'product_id';

  /// Price as string.
  static const String price = 'price';

  /// Currency code.
  static const String currency = 'currency';

  /// Source that triggered the paywall.
  static const String paywallSource = 'paywall_source';

  /// Trigger that caused upgrade prompt.
  static const String promptTrigger = 'prompt_trigger';

  // ============================================================
  // AD PARAMETERS
  // ============================================================

  /// Type of ad (banner, interstitial, rewarded).
  static const String adType = 'ad_type';

  /// Placement identifier for the ad.
  static const String adPlacement = 'ad_placement';

  /// Ad unit ID.
  static const String adUnitId = 'ad_unit_id';

  // ============================================================
  // AUTH PARAMETERS
  // ============================================================

  /// Auth provider (google, email, anonymous).
  static const String authProvider = 'auth_provider';

  // ============================================================
  // ERROR PARAMETERS
  // ============================================================

  /// Error code.
  static const String errorCode = 'error_code';

  /// Error message.
  static const String errorMessage = 'error_message';

  // ============================================================
  // SESSION PARAMETERS
  // ============================================================

  /// Session count.
  static const String sessionCount = 'session_count';

  /// Days since install.
  static const String daysSinceInstall = 'days_since_install';

  /// Platform (android, ios).
  static const String platform = 'platform';

  /// Form factor (mobile, tablet, tv).
  static const String formFactor = 'form_factor';
}

/// User properties for analytics segmentation.
abstract class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  /// User's subscription tier (free, pro).
  static const String subscriptionTier = 'subscription_tier';

  /// Days since app install.
  static const String daysSinceInstall = 'days_since_install';

  /// Number of playlists.
  static const String playlistCount = 'playlist_count';

  /// Number of favorites.
  static const String favoriteCount = 'favorite_count';

  /// Total watch time in minutes.
  static const String totalWatchTime = 'total_watch_time';

  /// Preferred content type.
  static const String preferredContentType = 'preferred_content_type';

  /// App version.
  static const String appVersion = 'app_version';

  /// Device form factor.
  static const String formFactor = 'form_factor';

  /// Whether user has Pro.
  static const String hasPro = 'has_pro';

  /// Number of sessions.
  static const String sessionCount = 'session_count';
}
