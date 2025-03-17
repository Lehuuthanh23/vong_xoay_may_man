import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'di.dart';

class AppSP {
  static Future<bool> set(key, value) async {
    SharedPreferences pref = getIt.get<SharedPreferences>();
    if (value is String) {
      return pref.setString(key, value);
    }

    if (value is int) {
      return pref.setInt(key, value);
    }

    if (value is List<String>) {
      return pref.setStringList(key, value);
    }

    if (value is bool) {
      return pref.setBool(key, value);
    }

    if (value is double) {
      return pref.setDouble(key, value);
    }

    return false;
  }

  static T? get<T>(key) {
    SharedPreferences pref = getIt.get<SharedPreferences>();

    if (!pref.containsKey(key)) {
      return null;
    }

    if (T == String) {
      return pref.getString(key) as T?;
    }

    if (T == int) {
      return pref.getInt(key) as T?;
    }

    if (T == List<String>) {
      return pref.getStringList(key) as T?;
    }

    if (T == bool) {
      return pref.getBool(key) as T?;
    }

    if (T == double) {
      return pref.getDouble(key) as T?;
    }

    return pref.get(key) as T?;
  }

  static Future<bool> remove(key) async {
    SharedPreferences pref = getIt.get<SharedPreferences>();

    return pref.remove(key);
  }

  /// Store item
  static Future<void> storeItem(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  /// Delete item
  static Future<void> deleteItem(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  /// Retrieve item
  static Future<dynamic> retrieveItem(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(key);
    if (value != null) {
      return jsonDecode(value);
    }
    return null;
  }

  /// Delete all
  static Future<void> deleteAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
