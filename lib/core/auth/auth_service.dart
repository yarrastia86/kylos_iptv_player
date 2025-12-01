// Kylos IPTV Player - Auth Service Interface
// Domain layer interface for authentication operations.

/// Represents an authenticated user.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.providers,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Unique user identifier.
  final String uid;

  /// User email address (null for anonymous users).
  final String? email;

  /// Display name.
  final String? displayName;

  /// Profile photo URL.
  final String? photoUrl;

  /// Whether this is an anonymous account.
  final bool isAnonymous;

  /// List of linked authentication providers.
  final List<String> providers;

  /// When the account was created.
  final DateTime? createdAt;

  /// When the user last signed in.
  final DateTime? lastLoginAt;

  /// Whether the user has a verified email.
  bool get hasVerifiedEmail => email != null && !isAnonymous;

  /// Whether the user can upgrade from anonymous.
  bool get canUpgrade => isAnonymous;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    List<String>? providers,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      providers: providers ?? this.providers,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AppUser($uid, $email, anonymous: $isAnonymous)';
}

/// Result of an authentication operation.
sealed class AuthResult {
  const AuthResult();
}

/// Authentication succeeded.
class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AppUser user;
}

/// Authentication failed.
class AuthFailure extends AuthResult {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  /// Common error codes.
  static const String invalidEmail = 'invalid-email';
  static const String userDisabled = 'user-disabled';
  static const String userNotFound = 'user-not-found';
  static const String wrongPassword = 'wrong-password';
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String weakPassword = 'weak-password';
  static const String operationNotAllowed = 'operation-not-allowed';
  static const String tooManyRequests = 'too-many-requests';
  static const String networkError = 'network-error';
  static const String cancelled = 'cancelled';
  static const String credentialAlreadyInUse = 'credential-already-in-use';
  static const String unknown = 'unknown';
}

/// Authentication service interface.
///
/// Defines the contract for authentication operations.
/// Implementations should not leak Firebase-specific types.
abstract class AuthService {
  /// Stream of authentication state changes.
  ///
  /// Emits null when signed out, AppUser when signed in.
  Stream<AppUser?> get authStateChanges;

  /// Currently signed-in user, or null if signed out.
  AppUser? get currentUser;

  /// Signs in anonymously.
  ///
  /// Creates a new anonymous account if none exists.
  Future<AuthResult> signInAnonymously();

  /// Signs in with email and password.
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with Google.
  Future<AuthResult> signInWithGoogle();

  /// Upgrades an anonymous account to email/password.
  ///
  /// Links the credential to the existing anonymous account,
  /// preserving all user data.
  Future<AuthResult> upgradeAnonymousWithEmailPassword({
    required String email,
    required String password,
  });

  /// Upgrades an anonymous account to Google.
  Future<AuthResult> upgradeAnonymousWithGoogle();

  /// Sends a password reset email.
  Future<AuthResult> sendPasswordResetEmail(String email);

  /// Signs out the current user.
  Future<void> signOut();

  /// Deletes the current user account.
  ///
  /// This is a destructive operation and requires recent authentication.
  Future<AuthResult> deleteAccount();

  /// Re-authenticates the user with their password.
  ///
  /// Required before sensitive operations like account deletion.
  Future<AuthResult> reauthenticateWithPassword(String password);

  /// Updates the user's display name.
  Future<AuthResult> updateDisplayName(String displayName);

  /// Updates the user's email address.
  ///
  /// Requires recent authentication.
  Future<AuthResult> updateEmail(String newEmail);

  /// Updates the user's password.
  ///
  /// Requires recent authentication.
  Future<AuthResult> updatePassword(String newPassword);
}
