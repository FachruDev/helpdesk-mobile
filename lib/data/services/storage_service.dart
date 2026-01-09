import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys
  static const String _keyCustomerToken = 'customer_token';
  static const String _keyInternalToken = 'internal_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUserRole = 'user_role';

  // Save customer token
  static Future<void> saveCustomerToken(String token) async {
    await _storage.write(key: _keyCustomerToken, value: token);
    await _storage.write(key: _keyUserRole, value: 'customer');
  }

  // Get customer token
  static Future<String?> getCustomerToken() async {
    return await _storage.read(key: _keyCustomerToken);
  }

  // Save internal token
  static Future<void> saveInternalToken(String token) async {
    await _storage.write(key: _keyInternalToken, value: token);
    await _storage.write(key: _keyUserRole, value: 'internal');
  }

  // Get internal token
  static Future<String?> getInternalToken() async {
    return await _storage.read(key: _keyInternalToken);
  }

  // Get current user role
  static Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  // Save user data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _keyUserData, value: userData);
  }

  // Get user data
  static Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  // Clear customer session
  static Future<void> clearCustomerSession() async {
    await _storage.delete(key: _keyCustomerToken);
    await _storage.delete(key: _keyUserData);
    final role = await getUserRole();
    if (role == 'customer') {
      await _storage.delete(key: _keyUserRole);
    }
  }

  // Clear internal session
  static Future<void> clearInternalSession() async {
    await _storage.delete(key: _keyInternalToken);
    await _storage.delete(key: _keyUserData);
    final role = await getUserRole();
    if (role == 'internal') {
      await _storage.delete(key: _keyUserRole);
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if customer is logged in
  static Future<bool> isCustomerLoggedIn() async {
    final token = await getCustomerToken();
    return token != null && token.isNotEmpty;
  }

  // Check if internal is logged in
  static Future<bool> isInternalLoggedIn() async {
    final token = await getInternalToken();
    return token != null && token.isNotEmpty;
  }
}
