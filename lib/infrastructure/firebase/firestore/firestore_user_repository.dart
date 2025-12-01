// Kylos IPTV Player - Firestore User Repository
// Implementation of UserRepository using Cloud Firestore.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/user/user_repository.dart';

/// Firestore implementation of UserRepository.
///
/// Manages user documents in Cloud Firestore.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Collection path: /users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserDocument?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return _documentToUser(doc);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error getting user: ${e.message}');
      }
      return null;
    }
  }

  @override
  Future<void> createUser(UserDocument user) async {
    try {
      await _usersCollection.doc(user.uid).set(_userToDocument(user));
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error creating user: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateUser(UserDocument user) async {
    try {
      await _usersCollection.doc(user.uid).update(_userToDocument(user));
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error updating user: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        'preferences': preferences.toJson(),
        'lastSyncAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error updating preferences: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error updating last login: ${e.message}');
      }
      // Non-critical operation, don't rethrow
    }
  }

  @override
  Stream<UserDocument?> watchUser(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return _documentToUser(doc);
        })
        .handleError((e) {
          if (kDebugMode) {
            print('Firestore stream error: $e');
          }
          return null;
        });
  }

  @override
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error checking user exists: ${e.message}');
      }
      return false;
    }
  }

  /// Converts a Firestore document to a UserDocument.
  UserDocument? _documentToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;

      return UserDocument(
        uid: data['uid'] as String? ?? doc.id,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        photoUrl: data['photoURL'] as String?,
        createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
        lastLoginAt: _parseTimestamp(data['lastLoginAt']),
        lastSyncAt: _parseTimestamp(data['lastSyncAt']),
        providers: (data['providers'] as List<dynamic>?)
                ?.map((p) => p.toString())
                .toList() ??
            [],
        status: _parseUserStatus(data['status'] as String?),
        preferences: data['preferences'] != null
            ? UserPreferences.fromJson(
                data['preferences'] as Map<String, dynamic>)
            : const UserPreferences(),
        subscription: data['subscription'] != null
            ? UserSubscription.fromJson(
                data['subscription'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing user document ${doc.id}: $e');
      }
      return null;
    }
  }

  /// Converts a UserDocument to Firestore document data.
  Map<String, dynamic> _userToDocument(UserDocument user) {
    return {
      'uid': user.uid,
      if (user.email != null) 'email': user.email,
      if (user.displayName != null) 'displayName': user.displayName,
      if (user.photoUrl != null) 'photoURL': user.photoUrl,
      'createdAt': Timestamp.fromDate(user.createdAt),
      if (user.lastLoginAt != null)
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt!),
      'lastSyncAt': FieldValue.serverTimestamp(),
      'providers': user.providers,
      'status': user.status.name,
      'preferences': user.preferences.toJson(),
      if (user.subscription != null) 'subscription': user.subscription!.toJson(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static UserStatus _parseUserStatus(String? value) {
    if (value == null) return UserStatus.active;
    return UserStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => UserStatus.active,
    );
  }
}
