// Kylos IPTV Player - Infrastructure Providers
// Riverpod providers for infrastructure services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/infrastructure/network/api_client.dart';
import 'package:kylos_iptv_player/infrastructure/repositories/local_playlist_repository.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance.
///
/// Must be overridden with actual instance during app initialization.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with an actual instance',
  );
});

/// Provider for LocalStorage.
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(preferences: prefs);
});

/// Provider for ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for PlaylistRepository.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return LocalPlaylistRepository(localStorage: localStorage);
});
