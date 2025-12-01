// Kylos IPTV Player - Playlist Providers
// Riverpod providers for playlist state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_api_client.dart';

/// State for the playlists controller.
class PlaylistsState {
  const PlaylistsState({
    this.playlists = const [],
    this.isLoading = false,
    this.error,
  });

  /// All configured playlists.
  final List<PlaylistSource> playlists;

  /// Whether playlists are being loaded.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether there are any playlists.
  bool get hasPlaylists => playlists.isNotEmpty;

  /// Creates a loading state.
  factory PlaylistsState.loading() {
    return const PlaylistsState(isLoading: true);
  }

  /// Creates an error state.
  factory PlaylistsState.withError(String error) {
    return PlaylistsState(error: error);
  }

  /// Creates a copy with the given fields replaced.
  PlaylistsState copyWith({
    List<PlaylistSource>? playlists,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing playlists.
///
/// Handles loading, adding, editing, and removing playlist sources.
class PlaylistsNotifier extends StateNotifier<PlaylistsState> {
  PlaylistsNotifier({
    required this.repository,
  }) : super(const PlaylistsState());

  final PlaylistRepository repository;

  /// Loads all playlists from storage.
  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final playlists = await repository.getPlaylists();
      state = state.copyWith(playlists: playlists, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load playlists: $e',
      );
    }
  }

  /// Adds a new playlist.
  Future<bool> addPlaylist(PlaylistSource playlist) async {
    // Validate the playlist
    final validation = playlist.validate();
    if (validation is PlaylistSourceInvalid) {
      state = state.copyWith(error: validation.errors.join(', '));
      return false;
    }

    try {
      await repository.addPlaylist(playlist);
      final updatedPlaylists = [...state.playlists, playlist];
      state = state.copyWith(playlists: updatedPlaylists, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add playlist: $e');
      return false;
    }
  }

  /// Updates an existing playlist.
  Future<bool> updatePlaylist(PlaylistSource playlist) async {
    final validation = playlist.validate();
    if (validation is PlaylistSourceInvalid) {
      state = state.copyWith(error: validation.errors.join(', '));
      return false;
    }

    try {
      await repository.updatePlaylist(playlist);
      final updatedPlaylists = state.playlists.map((p) {
        return p.id == playlist.id ? playlist : p;
      }).toList();
      state = state.copyWith(playlists: updatedPlaylists, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update playlist: $e');
      return false;
    }
  }

  /// Removes a playlist.
  Future<bool> removePlaylist(String id) async {
    try {
      await repository.deletePlaylist(id);
      final updatedPlaylists =
          state.playlists.where((p) => p.id != id).toList();
      state = state.copyWith(playlists: updatedPlaylists, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove playlist: $e');
      return false;
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the playlists notifier.
final playlistsNotifierProvider =
    StateNotifierProvider<PlaylistsNotifier, PlaylistsState>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistsNotifier(repository: repository);
});

/// State for the active playlist.
class ActivePlaylistState {
  const ActivePlaylistState({
    this.playlist,
    this.isLoading = false,
  });

  /// The currently active playlist.
  final PlaylistSource? playlist;

  /// Whether the playlist is being activated.
  final bool isLoading;

  /// Whether an active playlist is set.
  bool get hasActivePlaylist => playlist != null;

  /// Creates a copy with the given fields replaced.
  ActivePlaylistState copyWith({
    PlaylistSource? playlist,
    bool? isLoading,
  }) {
    return ActivePlaylistState(
      playlist: playlist ?? this.playlist,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for the active playlist selection.
///
/// Manages which playlist is currently selected for browsing and playback.
class ActivePlaylistNotifier extends StateNotifier<ActivePlaylistState> {
  ActivePlaylistNotifier({
    required this.repository,
    required this.ref,
  }) : super(const ActivePlaylistState());

  final PlaylistRepository repository;
  final Ref ref;

  /// Loads the active playlist from storage.
  Future<void> loadActivePlaylist() async {
    state = state.copyWith(isLoading: true);

    try {
      final activeId = await repository.getActivePlaylistId();
      if (activeId != null) {
        final playlist = await repository.getPlaylist(activeId);
        state = ActivePlaylistState(playlist: playlist);
      } else {
        state = const ActivePlaylistState();
      }
    } catch (e) {
      state = const ActivePlaylistState();
    }
  }

  /// Sets the active playlist.
  Future<void> setActivePlaylist(PlaylistSource playlist) async {
    state = state.copyWith(isLoading: true);

    try {
      await repository.setActivePlaylist(playlist.id);
      state = ActivePlaylistState(playlist: playlist);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Clears the active playlist.
  void clearActivePlaylist() {
    state = const ActivePlaylistState();
  }
}

/// Provider for the active playlist notifier.
final activePlaylistNotifierProvider =
    StateNotifierProvider<ActivePlaylistNotifier, ActivePlaylistState>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return ActivePlaylistNotifier(repository: repository, ref: ref);
});

/// Convenience provider to get just the active playlist.
final activePlaylistProvider = Provider<PlaylistSource?>((ref) {
  return ref.watch(activePlaylistNotifierProvider).playlist;
});

/// Provider to check if any playlist exists.
final hasPlaylistsProvider = Provider<bool>((ref) {
  return ref.watch(playlistsNotifierProvider).hasPlaylists;
});

/// Placeholder for the repository provider - should be overridden.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  throw UnimplementedError(
    'playlistRepositoryProvider must be overridden with an implementation',
  );
});

/// State for Xtream authentication info.
class XtreamAuthState {
  const XtreamAuthState({
    this.authInfo,
    this.isLoading = false,
    this.error,
  });

  final XtreamAuthInfo? authInfo;
  final bool isLoading;
  final String? error;

  XtreamAuthState copyWith({
    XtreamAuthInfo? authInfo,
    bool? isLoading,
    String? error,
  }) {
    return XtreamAuthState(
      authInfo: authInfo ?? this.authInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for Xtream authentication info.
class XtreamAuthNotifier extends StateNotifier<XtreamAuthState> {
  XtreamAuthNotifier({required this.ref}) : super(const XtreamAuthState());

  final Ref ref;
  XtreamApiClient? _client;

  Future<void> loadAuthInfo() async {
    final activePlaylist = ref.read(activePlaylistProvider);
    if (activePlaylist == null ||
        activePlaylist.type != PlaylistType.xtream ||
        activePlaylist.xtreamCredentials == null) {
      state = const XtreamAuthState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      _client?.dispose();
      _client = XtreamApiClient(credentials: activePlaylist.xtreamCredentials!);
      final authInfo = await _client!.authenticate();
      state = XtreamAuthState(authInfo: authInfo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch auth info: $e',
      );
    }
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}

/// Provider for Xtream auth info.
final xtreamAuthNotifierProvider =
    StateNotifierProvider<XtreamAuthNotifier, XtreamAuthState>((ref) {
  return XtreamAuthNotifier(ref: ref);
});

/// Convenience provider for expiration date.
final xtreamExpirationDateProvider = Provider<DateTime?>((ref) {
  return ref.watch(xtreamAuthNotifierProvider).authInfo?.expDate;
});
