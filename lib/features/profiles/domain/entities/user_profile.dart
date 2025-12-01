// Kylos IPTV Player - User Profile Entity
// Domain entity representing a user profile.

/// Represents a user profile within the app.
///
/// Multiple profiles can exist under a single account,
/// each with their own preferences and watch history.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isKidsProfile = false,
    this.createdAt,
  });

  /// Unique identifier for this profile.
  final String id;

  /// Display name for the profile.
  final String name;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Whether this is a restricted kids profile.
  final bool isKidsProfile;

  /// When this profile was created.
  final DateTime? createdAt;

  /// Creates a copy with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isKidsProfile,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isKidsProfile: isKidsProfile ?? this.isKidsProfile,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
