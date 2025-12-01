// Kylos IPTV Player - User Repository Interface
// Domain layer interface for user profile and preferences operations.

/// User preferences that sync across devices.
class UserPreferences {
  const UserPreferences({
    this.language = 'en',
    this.theme = ThemePreference.system,
    this.defaultProfileId,
    this.analyticsEnabled = true,
  });

  final String language;
  final ThemePreference theme;
  final String? defaultProfileId;
  final bool analyticsEnabled;

  UserPreferences copyWith({
    String? language,
    ThemePreference? theme,
    String? defaultProfileId,
    bool? analyticsEnabled,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      defaultProfileId: defaultProfileId ?? this.defaultProfileId,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme.name,
      'defaultProfileId': defaultProfileId,
      'analyticsEnabled': analyticsEnabled,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] as String? ?? 'en',
      theme: ThemePreference.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => ThemePreference.system,
      ),
      defaultProfileId: json['defaultProfileId'] as String?,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
    );
  }
}

/// Theme preference options.
enum ThemePreference {
  light,
  dark,
  system,
}

/// User document stored in Firestore.
class UserDocument {
  const UserDocument({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.lastSyncAt,
    required this.providers,
    this.status = UserStatus.active,
    required this.preferences,
    this.subscription,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastSyncAt;
  final List<String> providers;
  final UserStatus status;
  final UserPreferences preferences;
  final UserSubscription? subscription;

  UserDocument copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastSyncAt,
    List<String>? providers,
    UserStatus? status,
    UserPreferences? preferences,
    UserSubscription? subscription,
  }) {
    return UserDocument(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      providers: providers ?? this.providers,
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      subscription: subscription ?? this.subscription,
    );
  }
}

/// User account status.
enum UserStatus {
  active,
  suspended,
  deleted,
}

/// Denormalized subscription info in user document.
class UserSubscription {
  const UserSubscription({
    required this.tier,
    this.expiresAt,
    this.platform,
    this.autoRenew = false,
  });

  final String tier;
  final DateTime? expiresAt;
  final String? platform;
  final bool autoRenew;

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'expiresAt': expiresAt?.toIso8601String(),
      'platform': platform,
      'autoRenew': autoRenew,
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      tier: json['tier'] as String? ?? 'free',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      platform: json['platform'] as String?,
      autoRenew: json['autoRenew'] as bool? ?? false,
    );
  }
}

/// Repository interface for user document operations.
abstract class UserRepository {
  /// Gets the user document for the given user ID.
  Future<UserDocument?> getUser(String userId);

  /// Creates a new user document.
  Future<void> createUser(UserDocument user);

  /// Updates an existing user document.
  Future<void> updateUser(UserDocument user);

  /// Updates user preferences.
  Future<void> updatePreferences(String userId, UserPreferences preferences);

  /// Updates the last login timestamp.
  Future<void> updateLastLogin(String userId);

  /// Stream of user document changes.
  Stream<UserDocument?> watchUser(String userId);

  /// Checks if a user document exists.
  Future<bool> userExists(String userId);
}
