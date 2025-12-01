# MyIPTV Player - Flutter Architecture and Project Structure

## Document Version

| Version | Date       | Author          | Description                     |
|---------|------------|-----------------|--------------------------------|
| 1.0     | 2024-01-XX | Architecture    | Initial architecture design    |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview](#2-architecture-overview)
3. [Project Structure](#3-project-structure)
4. [State Management Architecture](#4-state-management-architecture)
5. [Recommended Packages](#5-recommended-packages)
6. [Sample File Tree](#6-sample-file-tree)
7. [Flutter Skeleton Implementation](#7-flutter-skeleton-implementation)
8. [Platform-Specific Considerations](#8-platform-specific-considerations)

---

## 1. Executive Summary

This document defines the Flutter client architecture for MyIPTV Player, a cross-platform IPTV application targeting mobile devices (Android/iOS), TV platforms (Android TV/Fire TV), and with future extensibility toward Samsung Tizen.

### Key Architectural Decisions

| Decision                  | Choice                | Rationale                                                    |
|--------------------------|----------------------|-------------------------------------------------------------|
| State Management         | Riverpod 2.x         | Type-safe, testable, compile-time safety, no context needed |
| Architecture Pattern     | Clean Architecture   | Separation of concerns, testability, maintainability        |
| Navigation              | go_router            | Declarative, deep linking, TV navigation compatible         |
| DI Approach             | Riverpod providers   | Built-in with state management, no additional framework     |
| Project Structure       | Feature-first modular| Scalable, team-friendly, clear boundaries                   |

### Why Riverpod Over Bloc?

1. **Compile-time safety**: Riverpod catches provider dependency errors at compile time.
2. **No BuildContext dependency**: Critical for TV platforms where widget trees differ significantly.
3. **Code generation support**: Reduces boilerplate with `riverpod_generator`.
4. **Simpler testing**: Providers can be easily overridden without complex setup.
5. **Better for async data**: Built-in `AsyncValue` handles loading/error states elegantly.
6. **Flexible scoping**: Can scope state per feature, per screen, or globally as needed.

---

## 2. Architecture Overview

### 2.1 Clean Architecture Layers

```
+------------------------------------------------------------------+
|                      PRESENTATION LAYER                           |
|  (Widgets, Screens, Controllers, ViewModels via Riverpod)        |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                        DOMAIN LAYER                               |
|  (Entities, Use Cases, Repository Interfaces, Value Objects)     |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    INFRASTRUCTURE LAYER                           |
|  (Repository Implementations, Data Sources, APIs, Parsers)       |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                      EXTERNAL SERVICES                            |
|  (Firebase, IPTV Providers, Local Storage, Platform APIs)        |
+------------------------------------------------------------------+
```

### 2.2 Module Communication

```
+-------------+     +-------------+     +-------------+
|   Live TV   |     |     VOD     |     |   Series    |
+------+------+     +------+------+     +------+------+
       |                   |                   |
       +-------------------+-------------------+
                           |
                    +------v------+
                    |   Playback  |  <-- Shared playback module
                    +------+------+
                           |
       +-------------------+-------------------+
       |                   |                   |
+------v------+     +------v------+     +------v------+
|  Playlists  |     |   Profiles  |     | Monetization|
+-------------+     +-------------+     +-------------+
```

### 2.3 Data Flow

```
User Action
    |
    v
[Widget] --> [Controller/Notifier] --> [Use Case] --> [Repository]
                                                            |
                                                            v
                                                     [Data Source]
                                                            |
                                    +-------------------+---+-------------------+
                                    |                   |                       |
                                    v                   v                       v
                              [Remote API]       [Local Cache]           [Platform]
```

---

## 3. Project Structure

### 3.1 Package Layout

```
lib/
├── app.dart                    # App widget with MaterialApp/Router setup
├── main.dart                   # Default entry point
├── main_mobile.dart            # Mobile-specific initialization
├── main_tv.dart                # TV-specific initialization
├── bootstrap.dart              # Shared initialization logic
│
├── core/                       # Shared utilities and foundation
│   ├── constants/
│   ├── design_system/
│   ├── error/
│   ├── extensions/
│   ├── network/
│   ├── platform/
│   ├── storage/
│   └── utils/
│
├── features/                   # Feature modules (vertical slices)
│   ├── live_tv/
│   ├── vod/
│   ├── series/
│   ├── playback/
│   ├── playlists/
│   ├── profiles/
│   ├── favorites/
│   ├── epg/
│   ├── search/
│   ├── settings/
│   ├── monetization/
│   ├── onboarding/
│   └── parental_control/
│
├── infrastructure/             # External integrations
│   ├── iptv/
│   ├── epg/
│   ├── firebase/
│   ├── analytics/
│   ├── push_notifications/
│   └── remote_config/
│
├── navigation/                 # Routing configuration
│   ├── app_router.dart
│   ├── routes.dart
│   └── guards/
│
└── shared/                     # Shared widgets and utilities
    ├── widgets/
    ├── providers/
    └── models/
```

### 3.2 Feature Module Structure

Each feature follows a consistent internal structure:

```
features/live_tv/
├── data/
│   ├── datasources/
│   │   ├── live_tv_local_datasource.dart
│   │   └── live_tv_remote_datasource.dart
│   ├── models/
│   │   ├── channel_model.dart
│   │   └── channel_model.g.dart
│   └── repositories/
│       └── live_tv_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── channel.dart
│   │   └── channel_category.dart
│   ├── repositories/
│   │   └── live_tv_repository.dart
│   └── usecases/
│       ├── get_channels.dart
│       ├── get_categories.dart
│       └── switch_channel.dart
│
└── presentation/
    ├── controllers/
    │   ├── live_tv_controller.dart
    │   └── channel_list_controller.dart
    ├── providers/
    │   └── live_tv_providers.dart
    ├── screens/
    │   ├── live_tv_screen.dart
    │   └── channel_detail_screen.dart
    └── widgets/
        ├── channel_tile.dart
        ├── channel_grid.dart
        └── category_selector.dart
```

### 3.3 Multi-Package Consideration

For a large team or complex app, consider a federated structure:

```
packages/
├── myiptv_core/              # Shared core utilities
├── myiptv_design_system/     # UI components and theming
├── myiptv_iptv_client/       # IPTV parsing and streaming logic
├── myiptv_player_engine/     # Video player abstraction
└── myiptv_analytics/         # Analytics wrapper

app/                          # Main application
└── lib/
    └── features/...
```

**Recommendation**: Start with a monolithic structure, refactor to multi-package when team size exceeds 5 developers or when code sharing across apps becomes necessary.

---

## 4. State Management Architecture

### 4.1 Provider Categories

```dart
// Global application state (singleton lifetime)
@riverpod
class AppSettings extends _$AppSettings { ... }

// Feature-scoped state (disposed when feature is closed)
@riverpod
class LiveTvController extends _$LiveTvController { ... }

// Screen-scoped state (disposed when screen pops)
@riverpod
class ChannelDetailController extends _$ChannelDetailController { ... }

// Derived/computed state (auto-cached)
@riverpod
List<Channel> filteredChannels(FilteredChannelsRef ref) { ... }
```

### 4.2 State Representations

#### 4.2.1 Playlist Sources and Active Provider

```dart
// Domain Entity
class PlaylistSource {
  final String id;
  final String name;
  final PlaylistType type; // m3u_url, m3u_file, xtream_api
  final String endpoint;
  final DateTime? lastRefresh;
  final PlaylistStatus status;
}

// State Provider
@riverpod
class PlaylistsController extends _$PlaylistsController {
  @override
  Future<List<PlaylistSource>> build() async {
    return ref.watch(playlistRepositoryProvider).getAllPlaylists();
  }

  Future<void> addPlaylist(PlaylistSource source) async { ... }
  Future<void> removePlaylist(String id) async { ... }
  Future<void> refreshPlaylist(String id) async { ... }
}

@riverpod
class ActivePlaylistController extends _$ActivePlaylistController {
  @override
  PlaylistSource? build() {
    // Load from local storage on init
    return ref.watch(localStorageProvider).getActivePlaylist();
  }

  void setActive(PlaylistSource source) {
    state = source;
    ref.read(localStorageProvider).saveActivePlaylist(source);
    // Invalidate dependent providers
    ref.invalidate(channelListProvider);
    ref.invalidate(epgDataProvider);
  }
}
```

#### 4.2.2 Live Channel Lists and EPG Data

```dart
// Paginated channel list with categories
@riverpod
class ChannelListController extends _$ChannelListController {
  static const _pageSize = 50;

  @override
  Future<PaginatedChannels> build({String? categoryId}) async {
    final playlist = ref.watch(activePlaylistControllerProvider);
    if (playlist == null) return PaginatedChannels.empty();

    return _fetchChannels(page: 0, categoryId: categoryId);
  }

  Future<void> loadNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore) return;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true),
    );

    final nextPage = await _fetchChannels(
      page: currentState.currentPage + 1,
      categoryId: currentState.categoryId,
    );

    state = AsyncValue.data(
      currentState.merge(nextPage),
    );
  }
}

// EPG data with lazy loading per channel
@riverpod
class EpgController extends _$EpgController {
  @override
  Future<EpgData> build() async {
    final playlist = ref.watch(activePlaylistControllerProvider);
    if (playlist == null) return EpgData.empty();

    // Load EPG index (lightweight)
    return ref.watch(epgRepositoryProvider).getEpgIndex(playlist.id);
  }

  Future<List<EpgProgram>> getChannelPrograms(String channelId) async {
    // Lazy load full program data for specific channel
    return ref.watch(epgRepositoryProvider).getChannelPrograms(channelId);
  }
}
```

#### 4.2.3 Playback State

```dart
// Unified playback state for all content types
@freezed
class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    required PlaybackStatus status,
    PlayableContent? currentContent,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? playbackSpeed,
    List<AudioTrack>? audioTracks,
    AudioTrack? selectedAudioTrack,
    List<Subtitle>? subtitles,
    Subtitle? selectedSubtitle,
    PlayerError? error,
  }) = _PlaybackState;
}

enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
  ended,
}

@riverpod
class PlaybackController extends _$PlaybackController {
  VideoPlayerController? _playerController;

  @override
  PlaybackState build() {
    ref.onDispose(() => _playerController?.dispose());
    return const PlaybackState(status: PlaybackStatus.idle);
  }

  Future<void> play(PlayableContent content) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentContent: content,
    );

    try {
      _playerController = await _initializePlayer(content);
      await _playerController!.play();
      state = state.copyWith(status: PlaybackStatus.playing);
      _startPositionTracking();
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        error: PlayerError.fromException(e),
      );
    }
  }

  void pause() { ... }
  void resume() { ... }
  void seek(Duration position) { ... }
  void setAudioTrack(AudioTrack track) { ... }
  void setSubtitle(Subtitle? subtitle) { ... }
  void stop() { ... }
}
```

#### 4.2.4 User Profile, Favorites, and Parental Control

```dart
// User profile with sync capability
@riverpod
class UserProfileController extends _$UserProfileController {
  @override
  Future<UserProfile> build() async {
    final localProfile = await ref.watch(localStorageProvider).getProfile();
    final authState = ref.watch(authControllerProvider);

    if (authState.isAuthenticated) {
      // Sync with remote
      return _syncProfile(localProfile);
    }

    return localProfile ?? UserProfile.guest();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await ref.read(localStorageProvider).saveProfile(profile);

    if (ref.read(authControllerProvider).isAuthenticated) {
      await ref.read(backendSyncProvider).syncProfile(profile);
    }

    ref.invalidateSelf();
  }
}

// Favorites with local-first, sync-later pattern
@riverpod
class FavoritesController extends _$FavoritesController {
  @override
  Future<List<Favorite>> build() async {
    return ref.watch(favoritesRepositoryProvider).getAllFavorites();
  }

  Future<void> addFavorite(PlayableContent content) async {
    final favorite = Favorite.fromContent(content);
    await ref.read(favoritesRepositoryProvider).add(favorite);
    ref.invalidateSelf();
    _scheduleSync();
  }

  Future<void> removeFavorite(String id) async {
    await ref.read(favoritesRepositoryProvider).remove(id);
    ref.invalidateSelf();
    _scheduleSync();
  }

  void _scheduleSync() {
    // Debounced sync to backend
    ref.read(syncSchedulerProvider).scheduleFavoritesSync();
  }
}

// Parental control with PIN protection
@riverpod
class ParentalControlController extends _$ParentalControlController {
  @override
  ParentalControlState build() {
    return ParentalControlState(
      isEnabled: ref.watch(settingsProvider).parentalControlEnabled,
      isUnlocked: false,
      rating: ref.watch(settingsProvider).maxAllowedRating,
    );
  }

  bool canAccess(ContentRating rating) {
    if (!state.isEnabled) return true;
    if (state.isUnlocked) return true;
    return rating.value <= state.rating.value;
  }

  Future<bool> unlock(String pin) async {
    final isValid = await ref.read(secureStorageProvider).verifyPin(pin);
    if (isValid) {
      state = state.copyWith(isUnlocked: true);
      _scheduleAutoLock();
    }
    return isValid;
  }

  void lock() {
    state = state.copyWith(isUnlocked: false);
  }
}
```

#### 4.2.5 Monetization State

```dart
// Entitlements with caching and remote verification
@riverpod
class EntitlementsController extends _$EntitlementsController {
  @override
  Future<Entitlements> build() async {
    // Check cached entitlements first
    final cached = await ref.watch(localStorageProvider).getCachedEntitlements();

    if (cached != null && !cached.isExpired) {
      // Refresh in background
      _refreshInBackground();
      return cached;
    }

    // Fetch from server
    return _fetchEntitlements();
  }

  Future<Entitlements> _fetchEntitlements() async {
    final authState = ref.read(authControllerProvider);

    if (!authState.isAuthenticated) {
      return Entitlements.free();
    }

    try {
      final entitlements = await ref.read(monetizationRepositoryProvider)
          .getEntitlements(authState.userId!);

      await ref.read(localStorageProvider).cacheEntitlements(entitlements);
      return entitlements;
    } catch (e) {
      // Fallback to cached on network error
      final cached = await ref.read(localStorageProvider).getCachedEntitlements();
      return cached ?? Entitlements.free();
    }
  }

  bool get isPro => state.valueOrNull?.isPro ?? false;

  bool hasFeature(ProFeature feature) {
    return state.valueOrNull?.hasFeature(feature) ?? false;
  }
}

// Purchase flow
@riverpod
class PurchaseController extends _$PurchaseController {
  @override
  PurchaseState build() => const PurchaseState.idle();

  Future<void> purchasePro() async {
    state = const PurchaseState.loading();

    try {
      final result = await ref.read(iapServiceProvider).purchase(Products.proAnnual);

      if (result.isSuccess) {
        // Verify with backend
        await ref.read(monetizationRepositoryProvider).verifyPurchase(result.receipt);

        // Refresh entitlements
        ref.invalidate(entitlementsControllerProvider);

        state = const PurchaseState.success();
      } else {
        state = PurchaseState.error(result.error);
      }
    } catch (e) {
      state = PurchaseState.error(PurchaseError.unknown(e.toString()));
    }
  }

  Future<void> restorePurchases() async { ... }
}
```

### 4.3 Backend Coordination

#### 4.3.1 Settings Sync

```dart
@riverpod
class SettingsSyncController extends _$SettingsSyncController {
  Timer? _debounceTimer;

  @override
  SyncStatus build() => const SyncStatus.synced();

  void onSettingChanged(String key, dynamic value) {
    // Save locally immediately
    ref.read(localStorageProvider).saveSetting(key, value);

    // Debounce remote sync
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _syncToRemote);

    state = const SyncStatus.pending();
  }

  Future<void> _syncToRemote() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;

    try {
      final settings = await ref.read(localStorageProvider).getAllSettings();
      await ref.read(backendClientProvider).syncSettings(settings);
      state = const SyncStatus.synced();
    } catch (e) {
      state = SyncStatus.error(e.toString());
      // Retry later
      _scheduleRetry();
    }
  }
}
```

#### 4.3.2 Entitlements Storage

```dart
@riverpod
class EntitlementsSyncService extends _$EntitlementsSyncService {
  @override
  void build() {
    // Listen to purchase events
    ref.listen(purchaseControllerProvider, (previous, next) {
      if (next is PurchaseStateSuccess) {
        _syncEntitlementsToBackend();
      }
    });
  }

  Future<void> _syncEntitlementsToBackend() async {
    final entitlements = await ref.read(iapServiceProvider).getAllPurchases();

    await ref.read(backendClientProvider).updateEntitlements(
      userId: ref.read(authControllerProvider).userId!,
      entitlements: entitlements,
    );
  }
}
```

#### 4.3.3 Push Notifications

```dart
@riverpod
class PushNotificationController extends _$PushNotificationController {
  @override
  Future<void> build() async {
    final messaging = ref.watch(firebaseMessagingProvider);

    // Request permission
    await messaging.requestPermission();

    // Get token and register with backend
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  Future<void> _registerToken(String token) async {
    await ref.read(backendClientProvider).registerPushToken(
      userId: ref.read(authControllerProvider).userId,
      token: token,
      platform: Platform.operatingSystem,
    );
  }

  void _handleMessage(RemoteMessage message) {
    final type = NotificationType.fromString(message.data['type']);

    switch (type) {
      case NotificationType.newContent:
        ref.invalidate(channelListControllerProvider);
        break;
      case NotificationType.entitlementUpdate:
        ref.invalidate(entitlementsControllerProvider);
        break;
      case NotificationType.maintenance:
        ref.read(maintenanceControllerProvider.notifier).show(message);
        break;
    }
  }
}
```

---

## 5. Recommended Packages

### 5.1 Core Packages

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| State Management      | `riverpod` + `riverpod_annotation` + `riverpod_generator` | Type-safe reactive state |
| Code Generation       | `freezed` + `json_serializable` | Immutable models, JSON serialization |
| Navigation            | `go_router`                | Declarative routing with deep links        |
| DI                    | Built into Riverpod        | No additional package needed               |

### 5.2 Video Playback

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| Primary Player        | `media_kit`                | Cross-platform video (libmpv-based)        |
| Alternative           | `video_player` + `chewie`  | Official Flutter, simpler but limited      |
| HLS/DASH              | Handled by media_kit       | Native protocol support                    |
| Casting               | `cast`                     | Chromecast support                         |

**Recommendation**: Use `media_kit` for its superior codec support, HLS/DASH handling, and TV platform compatibility. Wrap in an abstraction layer for future flexibility.

### 5.3 Backend and Remote Services

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| Firebase Core         | `firebase_core`            | Firebase initialization                    |
| Authentication        | `firebase_auth`            | User authentication                        |
| Cloud Firestore       | `cloud_firestore`          | Realtime database                          |
| Remote Config         | `firebase_remote_config`   | Feature flags and A/B testing              |
| Push Notifications    | `firebase_messaging`       | FCM integration                            |
| Crashlytics           | `firebase_crashlytics`     | Crash reporting                            |
| Analytics             | `firebase_analytics`       | User analytics                             |

### 5.4 Local Storage and Caching

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| Structured Storage    | `isar`                     | Fast NoSQL database, great for large data  |
| Key-Value             | `shared_preferences`       | Simple settings storage                    |
| Secure Storage        | `flutter_secure_storage`   | PIN, tokens, sensitive data                |
| HTTP Caching          | `dio` with `dio_cache_interceptor` | Network response caching         |
| Image Caching         | `cached_network_image`     | Channel logos, posters                     |

### 5.5 Networking

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| HTTP Client           | `dio`                      | Powerful HTTP with interceptors            |
| Connectivity          | `connectivity_plus`        | Network state monitoring                   |
| XML Parsing           | `xml`                      | XMLTV EPG parsing                          |

### 5.6 TV and Platform-Specific

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| TV Focus              | `flutter_tv` or custom     | D-pad navigation support                   |
| Shortcuts             | Built-in `Shortcuts`       | Keyboard/remote handling                   |
| Platform Integration  | `wakelock`                 | Prevent screen sleep during playback       |
| PiP                   | `floating` or platform channels | Picture-in-Picture                   |

### 5.7 Monetization

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| In-App Purchases      | `in_app_purchase`          | Official IAP plugin                        |
| RevenueCat (Alt)      | `purchases_flutter`        | Simplified IAP with backend                |

### 5.8 Development and Quality

| Category               | Package                    | Purpose                                    |
|-----------------------|----------------------------|--------------------------------------------|
| Linting               | `very_good_analysis`       | Strict lint rules                          |
| Testing               | `mocktail`                 | Mocking for tests                          |
| Golden Tests          | `golden_toolkit`           | Screenshot testing                         |

---

## 6. Sample File Tree

```
myiptv_player/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
│
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── main_mobile.dart
│   ├── main_tv.dart
│   ├── bootstrap.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── storage_keys.dart
│   │   │
│   │   ├── design_system/
│   │   │   ├── design_system.dart           # Barrel export
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   ├── app_typography.dart
│   │   │   │   └── tv_theme.dart
│   │   │   ├── tokens/
│   │   │   │   ├── spacing.dart
│   │   │   │   └── radii.dart
│   │   │   └── components/
│   │   │       ├── buttons/
│   │   │       ├── cards/
│   │   │       └── inputs/
│   │   │
│   │   ├── error/
│   │   │   ├── exceptions.dart
│   │   │   ├── failures.dart
│   │   │   └── error_handler.dart
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   ├── string_extensions.dart
│   │   │   └── duration_extensions.dart
│   │   │
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── network_info.dart
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       ├── cache_interceptor.dart
│   │   │       └── logging_interceptor.dart
│   │   │
│   │   ├── platform/
│   │   │   ├── platform_info.dart
│   │   │   ├── tv_detector.dart
│   │   │   └── form_factor.dart
│   │   │
│   │   ├── storage/
│   │   │   ├── local_storage.dart
│   │   │   ├── secure_storage.dart
│   │   │   └── cache_manager.dart
│   │   │
│   │   └── utils/
│   │       ├── debouncer.dart
│   │       ├── logger.dart
│   │       └── validators.dart
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── onboarding_local_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── onboarding_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── onboarding_state.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── onboarding_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── complete_onboarding.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── onboarding_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── onboarding_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── welcome_screen.dart
│   │   │       │   └── add_playlist_screen.dart
│   │   │       └── widgets/
│   │   │           ├── playlist_type_selector.dart
│   │   │           └── url_input_field.dart
│   │   │
│   │   ├── playlists/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── playlist_local_datasource.dart
│   │   │   │   │   └── playlist_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── playlist_model.dart
│   │   │   │   │   └── playlist_model.g.dart
│   │   │   │   └── repositories/
│   │   │   │       └── playlist_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── playlist_source.dart
│   │   │   │   │   └── playlist_content.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── playlist_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── add_playlist.dart
│   │   │   │       ├── remove_playlist.dart
│   │   │   │       ├── refresh_playlist.dart
│   │   │   │       └── parse_playlist.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   ├── playlists_controller.dart
│   │   │       │   └── active_playlist_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── playlist_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── playlists_screen.dart
│   │   │       │   └── playlist_detail_screen.dart
│   │   │       └── widgets/
│   │   │           ├── playlist_tile.dart
│   │   │           └── playlist_status_badge.dart
│   │   │
│   │   ├── live_tv/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── channel_local_datasource.dart
│   │   │   │   │   └── channel_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── channel_model.dart
│   │   │   │   │   └── category_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── live_tv_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── channel.dart
│   │   │   │   │   └── channel_category.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── live_tv_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_channels.dart
│   │   │   │       ├── get_categories.dart
│   │   │   │       └── get_channel_stream.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   ├── live_tv_controller.dart
│   │   │       │   └── channel_list_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── live_tv_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── live_tv_screen.dart
│   │   │       │   └── live_tv_screen_tv.dart     # TV-specific layout
│   │   │       └── widgets/
│   │   │           ├── channel_tile.dart
│   │   │           ├── channel_grid.dart
│   │   │           ├── category_tabs.dart
│   │   │           └── now_playing_bar.dart
│   │   │
│   │   ├── vod/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── movie.dart
│   │   │   │   │   └── vod_category.dart
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   ├── vod_screen.dart
│   │   │       │   └── movie_detail_screen.dart
│   │   │       └── widgets/
│   │   │           ├── movie_card.dart
│   │   │           └── movie_grid.dart
│   │   │
│   │   ├── series/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── series.dart
│   │   │   │   │   ├── season.dart
│   │   │   │   │   └── episode.dart
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   ├── series_screen.dart
│   │   │       │   └── series_detail_screen.dart
│   │   │       └── widgets/
│   │   │           ├── series_card.dart
│   │   │           └── episode_list.dart
│   │   │
│   │   ├── playback/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── playback_history_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── playback_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── playable_content.dart
│   │   │   │   │   ├── playback_state.dart
│   │   │   │   │   ├── audio_track.dart
│   │   │   │   │   └── subtitle.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── playback_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── play_content.dart
│   │   │   │       ├── resume_content.dart
│   │   │   │       └── save_playback_position.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   ├── playback_controller.dart
│   │   │       │   └── player_ui_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── playback_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── player_screen.dart
│   │   │       │   └── player_screen_tv.dart
│   │   │       └── widgets/
│   │   │           ├── player_controls.dart
│   │   │           ├── player_controls_tv.dart
│   │   │           ├── seek_bar.dart
│   │   │           ├── audio_track_selector.dart
│   │   │           └── subtitle_selector.dart
│   │   │
│   │   ├── epg/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── epg_local_datasource.dart
│   │   │   │   │   └── epg_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── epg_program_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── epg_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── epg_program.dart
│   │   │   │   │   └── epg_schedule.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── epg_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_channel_epg.dart
│   │   │   │       └── refresh_epg.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── epg_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── epg_providers.dart
│   │   │       ├── screens/
│   │   │       │   └── epg_guide_screen.dart
│   │   │       └── widgets/
│   │   │           ├── epg_timeline.dart
│   │   │           ├── program_tile.dart
│   │   │           └── now_next_widget.dart
│   │   │
│   │   ├── favorites/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── favorites_controller.dart
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   └── favorites_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── search/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── search_controller.dart
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   └── search_screen.dart
│   │   │       └── widgets/
│   │   │           └── search_results.dart
│   │   │
│   │   ├── profiles/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user_profile.dart
│   │   │   │   └── repositories/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── profile_controller.dart
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   ├── profiles_screen.dart
│   │   │       │   └── edit_profile_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── parental_control/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── parental_control_controller.dart
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       │   └── parental_control_screen.dart
│   │   │       └── widgets/
│   │   │           └── pin_input.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── settings_local_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── app_settings.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── settings_controller.dart
│   │   │       ├── providers/
│   │   │       │   └── settings_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── settings_screen.dart
│   │   │       │   └── playback_settings_screen.dart
│   │   │       └── widgets/
│   │   │           └── settings_tile.dart
│   │   │
│   │   └── monetization/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── iap_datasource.dart
│   │       │   │   └── entitlements_remote_datasource.dart
│   │       │   └── repositories/
│   │       │       └── monetization_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   ├── entitlements.dart
│   │       │   │   ├── product.dart
│   │       │   │   └── purchase_result.dart
│   │       │   ├── repositories/
│   │       │   │   └── monetization_repository.dart
│   │       │   └── usecases/
│   │       │       ├── purchase_pro.dart
│   │       │       ├── restore_purchases.dart
│   │       │       └── verify_entitlements.dart
│   │       └── presentation/
│   │           ├── controllers/
│   │           │   ├── entitlements_controller.dart
│   │           │   └── purchase_controller.dart
│   │           ├── providers/
│   │           │   └── monetization_providers.dart
│   │           ├── screens/
│   │           │   └── paywall_screen.dart
│   │           └── widgets/
│   │               ├── pro_badge.dart
│   │               └── feature_comparison.dart
│   │
│   ├── infrastructure/
│   │   ├── iptv/
│   │   │   ├── iptv_client.dart
│   │   │   ├── m3u_parser.dart
│   │   │   ├── xtream_client.dart
│   │   │   └── models/
│   │   │       ├── m3u_entry.dart
│   │   │       └── xtream_response.dart
│   │   │
│   │   ├── epg/
│   │   │   ├── epg_parser.dart
│   │   │   ├── xmltv_parser.dart
│   │   │   └── epg_mapper.dart
│   │   │
│   │   ├── player/
│   │   │   ├── player_factory.dart
│   │   │   ├── player_interface.dart
│   │   │   └── media_kit_player.dart
│   │   │
│   │   ├── firebase/
│   │   │   ├── firebase_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   └── remote_config_service.dart
│   │   │
│   │   ├── analytics/
│   │   │   ├── analytics_service.dart
│   │   │   ├── analytics_events.dart
│   │   │   └── firebase_analytics_impl.dart
│   │   │
│   │   ├── push_notifications/
│   │   │   ├── push_notification_service.dart
│   │   │   └── notification_handler.dart
│   │   │
│   │   └── remote_config/
│   │       ├── feature_flags.dart
│   │       └── remote_config_provider.dart
│   │
│   ├── navigation/
│   │   ├── app_router.dart
│   │   ├── routes.dart
│   │   ├── route_paths.dart
│   │   └── guards/
│   │       ├── auth_guard.dart
│   │       ├── onboarding_guard.dart
│   │       └── parental_guard.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── async_value_widget.dart
│       │   ├── error_widget.dart
│       │   ├── loading_widget.dart
│       │   ├── empty_state_widget.dart
│       │   ├── focusable_widget.dart        # TV focus support
│       │   └── responsive_builder.dart
│       │
│       ├── providers/
│       │   ├── shared_providers.dart
│       │   └── platform_providers.dart
│       │
│       └── models/
│           ├── result.dart                  # Result<T, E> type
│           └── pagination.dart
│
├── test/
│   ├── unit/
│   │   ├── features/
│   │   └── infrastructure/
│   ├── widget/
│   │   └── features/
│   ├── integration/
│   ├── golden/
│   └── mocks/
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── l10n/
│
├── analysis_options.yaml
├── pubspec.yaml
├── build.yaml
└── README.md
```

---

## 7. Flutter Skeleton Implementation

### 7.1 Main Entry Point

```dart
// lib/main.dart
// Default entry point - detects platform and delegates

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:myiptv_player/bootstrap.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';

void main() {
  // Detect if running on TV platform
  final formFactor = _detectFormFactor();

  bootstrap(formFactor: formFactor);
}

FormFactor _detectFormFactor() {
  if (kIsWeb) {
    return FormFactor.web;
  }

  if (Platform.isAndroid) {
    // Android TV detection happens in bootstrap via platform channel
    return FormFactor.mobile; // Default, will be updated
  }

  if (Platform.isIOS) {
    return FormFactor.mobile;
  }

  return FormFactor.desktop;
}
```

```dart
// lib/main_mobile.dart
// Explicit mobile entry point for build variants

import 'package:myiptv_player/bootstrap.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';

void main() {
  bootstrap(formFactor: FormFactor.mobile);
}
```

```dart
// lib/main_tv.dart
// Explicit TV entry point for Android TV / Fire TV builds

import 'package:myiptv_player/bootstrap.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';

void main() {
  bootstrap(formFactor: FormFactor.tv);
}
```

### 7.2 Bootstrap

```dart
// lib/bootstrap.dart

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myiptv_player/app.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';
import 'package:myiptv_player/shared/providers/platform_providers.dart';

Future<void> bootstrap({required FormFactor formFactor}) async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure error handling
  _configureErrorHandling();

  // Lock orientation for mobile (TV handles this differently)
  if (formFactor == FormFactor.mobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Create provider container with overrides
  final container = ProviderContainer(
    overrides: [
      formFactorProvider.overrideWithValue(formFactor),
    ],
  );

  // Run the app
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyIPTVApp(),
    ),
  );
}

void _configureErrorHandling() {
  // Pass Flutter errors to Crashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Pass async errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}
```

### 7.3 App Widget

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myiptv_player/core/design_system/theme/app_theme.dart';
import 'package:myiptv_player/core/design_system/theme/tv_theme.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';
import 'package:myiptv_player/navigation/app_router.dart';
import 'package:myiptv_player/shared/providers/platform_providers.dart';

class MyIPTVApp extends ConsumerWidget {
  const MyIPTVApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = ref.watch(formFactorProvider);
    final router = ref.watch(appRouterProvider);

    // Select theme based on form factor
    final theme = formFactor == FormFactor.tv
        ? TvTheme.dark()
        : AppTheme.dark();

    final lightTheme = formFactor == FormFactor.tv
        ? TvTheme.light()
        : AppTheme.light();

    return MaterialApp.router(
      title: 'MyIPTV Player',
      debugShowCheckedModeBanner: false,

      // Theming
      theme: lightTheme,
      darkTheme: theme,
      themeMode: ThemeMode.dark, // Default to dark for media apps

      // Routing
      routerConfig: router,

      // Localization would be configured here
      // localizationsDelegates: [...],
      // supportedLocales: [...],

      // Builder for global overlays and TV focus management
      builder: (context, child) {
        return _AppShell(
          formFactor: formFactor,
          child: child!,
        );
      },
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.formFactor,
    required this.child,
  });

  final FormFactor formFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Wrap with TV-specific focus handling if needed
    if (formFactor == FormFactor.tv) {
      return Shortcuts(
        shortcuts: _tvShortcuts,
        child: child,
      );
    }

    return child;
  }

  static final _tvShortcuts = <LogicalKeySet, Intent>{
    // Define TV remote button mappings here
    // LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
  };
}
```

### 7.4 Routing Configuration

```dart
// lib/navigation/routes.dart

abstract class Routes {
  // Onboarding
  static const onboarding = '/onboarding';
  static const addPlaylist = '/onboarding/add-playlist';

  // Main tabs
  static const home = '/';
  static const liveTV = '/live-tv';
  static const vod = '/vod';
  static const series = '/series';
  static const favorites = '/favorites';
  static const settings = '/settings';

  // Detail screens
  static const channelDetail = '/live-tv/channel/:id';
  static const movieDetail = '/vod/movie/:id';
  static const seriesDetail = '/series/:id';
  static const episodeDetail = '/series/:seriesId/episode/:episodeId';

  // Player
  static const player = '/player';

  // Settings sub-screens
  static const playbackSettings = '/settings/playback';
  static const parentalControl = '/settings/parental';
  static const playlists = '/settings/playlists';
  static const about = '/settings/about';

  // Monetization
  static const paywall = '/pro';
}
```

```dart
// lib/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myiptv_player/features/live_tv/presentation/screens/live_tv_screen.dart';
import 'package:myiptv_player/features/onboarding/presentation/screens/add_playlist_screen.dart';
import 'package:myiptv_player/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:myiptv_player/features/playback/presentation/screens/player_screen.dart';
import 'package:myiptv_player/features/series/presentation/screens/series_screen.dart';
import 'package:myiptv_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:myiptv_player/features/vod/presentation/screens/vod_screen.dart';
import 'package:myiptv_player/navigation/guards/onboarding_guard.dart';
import 'package:myiptv_player/navigation/routes.dart';
import 'package:myiptv_player/shared/widgets/shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingGuard = ref.watch(onboardingGuardProvider);

  return GoRouter(
    initialLocation: Routes.liveTV,
    debugLogDiagnostics: true,

    // Redirect logic for onboarding
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation.startsWith(Routes.onboarding);
      final needsOnboarding = !onboardingGuard.isComplete;

      if (needsOnboarding && !isOnboarding) {
        return Routes.onboarding;
      }

      if (!needsOnboarding && isOnboarding) {
        return Routes.liveTV;
      }

      return null;
    },

    routes: [
      // Onboarding flow
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'add-playlist',
            builder: (context, state) => const AddPlaylistScreen(),
          ),
        ],
      ),

      // Main app with bottom navigation shell
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: Routes.liveTV,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LiveTvScreen(),
            ),
          ),
          GoRoute(
            path: Routes.vod,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VodScreen(),
            ),
          ),
          GoRoute(
            path: Routes.series,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SeriesScreen(),
            ),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Full-screen player (outside shell)
      GoRoute(
        path: Routes.player,
        builder: (context, state) {
          // Content passed via extra
          final content = state.extra;
          return PlayerScreen(content: content);
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
```

### 7.5 Platform Providers

```dart
// lib/shared/providers/platform_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';

/// Form factor provider - overridden at app startup
final formFactorProvider = Provider<FormFactor>((ref) {
  // Default value, will be overridden in bootstrap
  return FormFactor.mobile;
});

/// Whether the app is running on a TV platform
final isTvProvider = Provider<bool>((ref) {
  return ref.watch(formFactorProvider) == FormFactor.tv;
});

/// Whether the app is running on mobile (phone/tablet)
final isMobileProvider = Provider<bool>((ref) {
  final formFactor = ref.watch(formFactorProvider);
  return formFactor == FormFactor.mobile || formFactor == FormFactor.tablet;
});
```

```dart
// lib/core/platform/form_factor.dart

enum FormFactor {
  mobile,
  tablet,
  tv,
  desktop,
  web,
}

extension FormFactorX on FormFactor {
  bool get isMobile => this == FormFactor.mobile || this == FormFactor.tablet;
  bool get isTV => this == FormFactor.tv;
  bool get isDesktop => this == FormFactor.desktop;
  bool get isWeb => this == FormFactor.web;

  /// Whether this platform uses remote/keyboard navigation (no touch)
  bool get usesFocusNavigation => this == FormFactor.tv;
}
```

### 7.6 Shell Screen with Navigation

```dart
// lib/shared/widgets/shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myiptv_player/navigation/routes.dart';
import 'package:myiptv_player/shared/providers/platform_providers.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTV = ref.watch(isTvProvider);

    if (isTV) {
      return _TvShellScreen(child: child);
    }

    return _MobileShellScreen(child: child);
  }
}

class _MobileShellScreen extends StatelessWidget {
  const _MobileShellScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Live TV',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'Series',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.liveTV)) return 0;
    if (location.startsWith(Routes.vod)) return 1;
    if (location.startsWith(Routes.series)) return 2;
    if (location.startsWith(Routes.settings)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.liveTV);
      case 1:
        context.go(Routes.vod);
      case 2:
        context.go(Routes.series);
      case 3:
        context.go(Routes.settings);
    }
  }
}

class _TvShellScreen extends StatelessWidget {
  const _TvShellScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TV uses a side rail or top navigation for Leanback-style UX
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail for TV
          NavigationRail(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv),
                label: Text('Live TV'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.movie_outlined),
                selectedIcon: Icon(Icons.movie),
                label: Text('Movies'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tv_outlined),
                selectedIcon: Icon(Icons.tv),
                label: Text('Series'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content area
          Expanded(child: child),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.liveTV)) return 0;
    if (location.startsWith(Routes.vod)) return 1;
    if (location.startsWith(Routes.series)) return 2;
    if (location.startsWith(Routes.settings)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.liveTV);
      case 1:
        context.go(Routes.vod);
      case 2:
        context.go(Routes.series);
      case 3:
        context.go(Routes.settings);
    }
  }
}
```

### 7.7 Placeholder Screens

```dart
// lib/features/onboarding/presentation/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myiptv_player/navigation/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo placeholder
              Icon(
                Icons.play_circle_outline,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              Text(
                'Welcome to MyIPTV Player',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Add your IPTV playlist to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // CTA button
              FilledButton.icon(
                onPressed: () => context.push(Routes.addPlaylist),
                icon: const Icon(Icons.add),
                label: const Text('Add Playlist'),
              ),
              const SizedBox(height: 16),

              // Skip for later
              TextButton(
                onPressed: () {
                  // TODO: Mark onboarding as skipped, go to main app
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

```dart
// lib/features/onboarding/presentation/screens/add_playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  final _urlController = TextEditingController();
  PlaylistType _selectedType = PlaylistType.m3uUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playlist type selector
            SegmentedButton<PlaylistType>(
              segments: const [
                ButtonSegment(
                  value: PlaylistType.m3uUrl,
                  label: Text('M3U URL'),
                  icon: Icon(Icons.link),
                ),
                ButtonSegment(
                  value: PlaylistType.m3uFile,
                  label: Text('M3U File'),
                  icon: Icon(Icons.file_upload),
                ),
                ButtonSegment(
                  value: PlaylistType.xtream,
                  label: Text('Xtream'),
                  icon: Icon(Icons.api),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() => _selectedType = selection.first);
              },
            ),
            const SizedBox(height: 24),

            // Input fields based on type
            if (_selectedType == PlaylistType.m3uUrl) ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Playlist URL',
                  hintText: 'https://example.com/playlist.m3u',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
            ] else if (_selectedType == PlaylistType.m3uFile) ...[
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Select M3U File'),
              ),
            ] else if (_selectedType == PlaylistType.xtream) ...[
              // TODO: Xtream API credentials form
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],

            const Spacer(),

            // Submit button
            FilledButton(
              onPressed: _onSubmit,
              child: const Text('Add Playlist'),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    // TODO: Validate and add playlist via controller
    // Then navigate to main app
  }
}

enum PlaylistType {
  m3uUrl,
  m3uFile,
  xtream,
}
```

```dart
// lib/features/live_tv/presentation/screens/live_tv_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live TV screen displaying channel categories and channel grid.
///
/// This screen will integrate with:
/// - [ChannelListController] for fetching and displaying channels
/// - [EpgController] for showing now/next program info
/// - [PlaybackController] for starting channel playback
///
/// TV-specific variant: [LiveTvScreenTv] uses different layout optimized
/// for remote navigation with horizontal scrolling rows.
class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch channel list provider
    // final channelsAsync = ref.watch(channelListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show category filter
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64),
            SizedBox(height: 16),
            Text('Live TV - Channel Grid'),
            SizedBox(height: 8),
            Text(
              'Channel list with categories will be displayed here.\n'
              'Tapping a channel will start playback.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/features/vod/presentation/screens/vod_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// VOD (Video on Demand) screen displaying movies.
///
/// This screen will integrate with:
/// - [VodController] for fetching and filtering movies
/// - [FavoritesController] for favorite functionality
/// - [PlaybackController] for movie playback
class VodScreen extends ConsumerWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 64),
            SizedBox(height: 16),
            Text('VOD - Movie Grid'),
            SizedBox(height: 8),
            Text(
              'Movie posters with categories will be displayed here.\n'
              'Supports horizontal scrolling rows and grid view.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/features/series/presentation/screens/series_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Series screen displaying TV shows with seasons and episodes.
///
/// This screen will integrate with:
/// - [SeriesController] for fetching series catalog
/// - [FavoritesController] for favorite functionality
/// - [PlaybackController] for episode playback
/// - [WatchHistoryController] for resume functionality
class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv, size: 64),
            SizedBox(height: 16),
            Text('Series - Show Grid'),
            SizedBox(height: 8),
            Text(
              'TV series with season/episode navigation.\n'
              'Supports continue watching and episode progress.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen with app configuration options.
///
/// Settings categories:
/// - Playlists management
/// - Playback preferences (quality, buffer, decoder)
/// - Parental controls
/// - Profile management
/// - About & Pro upgrade
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Playlists
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Playlists'),
            subtitle: const Text('Manage your IPTV sources'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to playlists management
            },
          ),
          const Divider(),

          // Playback
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Playback'),
            subtitle: const Text('Quality, buffer, decoder settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to playback settings
            },
          ),
          const Divider(),

          // Parental Controls
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Parental Controls'),
            subtitle: const Text('PIN and content restrictions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to parental controls
            },
          ),
          const Divider(),

          // Profile
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Account and sync settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to profile
            },
          ),
          const Divider(),

          // Pro upgrade
          ListTile(
            leading: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Upgrade to Pro'),
            subtitle: const Text('Unlock all features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to paywall
            },
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version, licenses, support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to about
            },
          ),
        ],
      ),
    );
  }
}
```

### 7.8 Player Screen Skeleton

```dart
// lib/features/playback/presentation/screens/player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen video player screen.
///
/// This screen will integrate with:
/// - [PlaybackController] for playback state and controls
/// - [media_kit] package for actual video rendering
/// - Audio track and subtitle selection
/// - EPG now/next for live channels
///
/// The player uses different control layouts for mobile vs TV:
/// - Mobile: Touch controls with tap-to-show overlay
/// - TV: Always-visible controls, D-pad navigation
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.content,
  });

  /// The content to play (Channel, Movie, or Episode)
  final dynamic content;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Enter fullscreen and landscape on mobile
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Watch playback state
    // final playbackState = ref.watch(playbackControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player surface
          // TODO: Replace with actual video player widget from media_kit
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  size: 80,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Video Player Surface',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  'media_kit video widget will be rendered here',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // Player controls overlay
          _PlayerControls(
            onBack: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatefulWidget {
  const _PlayerControls({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement auto-hide timer for controls

    if (!_controlsVisible) {
      return GestureDetector(
        onTap: () => setState(() => _controlsVisible = true),
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _controlsVisible = false),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.transparent,
              Colors.black54,
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Channel / Movie Title',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.subtitles, color: Colors.white),
                      onPressed: () {
                        // TODO: Show subtitle selector
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.audiotrack, color: Colors.white),
                      onPressed: () {
                        // TODO: Show audio track selector
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Center play/pause
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    // TODO: Seek back 10s
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 72,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  onPressed: () {
                    // TODO: Toggle play/pause
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    // TODO: Seek forward 10s
                  },
                ),
              ],
            ),

            const Spacer(),

            // Bottom bar with seek
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Seek bar
                    Row(
                      children: [
                        const Text(
                          '00:00',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Slider(
                            value: 0.0,
                            onChanged: (value) {
                              // TODO: Seek to position
                            },
                          ),
                        ),
                        const Text(
                          '00:00',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 7.9 Onboarding Guard

```dart
// lib/navigation/guards/onboarding_guard.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingGuardProvider = Provider<OnboardingGuard>((ref) {
  // TODO: Read from local storage whether onboarding is complete
  return OnboardingGuard(isComplete: false);
});

class OnboardingGuard {
  const OnboardingGuard({required this.isComplete});

  final bool isComplete;
}
```

### 7.10 Theme Configuration

```dart
// lib/core/design_system/theme/app_theme.dart

import 'package:flutter/material.dart';

abstract class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF6750A4),
      onPrimary: Colors.white,
      secondary: Color(0xFF625B71),
      onSecondary: Colors.white,
      surface: Color(0xFF1C1B1F),
      onSurface: Colors.white,
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        indicatorColor: colorScheme.primaryContainer,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF6750A4),
      onPrimary: Colors.white,
      secondary: Color(0xFF625B71),
      onSecondary: Colors.white,
      surface: Color(0xFFFFFBFE),
      onSurface: Color(0xFF1C1B1F),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
  }
}
```

```dart
// lib/core/design_system/theme/tv_theme.dart

import 'package:flutter/material.dart';
import 'package:myiptv_player/core/design_system/theme/app_theme.dart';

/// TV-specific theme with larger touch targets and focus indicators.
abstract class TvTheme {
  static ThemeData dark() {
    final base = AppTheme.dark();

    return base.copyWith(
      // Larger text for TV viewing distance
      textTheme: base.textTheme.apply(
        fontSizeFactor: 1.2,
      ),

      // Larger icons
      iconTheme: base.iconTheme.copyWith(
        size: 28,
      ),

      // Focus indicators for D-pad navigation
      focusColor: base.colorScheme.primary.withOpacity(0.3),

      // Larger cards for easier navigation
      cardTheme: base.cardTheme.copyWith(
        margin: const EdgeInsets.all(8),
      ),

      // Navigation rail adjustments
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        selectedIconTheme: IconThemeData(
          color: base.colorScheme.primary,
          size: 32,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Colors.white70,
          size: 28,
        ),
        selectedLabelTextStyle: TextStyle(
          color: base.colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = AppTheme.light();

    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: 1.2),
    );
  }
}
```

---

## 8. Platform-Specific Considerations

### 8.1 Android TV / Fire TV

1. **Focus Management**: Use `FocusableActionDetector` or custom focus widgets for D-pad navigation.
2. **Leanback Guidelines**: Follow material design for TV with larger touch targets (48dp minimum).
3. **Banner/Icon**: Provide TV-specific launcher assets.
4. **Remote Keys**: Handle `Select`, `Back`, `Play/Pause`, and directional keys.

```dart
// Example: TV-optimized focusable card
class FocusableCard extends StatelessWidget {
  const FocusableCard({
    super.key,
    required this.child,
    required this.onSelect,
  });

  final Widget child;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: hasFocus
                ? (Matrix4.identity()..scale(1.05))
                : Matrix4.identity(),
            decoration: BoxDecoration(
              border: hasFocus
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
```

### 8.2 iOS Specific

1. **App Transport Security**: Ensure HTTPS for all network requests.
2. **Background Audio**: Configure `Info.plist` for background playback.
3. **Picture-in-Picture**: Implement PiP for supported devices.
4. **StoreKit**: Use official IAP implementation for App Store compliance.

### 8.3 Samsung Tizen (Future)

Flutter support for Tizen is experimental via the `flutter-tizen` project. Key considerations:

1. **Separate build target**: Will require `main_tizen.dart` entry point.
2. **Remote navigation**: Similar to Android TV D-pad handling.
3. **Package limitations**: Some packages may not work; plan for abstractions.

### 8.4 Responsive Layouts

```dart
// lib/shared/widgets/responsive_builder.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myiptv_player/core/platform/form_factor.dart';
import 'package:myiptv_player/shared/providers/platform_providers.dart';

class ResponsiveBuilder extends ConsumerWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.tv,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? tv;
  final Widget? desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = ref.watch(formFactorProvider);

    return switch (formFactor) {
      FormFactor.tv => tv ?? desktop ?? mobile,
      FormFactor.desktop => desktop ?? mobile,
      FormFactor.tablet => tablet ?? mobile,
      _ => mobile,
    };
  }
}
```

---

## Appendix A: pubspec.yaml Dependencies

```yaml
name: myiptv_player
description: Cross-platform IPTV player application
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Code Generation
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

  # Navigation
  go_router: ^12.0.0

  # Networking
  dio: ^5.4.0
  connectivity_plus: ^5.0.0

  # Local Storage
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.0
  firebase_crashlytics: ^3.4.0
  firebase_analytics: ^10.7.0
  firebase_remote_config: ^4.3.0

  # Video Player
  media_kit: ^1.1.0
  media_kit_video: ^1.1.0
  media_kit_libs_video: ^1.0.0

  # UI Utilities
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # XML Parsing (EPG)
  xml: ^6.4.0

  # In-App Purchases
  in_app_purchase: ^3.1.0

  # Platform
  wakelock_plus: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  isar_generator: ^3.1.0

  # Linting
  very_good_analysis: ^5.1.0

  # Testing
  mocktail: ^1.0.0
  golden_toolkit: ^0.15.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
```

---

## Appendix B: Analysis Options

```yaml
# analysis_options.yaml

include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    public_member_api_docs: false
    lines_longer_than_80_chars: false
    flutter_style_todos: false
```

---

## Summary

This architecture provides:

1. **Clean separation of concerns** with domain, data, and presentation layers per feature.
2. **Scalable state management** with Riverpod for reactive, testable state.
3. **Multi-platform support** with form factor detection and responsive layouts.
4. **TV-first consideration** with focus navigation and Leanback-style UX.
5. **Extensible infrastructure** for IPTV parsing, video playback, and backend sync.
6. **Production-ready foundation** with error handling, analytics, and monetization hooks.

The skeleton code is ready for immediate development. Start by implementing the playlist parsing in `infrastructure/iptv/` and the channel list in `features/live_tv/` to see end-to-end functionality.
