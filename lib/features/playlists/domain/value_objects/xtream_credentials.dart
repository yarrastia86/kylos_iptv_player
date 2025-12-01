// Kylos IPTV Player - Xtream Credentials Value Object
// Value object for Xtream Codes API credentials.

import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';

/// Result of credentials validation.
sealed class XtreamCredentialsValidation {
  const XtreamCredentialsValidation();
}

/// Credentials are valid.
class XtreamCredentialsValid extends XtreamCredentialsValidation {
  const XtreamCredentialsValid();
}

/// Credentials are invalid with specific field errors.
class XtreamCredentialsInvalid extends XtreamCredentialsValidation {
  const XtreamCredentialsInvalid({
    this.serverUrlError,
    this.usernameError,
    this.passwordError,
  });

  final String? serverUrlError;
  final String? usernameError;
  final String? passwordError;

  /// Returns true if any field has an error.
  bool get hasErrors =>
      serverUrlError != null ||
      usernameError != null ||
      passwordError != null;

  /// Returns all error messages.
  List<String> get allErrors => [
        if (serverUrlError != null) serverUrlError!,
        if (usernameError != null) usernameError!,
        if (passwordError != null) passwordError!,
      ];
}

/// Value object representing validated Xtream Codes API credentials.
///
/// Contains server URL, username, and password required for Xtream API access.
/// Immutable and validates all fields on construction.
class XtreamCredentials {
  XtreamCredentials._({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  /// The Xtream server URL.
  final PlaylistUrl serverUrl;

  /// The username for authentication.
  final String username;

  /// The password for authentication.
  final String password;

  /// Creates credentials from raw strings, returning null if invalid.
  static XtreamCredentials? tryCreate({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final validation = validate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    if (validation is XtreamCredentialsInvalid) {
      return null;
    }

    final url = PlaylistUrl.tryParse(serverUrl);
    if (url == null) return null;

    return XtreamCredentials._(
      serverUrl: url,
      username: username.trim(),
      password: password,
    );
  }

  /// Creates credentials from raw strings, throwing if invalid.
  factory XtreamCredentials.create({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final result = tryCreate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    if (result == null) {
      throw const FormatException('Invalid Xtream credentials');
    }
    return result;
  }

  /// Validates credentials and returns detailed validation result.
  static XtreamCredentialsValidation validate({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    String? serverUrlError;
    String? usernameError;
    String? passwordError;

    // Validate server URL
    final urlValidation = PlaylistUrl.validate(serverUrl);
    if (urlValidation is PlaylistUrlInvalid) {
      serverUrlError = urlValidation.reason;
    }

    // Validate username
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      usernameError = 'Username cannot be empty';
    } else if (trimmedUsername.length < 2) {
      usernameError = 'Username must be at least 2 characters';
    }

    // Validate password
    if (password.isEmpty) {
      passwordError = 'Password cannot be empty';
    }

    if (serverUrlError != null ||
        usernameError != null ||
        passwordError != null) {
      return XtreamCredentialsInvalid(
        serverUrlError: serverUrlError,
        usernameError: usernameError,
        passwordError: passwordError,
      );
    }

    return const XtreamCredentialsValid();
  }

  /// Builds the Xtream API player URL for live streams.
  String buildLiveStreamUrl(String streamId, String extension) {
    return '${serverUrl.value}/live/$username/$password/$streamId.$extension';
  }

  /// Builds the Xtream API VOD URL.
  String buildVodUrl(String streamId, String extension) {
    return '${serverUrl.value}/movie/$username/$password/$streamId.$extension';
  }

  /// Builds the Xtream API series URL.
  String buildSeriesUrl(String streamId, String extension) {
    return '${serverUrl.value}/series/$username/$password/$streamId.$extension';
  }

  /// Builds the Xtream API endpoint URL for a given action.
  String buildApiUrl(String action) {
    return '${serverUrl.value}/player_api.php'
        '?username=$username'
        '&password=$password'
        '&action=$action';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XtreamCredentials &&
          runtimeType == other.runtimeType &&
          serverUrl == other.serverUrl &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => Object.hash(serverUrl, username, password);

  @override
  String toString() => 'XtreamCredentials(${serverUrl.host}, $username)';
}
