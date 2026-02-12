import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';

class FcmApiService {
  /// Register FCM token untuk customer
  static Future<bool> registerCustomerToken({
    required String token,
    required String fcmToken,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerFcmToken}');
      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
          if (appVersion != null) 'app_version': appVersion,
        }),
      );

      if (kDebugMode) {
        print('Register customer FCM token response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to register customer FCM token: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering customer FCM token: $e');
      }
      return false;
    }
  }

  /// Register FCM token untuk internal user
  static Future<bool> registerInternalToken({
    required String token,
    required String fcmToken,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalFcmToken}');
      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
          if (appVersion != null) 'app_version': appVersion,
        }),
      );

      if (kDebugMode) {
        print('Register internal FCM token response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to register internal FCM token: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering internal FCM token: $e');
      }
      return false;
    }
  }

  /// Unregister FCM token untuk customer (saat logout)
  static Future<bool> unregisterCustomerToken({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerFcmToken}');
      final response = await http.delete(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      if (kDebugMode) {
        print('Unregister customer FCM token response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to unregister customer FCM token: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering customer FCM token: $e');
      }
      return false;
    }
  }

  /// Unregister FCM token untuk internal user (saat logout)
  static Future<bool> unregisterInternalToken({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalFcmToken}');
      final response = await http.delete(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      if (kDebugMode) {
        print('Unregister internal FCM token response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to unregister internal FCM token: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering internal FCM token: $e');
      }
      return false;
    }
  }
}
