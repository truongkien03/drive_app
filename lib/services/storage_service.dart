import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver.dart';
import '../models/auth_token.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _driverKey = 'driver_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save auth token
  static Future<void> saveToken(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(token.toJson()));
  }

  // Get auth token
  static Future<AuthToken?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenJson = prefs.getString(_tokenKey);
    if (tokenJson != null) {
      return AuthToken.fromJson(jsonDecode(tokenJson));
    }
    return null;
  }

  // Save driver data
  static Future<void> saveDriver(Driver driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverKey, jsonEncode(driver.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get driver data
  static Future<Driver?> getDriver() async {
    final prefs = await SharedPreferences.getInstance();
    final driverJson = prefs.getString(_driverKey);
    if (driverJson != null) {
      return Driver.fromJson(jsonDecode(driverJson));
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_driverKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Save phone number for convenience
  static Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber);
  }

  // Get saved phone number
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone_number');
  }
}
