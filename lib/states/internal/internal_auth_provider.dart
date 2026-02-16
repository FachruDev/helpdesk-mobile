import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_auth_repository.dart';
import 'package:helpdesk_mobile/data/services/fcm_service.dart';
import 'package:helpdesk_mobile/data/services/fcm_api_service.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

// Repository Provider
final internalAuthRepositoryProvider = Provider<InternalAuthRepository>((ref) {
  return InternalAuthRepository();
});

// Auth State
class InternalAuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  InternalAuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  InternalAuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return InternalAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

// Auth Notifier
class InternalAuthNotifier extends Notifier<InternalAuthState> {
  InternalAuthRepository get _repository => ref.read(internalAuthRepositoryProvider);
  bool _isLoginInProgress = false;

  @override
  InternalAuthState build() {
    _checkAuthStatus();
    return InternalAuthState();
  }

  // Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      // Jika login sedang berlangsung, jangan interfere
      if (_isLoginInProgress || state.isAuthenticated) return;
      
      // Coba validasi token dengan me endpoint
      final response = await _repository.me();
      
      // Cek lagi sebelum update state (login mungkin sudah selesai)
      if (_isLoginInProgress || state.isAuthenticated) return;
      
      if (response.success && response.data != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: response.data,
        );
      } else {
        // Token invalid, clear session TANPA affect state yang mungkin sudah diset login
        await _repository.logout();
        if (!_isLoginInProgress && !state.isAuthenticated) {
          state = InternalAuthState(isAuthenticated: false);
        }
      }
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _isLoginInProgress = true;

    try {
      // PENTING: Request FRESH token dari Firebase sebelum login
      // Jangan pakai cache lama yang bisa sudah UNREGISTERED
      final fcmService = FcmService();
      await fcmService.getOrRefreshToken();
      final deviceInfo = fcmService.getDeviceInfo();
      
      if (kDebugMode) {
        print('[Internal Login] FCM token: ${deviceInfo['fcm_token']}');
      }
      
      final response = await _repository.login(
        email: email,
        password: password,
        fcmToken: deviceInfo['fcm_token'],
        platform: deviceInfo['platform'],
        appVersion: deviceInfo['app_version'],
      );

      if (response.success && response.data != null) {
        final user = response.data!['user'] as UserModel?;
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          errorMessage: null,
        );
        
        // FCM token sudah di-register saat login (v1.3)
        // Fallback: register jika belum
        final fcmRegistered = response.data!['fcm_registered'] as bool? ?? false;
        if (!fcmRegistered) {
          _registerFcmToken();
        }
        
        return true;
      } else {
        _isLoginInProgress = false;
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: response.message ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      _isLoginInProgress = false;
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
        // JANGAN langsung logout - mungkin hanya network error sementara
        // Hanya logout jika benar-benar 401 unauthorized
        if (response.statusCode == 401) {
          await logout();
        } else {
          if (kDebugMode) {
            print('[Internal] fetchProfile failed but not 401, keeping session');
            print('[Internal] Status: ${response.statusCode}, Message: ${response.message}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Internal] fetchProfile error: $e');
      }
      // Network error, jangan logout
    }
  }

  // Logout
  // Default: logout biasa tanpa remove FCM token dari device
  // Jika removeDeviceToken = true, akan unregister FCM token dan hapus dari device
  Future<void> logout({bool removeDeviceToken = false}) async {
    _isLoginInProgress = false;
    state = state.copyWith(isLoading: true);

    try {
      if (removeDeviceToken) {
        // User pilih "remove this device"
        final fcmService = FcmService();
        final fcmToken = fcmService.fcmToken;
        
        // Logout dengan unregister FCM token
        await _repository.logout(
          fcmToken: fcmToken,
          removeDeviceToken: true,
        );
        
        // Delete local FCM token
        await fcmService.deleteToken();
      } else {
        // Logout biasa, FCM token tetap ada di device
        await _repository.logout();
      }
      
      state = InternalAuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = InternalAuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }
  
  // Register FCM token (fallback jika login tidak register)
  Future<void> _registerFcmToken() async {
    try {
      final fcmService = FcmService();
      final token = await StorageService.getInternalToken();
      
      if (token == null || fcmService.fcmToken == null) return;
      
      final deviceInfo = fcmService.getDeviceInfo();
      await FcmApiService.registerInternalToken(
        token: token,
        fcmToken: deviceInfo['fcm_token'],
        platform: deviceInfo['platform'],
        appVersion: deviceInfo['app_version'],
      );
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
final internalAuthProvider = NotifierProvider<InternalAuthNotifier, InternalAuthState>(() {
  return InternalAuthNotifier();
});
