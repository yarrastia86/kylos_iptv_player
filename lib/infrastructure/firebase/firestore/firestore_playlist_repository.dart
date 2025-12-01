// Kylos IPTV Player - Firestore Playlist Repository
// Implementation of PlaylistRepository using Cloud Firestore.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firestore/playlist_dto.dart';

/// Firestore implementation of PlaylistRepository.
///
/// Syncs playlist sources to Cloud Firestore for cloud backup and
/// multi-device synchronization.
class FirestorePlaylistRepository implements PlaylistRepository {
  FirestorePlaylistRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  /// Collection path: /users/{userId}/playlists
  CollectionReference<Map<String, dynamic>> get _playlistsCollection =>
      _firestore.collection('users').doc(_userId).collection('playlists');

  /// User document path: /users/{userId}
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  @override
  Future<List<PlaylistSource>> getPlaylists() async {
    try {
      final snapshot = await _playlistsCollection
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _documentToPlaylist(doc))
          .whereType<PlaylistSource>()
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting playlists: ${e.message}');
      }
      // Return empty list on error - graceful degradation
      return [];
    }
  }

  @override
  Future<PlaylistSource?> getPlaylist(String id) async {
    try {
      final doc = await _playlistsCollection.doc(id).get();
      if (!doc.exists) return null;
      return _documentToPlaylist(doc);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting playlist: ${e.message}');
      }
      return null;
    }
  }

  @override
  Future<void> addPlaylist(PlaylistSource playlist) async {
    try {
      final dto = PlaylistDto.fromDomain(playlist);
      await _playlistsCollection.doc(playlist.id).set(dto.toJson());
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error adding playlist: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePlaylist(PlaylistSource playlist) async {
    try {
      final dto = PlaylistDto.fromDomain(playlist);
      await _playlistsCollection.doc(playlist.id).update(dto.toJson());
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error updating playlist: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    try {
      await _playlistsCollection.doc(id).delete();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error deleting playlist: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> setActivePlaylist(String id) async {
    try {
      // Update the active playlist in the user document
      await _userDoc.update({
        'preferences.activePlaylistId': id,
        'lastSyncAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error setting active playlist: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<String?> getActivePlaylistId() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) return null;
      final data = doc.data();
      final preferences = data?['preferences'] as Map<String, dynamic>?;
      return preferences?['activePlaylistId'] as String?;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting active playlist: ${e.message}');
      }
      return null;
    }
  }

  /// Watches playlists for real-time updates.
  Stream<List<PlaylistSource>> watchPlaylists() {
    return _playlistsCollection
        .orderBy('sortOrder')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToPlaylist(doc))
            .whereType<PlaylistSource>()
            .toList())
        .handleError((e) {
      if (kDebugMode) {
        print('Firestore stream error: $e');
      }
      return <PlaylistSource>[];
    });
  }

  /// Converts a Firestore document to a PlaylistSource.
  PlaylistSource? _documentToPlaylist(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null) return null;
      final dto = PlaylistDto.fromJson(data);
      return dto.toDomain();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing playlist document ${doc.id}: $e');
      }
      return null;
    }
  }
}

/// Syncing playlist repository that combines local and cloud storage.
///
/// Provides offline-first behavior with background sync to Firestore.
class SyncingPlaylistRepository implements PlaylistRepository {
  SyncingPlaylistRepository({
    required PlaylistRepository localRepository,
    required FirestorePlaylistRepository? cloudRepository,
  })  : _local = localRepository,
        _cloud = cloudRepository;

  final PlaylistRepository _local;
  final FirestorePlaylistRepository? _cloud;

  bool get _hasCloudSync => _cloud != null;

  @override
  Future<List<PlaylistSource>> getPlaylists() async {
    // Always return local data first for fast response
    final localPlaylists = await _local.getPlaylists();

    // Sync from cloud in background if available
    if (_hasCloudSync) {
      _syncFromCloud();
    }

    return localPlaylists;
  }

  @override
  Future<PlaylistSource?> getPlaylist(String id) async {
    return _local.getPlaylist(id);
  }

  @override
  Future<void> addPlaylist(PlaylistSource playlist) async {
    // Write to local first
    await _local.addPlaylist(playlist);

    // Sync to cloud in background
    if (_hasCloudSync) {
      _cloud!.addPlaylist(playlist).catchError((e) {
        if (kDebugMode) {
          print('Background cloud sync failed: $e');
        }
      });
    }
  }

  @override
  Future<void> updatePlaylist(PlaylistSource playlist) async {
    await _local.updatePlaylist(playlist);

    if (_hasCloudSync) {
      _cloud!.updatePlaylist(playlist).catchError((e) {
        if (kDebugMode) {
          print('Background cloud sync failed: $e');
        }
      });
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _local.deletePlaylist(id);

    if (_hasCloudSync) {
      _cloud!.deletePlaylist(id).catchError((e) {
        if (kDebugMode) {
          print('Background cloud sync failed: $e');
        }
      });
    }
  }

  @override
  Future<void> setActivePlaylist(String id) async {
    await _local.setActivePlaylist(id);

    if (_hasCloudSync) {
      _cloud!.setActivePlaylist(id).catchError((e) {
        if (kDebugMode) {
          print('Background cloud sync failed: $e');
        }
      });
    }
  }

  @override
  Future<String?> getActivePlaylistId() async {
    return _local.getActivePlaylistId();
  }

  /// Syncs playlists from cloud to local storage.
  Future<void> _syncFromCloud() async {
    if (!_hasCloudSync) return;

    try {
      final cloudPlaylists = await _cloud!.getPlaylists();
      final localPlaylists = await _local.getPlaylists();

      // Simple merge: cloud wins for conflicts based on updatedAt
      for (final cloudPlaylist in cloudPlaylists) {
        final localPlaylist = localPlaylists.firstWhere(
          (p) => p.id == cloudPlaylist.id,
          orElse: () => cloudPlaylist,
        );

        final cloudUpdatedAt = cloudPlaylist.updatedAt ?? cloudPlaylist.createdAt;
        final localUpdatedAt = localPlaylist.updatedAt ?? localPlaylist.createdAt;

        if (cloudUpdatedAt != null &&
            localUpdatedAt != null &&
            cloudUpdatedAt.isAfter(localUpdatedAt)) {
          await _local.updatePlaylist(cloudPlaylist);
        } else if (localPlaylist.id == cloudPlaylist.id &&
            cloudUpdatedAt == null) {
          await _local.addPlaylist(cloudPlaylist);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cloud sync failed: $e');
      }
    }
  }

  /// Forces a full sync with cloud.
  Future<void> forceSync() async {
    if (!_hasCloudSync) return;

    try {
      // Push all local playlists to cloud
      final localPlaylists = await _local.getPlaylists();
      for (final playlist in localPlaylists) {
        await _cloud!.addPlaylist(playlist);
      }

      // Pull all cloud playlists to local
      await _syncFromCloud();
    } catch (e) {
      if (kDebugMode) {
        print('Force sync failed: $e');
      }
      rethrow;
    }
  }

  /// Stream of playlists with real-time cloud updates.
  Stream<List<PlaylistSource>> watchPlaylists() {
    if (!_hasCloudSync) {
      // Return a stream that emits local playlists once
      return Stream.fromFuture(_local.getPlaylists());
    }

    return _cloud!.watchPlaylists();
  }
}
