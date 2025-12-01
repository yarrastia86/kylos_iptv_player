// Kylos IPTV Player - Local Storage Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/infrastructure/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorage', () {
    late LocalStorage localStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorage(preferences: prefs);
    });

    test('should store and retrieve string', () async {
      await localStorage.setString('key', 'value');
      expect(localStorage.getString('key'), 'value');
    });

    test('should store and retrieve bool', () async {
      await localStorage.setBool('key', true);
      expect(localStorage.getBool('key'), true);
    });

    test('should store and retrieve int', () async {
      await localStorage.setInt('key', 42);
      expect(localStorage.getInt('key'), 42);
    });

    test('should store and retrieve double', () async {
      await localStorage.setDouble('key', 3.14);
      expect(localStorage.getDouble('key'), 3.14);
    });

    test('should store and retrieve string list', () async {
      await localStorage.setStringList('key', ['a', 'b', 'c']);
      expect(localStorage.getStringList('key'), ['a', 'b', 'c']);
    });

    test('should return null for non-existent keys', () {
      expect(localStorage.getString('nonexistent'), isNull);
      expect(localStorage.getBool('nonexistent'), isNull);
      expect(localStorage.getInt('nonexistent'), isNull);
    });

    test('should check if key exists', () async {
      expect(localStorage.containsKey('key'), false);
      await localStorage.setString('key', 'value');
      expect(localStorage.containsKey('key'), true);
    });

    test('should remove key', () async {
      await localStorage.setString('key', 'value');
      expect(localStorage.containsKey('key'), true);

      await localStorage.remove('key');
      expect(localStorage.containsKey('key'), false);
    });

    test('should clear all keys', () async {
      await localStorage.setString('key1', 'value1');
      await localStorage.setString('key2', 'value2');

      await localStorage.clear();

      expect(localStorage.containsKey('key1'), false);
      expect(localStorage.containsKey('key2'), false);
    });
  });
}
