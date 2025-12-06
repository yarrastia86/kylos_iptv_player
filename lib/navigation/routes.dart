// Kylos IPTV Player - Routes
// Route path constants for the application.

/// Route path constants.
///
/// All route paths are defined here for type-safe navigation.
abstract class Routes {
  Routes._();

  // Onboarding flow
  static const String onboarding = '/onboarding';
  static const String addPlaylist = '/onboarding/add-playlist';

  // Dashboard (main home)
  static const String dashboard = '/';

  // Main content screens (no bottom nav)
  static const String liveTV = '/live-tv';
  static const String liveTvCategory = '/live-tv/category/:categoryId';
  static const String vod = '/vod';
  static const String vodCategory = '/vod/category/:categoryId';
  static const String series = '/series';
  static const String seriesCategory = '/series/category/:categoryId';
  static const String favorites = '/favorites';
  static const String settings = '/settings';

  // Legacy alias for backwards compatibility
  static const String home = dashboard;

  // Detail screens
  static const String channelDetail = '/live-tv/channel/:id';
  static const String movieDetail = '/vod/movie/:id';
  static const String seriesDetail = '/series/:id';
  static const String episodeDetail = '/series/:seriesId/episode/:episodeId';

  // Player
  static const String player = '/player';

  // Settings sub-screens
  static const String playbackSettings = '/settings/playback';
  static const String parentalControl = '/settings/parental';
  static const String playlists = '/settings/playlists';
  static const String addPlaylistFromSettings = '/settings/playlists/add';
  static const String profiles = '/settings/profiles';
  static const String about = '/settings/about';
  static const String deviceManagement = '/settings/devices';

  // Search
  static const String search = '/search';

  // Monetization
  static const String paywall = '/pro';

  // Helper methods for parameterized routes
  static String liveTvCategoryPath(String categoryId) =>
      '/live-tv/category/$categoryId';
  static String vodCategoryPath(String categoryId) =>
      '/vod/category/$categoryId';
  static String seriesCategoryPath(String categoryId) =>
      '/series/category/$categoryId';
  static String channelDetailPath(String id) => '/live-tv/channel/$id';
  static String movieDetailPath(String id) => '/vod/movie/$id';
  static String seriesDetailPath(String id) => '/series/$id';
  static String episodeDetailPath(String seriesId, String episodeId) =>
      '/series/$seriesId/episode/$episodeId';
}
