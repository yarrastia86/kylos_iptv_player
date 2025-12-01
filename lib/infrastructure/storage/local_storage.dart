// Kylos IPTV Player - Local Storage
// Abstraction over SharedPreferences for local data persistence.

import 'package:shared_preferences/shared_preferences.dart';

/// Local storage abstraction.
///
/// Provides a simplified interface over SharedPreferences
/// with support for common data types.
class LocalStorage {
  LocalStorage({required SharedPreferences preferences})
      : _prefs = preferences;

  final SharedPreferences _prefs;

  /// Gets a string value.
  String? getString(String key) => _prefs.getString(key);

  /// Sets a string value.
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// Gets a boolean value.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Sets a boolean value.
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  /// Gets an integer value.
  int? getInt(String key) => _prefs.getInt(key);

  /// Sets an integer value.
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  /// Gets a double value.
  double? getDouble(String key) => _prefs.getDouble(key);

  /// Sets a double value.
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  /// Gets a string list.
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  /// Sets a string list.
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// Removes a value.
  Future<bool> remove(String key) => _prefs.remove(key);

  /// Checks if a key exists.
  bool containsKey(String key) => _prefs.containsKey(key);

  /// Clears all stored values.
  Future<bool> clear() => _prefs.clear();
}
