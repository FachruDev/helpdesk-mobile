import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class CustomerAuthRepository {
  /// Login customer
  /// Support FCM token registration saat login (v1.3)
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    String? fcmToken,
    String? platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerLogin}');
      
      final body = {
        'email': email,
        'password': password,
      };
      
      // Add FCM token if provided (v1.3 feature)
      if (fcmToken != null) {
        body['fcm_token'] = fcmToken;
        if (platform != null) body['platform'] = platform;
        if (deviceId != null) body['device_id'] = deviceId;
        if (appVersion != null) body['app_version'] = appVersion;
      }
      
      final response = await http.post(
        url,
        headers: ApiConfig.headers(),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (kDebugMode) {
        print('[Customer Login] Status: ${response.statusCode}');
        print('[Customer Login] Response keys: ${responseData.keys.toList()}');
        print('[Customer Login] success: ${responseData['success']}');
        print('[Customer Login] has token: ${responseData.containsKey('token')}');
        print('[Customer Login] has data: ${responseData.containsKey('data')}');
        print('[Customer Login] has user: ${responseData.containsKey('user')}');
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token'] ?? responseData['data']?['token'];
        // Parse user data: coba 'user' root, 'data.user', atau 'data' langsung
        var userData = responseData['user'] ?? responseData['data']?['user'];
        // Jika data ada tapi bukan nested user, data mungkin IS the user object
        if (userData == null && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          // Jika data punya field name/email, itu adalah user object langsung
          if (data.containsKey('name') || data.containsKey('email') || data.containsKey('id')) {
            userData = data;
          }
        }
        final fcmRegistered = responseData['data']?['fcm_registered'] ?? responseData['fcm_registered'] ?? false;

        if (token != null) {
          // Save token to secure storage
          await StorageService.saveCustomerToken(token);
          
          // Save user data if available
          if (userData != null) {
            await StorageService.saveUserData(jsonEncode(userData));
          }

          return ApiResponse.success({
            'token': token,
            'user': userData != null ? UserModel.fromJson(userData) : null,
            'fcm_registered': fcmRegistered,
          }, message: responseData['message'] ?? 'Login successful');
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Login failed',
        statusCode: response.statusCode,
        errors: responseData['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<ApiResponse<UserModel>> me() async {
    try {
      final token = await StorageService.getCustomerToken();
      if (token == null) {
        return ApiResponse.error('No token found');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerMe}');
      
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final userData = responseData['user'] ?? responseData['data'];
        
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          
          // Update stored user data
          await StorageService.saveUserData(jsonEncode(userData));
          
          return ApiResponse.success(user);
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch user data',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Logout customer
  /// Support FCM token unregister saat logout (v1.3)
  /// Jika removeDeviceToken = true, kirim fcm_token dan remove_device_token flag
  /// Jika false (default), logout biasa tanpa unregister FCM token
  Future<ApiResponse<void>> logout({
    String? fcmToken,
    bool removeDeviceToken = false,
  }) async {
    try {
      final token = await StorageService.getCustomerToken();
      
      if (token != null) {
        final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerLogout}');
        
        final body = <String, dynamic>{};
        
        // Hanya kirim fcm_token jika user pilih remove device
        if (removeDeviceToken && fcmToken != null) {
          body['fcm_token'] = fcmToken;
          body['remove_device_token'] = true;
        }
        
        // Try to logout from server
        await http.post(
          url,
          headers: ApiConfig.headers(token: token),
          body: body.isNotEmpty ? jsonEncode(body) : null,
        );
      }

      // Clear local storage regardless of API response
      await StorageService.clearCustomerSession();
      
      return ApiResponse.success(null, message: 'Logged out successfully');
    } catch (e) {
      // Still clear local storage even if API fails
      await StorageService.clearCustomerSession();
      return ApiResponse.success(null, message: 'Logged out locally');
    }
  }

  /// Check if customer is authenticated
  Future<bool> isAuthenticated() async {
    return await StorageService.isCustomerLoggedIn();
  }

  /// Get stored user data
  Future<UserModel?> getStoredUser() async {
    try {
      final userData = await StorageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
