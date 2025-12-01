// Kylos IPTV Player - Firebase Auth Service
// Implementation of AuthService using Firebase Authentication.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kylos_iptv_player/core/auth/auth_service.dart';

/// Firebase implementation of AuthService.
///
/// Wraps Firebase Auth to provide a clean interface that doesn't leak
/// Firebase-specific types to the domain layer.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuth firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser {
    return _mapFirebaseUser(_firebaseAuth.currentUser);
  }

  @override
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to create anonymous user',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to sign in',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to create user',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthFailure(
          AuthFailure.cancelled,
          'Google sign-in was cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to sign in with Google',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> upgradeAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null || !currentFirebaseUser.isAnonymous) {
        return const AuthFailure(
          AuthFailure.operationNotAllowed,
          'No anonymous user to upgrade',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final userCredential =
          await currentFirebaseUser.linkWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to upgrade anonymous account',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> upgradeAnonymousWithGoogle() async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null || !currentFirebaseUser.isAnonymous) {
        return const AuthFailure(
          AuthFailure.operationNotAllowed,
          'No anonymous user to upgrade',
        );
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthFailure(
          AuthFailure.cancelled,
          'Google sign-in was cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await currentFirebaseUser.linkWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user);
      if (user == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to upgrade anonymous account with Google',
        );
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      // Return success with a placeholder user since we don't have one
      return AuthSuccess(
        AppUser(
          uid: '',
          isAnonymous: false,
          providers: [],
          email: email,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const AuthFailure(
          AuthFailure.userNotFound,
          'No user signed in',
        );
      }

      await user.delete();
      return AuthSuccess(
        AppUser(
          uid: user.uid,
          isAnonymous: user.isAnonymous,
          providers: [],
        ),
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> reauthenticateWithPassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        return const AuthFailure(
          AuthFailure.userNotFound,
          'No user signed in or no email associated',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      final appUser = _mapFirebaseUser(user);
      if (appUser == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to reauthenticate',
        );
      }
      return AuthSuccess(appUser);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> updateDisplayName(String displayName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const AuthFailure(
          AuthFailure.userNotFound,
          'No user signed in',
        );
      }

      await user.updateDisplayName(displayName);
      await user.reload();
      final appUser = _mapFirebaseUser(_firebaseAuth.currentUser);
      if (appUser == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to update display name',
        );
      }
      return AuthSuccess(appUser);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const AuthFailure(
          AuthFailure.userNotFound,
          'No user signed in',
        );
      }

      await user.verifyBeforeUpdateEmail(newEmail);
      final appUser = _mapFirebaseUser(user);
      if (appUser == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to update email',
        );
      }
      return AuthSuccess(appUser);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const AuthFailure(
          AuthFailure.userNotFound,
          'No user signed in',
        );
      }

      await user.updatePassword(newPassword);
      final appUser = _mapFirebaseUser(user);
      if (appUser == null) {
        return const AuthFailure(
          AuthFailure.unknown,
          'Failed to update password',
        );
      }
      return AuthSuccess(appUser);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return AuthFailure(AuthFailure.unknown, e.toString());
    }
  }

  /// Maps a Firebase User to an AppUser.
  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      providers: user.providerData.map((p) => p.providerId).toList(),
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  /// Maps Firebase Auth errors to AuthFailure.
  AuthFailure _handleFirebaseError(FirebaseAuthException e) {
    if (kDebugMode) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
    }

    final code = switch (e.code) {
      'invalid-email' => AuthFailure.invalidEmail,
      'user-disabled' => AuthFailure.userDisabled,
      'user-not-found' => AuthFailure.userNotFound,
      'wrong-password' => AuthFailure.wrongPassword,
      'email-already-in-use' => AuthFailure.emailAlreadyInUse,
      'weak-password' => AuthFailure.weakPassword,
      'operation-not-allowed' => AuthFailure.operationNotAllowed,
      'too-many-requests' => AuthFailure.tooManyRequests,
      'network-request-failed' => AuthFailure.networkError,
      'credential-already-in-use' => AuthFailure.credentialAlreadyInUse,
      _ => AuthFailure.unknown,
    };

    final message = switch (e.code) {
      'invalid-email' => 'The email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'The password is too weak.',
      'operation-not-allowed' => 'This operation is not allowed.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      'credential-already-in-use' =>
        'This credential is already linked to another account.',
      _ => e.message ?? 'An unknown error occurred.',
    };

    return AuthFailure(code, message);
  }
}
