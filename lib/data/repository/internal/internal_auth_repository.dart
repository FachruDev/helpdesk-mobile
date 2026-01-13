import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class InternalAuthRepository {
  /// Login internal/employee
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalLogin}');
      
      final response = await http.post(
        url,
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token'] ?? responseData['data']?['token'];
        final userData = responseData['user'] ?? responseData['data']?['user'];

        if (token != null) {
          // Save token to secure storage
          await StorageService.saveInternalToken(token);
          
          // Save user data if available
          if (userData != null) {
            await StorageService.saveUserData(jsonEncode(userData));
          }

          return ApiResponse.success({
            'token': token,
            'user': userData != null ? UserModel.fromJson(userData) : null,
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
      final token = await StorageService.getInternalToken();
      if (token == null) {
        return ApiResponse.error('No token found');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalMe}');
      
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

  /// Logout internal
  Future<ApiResponse<void>> logout() async {
    try {
      final token = await StorageService.getInternalToken();
      
      if (token != null) {
        final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalLogout}');
        
        // Try to logout from server
        await http.post(
          url,
          headers: ApiConfig.headers(token: token),
        );
      }

      // Clear local storage regardless of API response
      await StorageService.clearInternalSession();
      
      return ApiResponse.success(null, message: 'Logged out successfully');
    } catch (e) {
      // Still clear local storage even if API fails
      await StorageService.clearInternalSession();
      return ApiResponse.success(null, message: 'Logged out locally');
    }
  }

  /// Check if internal is authenticated
  Future<bool> isAuthenticated() async {
    return await StorageService.isInternalLoggedIn();
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
