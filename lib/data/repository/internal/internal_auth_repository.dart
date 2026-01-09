// Placeholder for Internal Auth Repository
// This will be implemented later for internal/employee users

import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';

class InternalAuthRepository {
  // TODO: Implement internal auth repository
  
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Internal login not implemented yet');
  }

  Future<ApiResponse<UserModel>> me() async {
    throw UnimplementedError('Internal me not implemented yet');
  }

  Future<ApiResponse<void>> logout() async {
    throw UnimplementedError('Internal logout not implemented yet');
  }

  Future<bool> isAuthenticated() async {
    throw UnimplementedError('Internal isAuthenticated not implemented yet');
  }

  Future<UserModel?> getStoredUser() async {
    throw UnimplementedError('Internal getStoredUser not implemented yet');
  }
}
