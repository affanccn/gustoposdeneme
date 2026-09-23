import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServerUrl = 'gusto_server_url';
  static const String _keyUserPin = 'gusto_user_pin';
  static const String _keyUserName = 'gusto_user_name';
  static const String _keyUserRole = 'gusto_user_role';
  static const String _keyUserId = 'gusto_user_id';
  static const String _keyDemoMode = 'gusto_demo_mode';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? 'http://localhost:3000';
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  static Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDemoMode) ?? true; // Defaults to standalone/demo enabled for instant out-of-the-box readiness
  }

  static Future<void> setDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDemoMode, enabled);
  }

  static Future<Map<String, String>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId) ?? 'waiter-1',
      'name': prefs.getString(_keyUserName) ?? 'Ahmet Yılmaz',
      'role': prefs.getString(_keyUserRole) ?? 'WAITER',
      'pin': prefs.getString(_keyUserPin) ?? '1234',
    };
  }

  static Future<void> saveUserSession(String id, String name, String role, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserPin, pin);
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserPin);
  }
}
