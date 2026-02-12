import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_auth_repository.dart';
import 'package:helpdesk_mobile/data/services/fcm_service.dart';
import 'package:helpdesk_mobile/data/services/fcm_api_service.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

// Repository Provider
final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((ref) {
  return CustomerAuthRepository();
});

// Auth State
class CustomerAuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  CustomerAuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  CustomerAuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return CustomerAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

// Auth Notifier
class CustomerAuthNotifier extends Notifier<CustomerAuthState> {
  CustomerAuthRepository get _repository => ref.read(customerAuthRepositoryProvider);

  @override
  CustomerAuthState build() {
    _checkAuthStatus();
    return CustomerAuthState();
  }

  // Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      final user = await _repository.getStoredUser();
      // Validate token by calling me endpoint
      final response = await _repository.me();
      if (response.success && response.data != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: response.data,
        );
      } else {
        // Token invalid, logout
        await _repository.logout();
        state = CustomerAuthState(
          isAuthenticated: false,
        );
      }
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final user = response.data!['user'] as UserModel?;
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          errorMessage: null,
        );
        
        // Register FCM token after successful login
        _registerFcmToken();
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: response.message ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Fetch user profile
  Future<void> fetchProfile() async {
    try {
      final response = await _repository.me();
      
      if (response.success && response.data != null) {
        state = state.copyWith(
          user: response.data,
          isAuthenticated: true,
        );
      } else {
        // Token invalid, logout
        await logout();
      }
    } catch (e) {
      // Handle error silently or update state if needed
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Unregister FCM token before logout
      await _unregisterFcmToken();
      
      await _repository.logout();
      
      state = CustomerAuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = CustomerAuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }
  
  // Register FCM token
  Future<void> _registerFcmToken() async {
    try {
      final fcmService = FcmService();
      final token = await StorageService.getCustomerToken();
      
      if (token == null || fcmService.fcmToken == null) return;
      
      final deviceInfo = fcmService.getDeviceInfo();
      await FcmApiService.registerCustomerToken(
        token: token,
        fcmToken: deviceInfo['fcm_token'],
        platform: deviceInfo['platform'],
        appVersion: deviceInfo['app_version'],
      );
    } catch (e) {
      // Handle silently
    }
  }
  
  // Unregister FCM token
  Future<void> _unregisterFcmToken() async {
    try {
      final fcmService = FcmService();
      final token = await StorageService.getCustomerToken();
      
      if (token == null || fcmService.fcmToken == null) return;
      
      await FcmApiService.unregisterCustomerToken(
        token: token,
        fcmToken: fcmService.fcmToken!,
      );
      
      await fcmService.deleteToken();
    } catch (e) {
      // Handle silently
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final customerAuthProvider = NotifierProvider<CustomerAuthNotifier, CustomerAuthState>(() {
  return CustomerAuthNotifier();
});
