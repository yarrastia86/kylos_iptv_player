// Kylos IPTV Player - Firebase Providers
// Riverpod providers for Firebase services.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kylos_iptv_player/core/auth/auth_service.dart';
import 'package:kylos_iptv_player/core/config/remote_config_service.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/core/user/user_repository.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/auth/firebase_auth_service.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/firestore_entitlement_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/firestore_playlist_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/firestore_user_repository.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/remote_config/firebase_remote_config_service.dart';
import 'package:kylos_iptv_player/infrastructure/providers/infrastructure_providers.dart';
import 'package:kylos_iptv_player/infrastructure/repositories/local_playlist_repository.dart';

// =============================================================================
// Firebase Core Providers
// =============================================================================

/// Provider for FirebaseAuth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for FirebaseFirestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for FirebaseRemoteConfig instance.
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

/// Provider for GoogleSignIn instance.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// =============================================================================
// Auth Providers
// =============================================================================

/// Provider for AuthService.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

/// Stream provider for current authenticated user.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user (synchronous access).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Provider for whether user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Provider for whether user is anonymous.
final isAnonymousProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAnonymous ?? true;
});

// =============================================================================
// User Repository Providers
// =============================================================================

/// Provider for UserRepository.
final userRepositoryProvider = Provider<UserRepository?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreUserRepository(firestore: firestore);
});

/// Provider for current user document.
final userDocumentProvider = StreamProvider<UserDocument?>((ref) {
  final user = ref.watch(currentUserProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  if (user == null || userRepo == null) {
    return Stream.value(null);
  }

  return userRepo.watchUser(user.uid);
});

// =============================================================================
// Playlist Repository Providers
// =============================================================================

/// Provider for cloud playlist repository (Firestore).
final cloudPlaylistRepositoryProvider =
    Provider<FirestorePlaylistRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);

  if (user == null) {
    return null;
  }

  return FirestorePlaylistRepository(
    firestore: firestore,
    userId: user.uid,
  );
});

/// Provider for local playlist repository.
final localPlaylistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return LocalPlaylistRepository(localStorage: localStorage);
});

/// Provider for syncing playlist repository.
///
/// Combines local and cloud storage for offline-first behavior
/// with background synchronization.
final syncingPlaylistRepositoryProvider = Provider<SyncingPlaylistRepository>((ref) {
  final local = ref.watch(localPlaylistRepositoryProvider);
  final cloud = ref.watch(cloudPlaylistRepositoryProvider);

  return SyncingPlaylistRepository(
    localRepository: local,
    cloudRepository: cloud,
  );
});

/// Override the default playlist repository with the syncing one.
///
/// This makes the syncing repository available throughout the app
/// via the standard playlistRepositoryProvider.
final playlistRepositoryOverrideProvider = Provider<PlaylistRepository>((ref) {
  return ref.watch(syncingPlaylistRepositoryProvider);
});

/// Stream provider for playlists with real-time updates.
final playlistsStreamProvider = StreamProvider<List<PlaylistSource>>((ref) {
  final syncingRepo = ref.watch(syncingPlaylistRepositoryProvider);
  return syncingRepo.watchPlaylists();
});

// =============================================================================
// Entitlement Providers
// =============================================================================

/// Provider for EntitlementRepository.
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreEntitlementRepository(firestore: firestore);
});

/// Stream provider for current user's entitlement.
final entitlementProvider = StreamProvider<Entitlement?>((ref) {
  final user = ref.watch(currentUserProvider);
  final entitlementRepo = ref.watch(entitlementRepositoryProvider);

  if (user == null) {
    return Stream.value(null);
  }

  return entitlementRepo.watchEntitlement(user.uid);
});

/// Provider for whether user has pro features.
final hasProProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).valueOrNull?.hasPro ?? false;
});

/// Provider for feature limits based on subscription tier.
final featureLimitsProvider = FutureProvider<FeatureLimits>((ref) async {
  final user = ref.watch(currentUserProvider);
  final entitlementRepo = ref.watch(entitlementRepositoryProvider);

  if (user == null) {
    return FeatureLimits.free;
  }

  return entitlementRepo.getFeatureLimits(user.uid);
});

// =============================================================================
// Remote Config Providers
// =============================================================================

/// Provider for RemoteConfigService.
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  final firebaseService = FirebaseRemoteConfigService(remoteConfig: remoteConfig);

  // Wrap with offline-capable service for graceful degradation
  return OfflineRemoteConfigService(delegate: firebaseService);
});

/// Provider for current app config.
final appConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(remoteConfigServiceProvider).config;
});

/// Provider for feature flags.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return ref.watch(appConfigProvider).features;
});

/// Stream provider for config changes.
final configChangesProvider = StreamProvider<AppConfig>((ref) {
  return ref.watch(remoteConfigServiceProvider).configChanges;
});

// =============================================================================
// Convenience Providers
// =============================================================================

/// Provider for checking if a specific feature is enabled.
Provider<bool> featureEnabledProvider(String featureKey) {
  return Provider<bool>((ref) {
    return ref.watch(remoteConfigServiceProvider).getFeatureFlag(featureKey);
  });
}

/// Provider for maintenance mode status.
final maintenanceModeProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).maintenanceMode;
});

/// Provider for force update status.
final forceUpdateProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).forceUpdate;
});
