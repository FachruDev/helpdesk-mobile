import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_auth_repository.dart';

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
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
      );
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
      }
    } catch (e) {
      // Handle error silently or update state if needed
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
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

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final customerAuthProvider = NotifierProvider<CustomerAuthNotifier, CustomerAuthState>(() {
  return CustomerAuthNotifier();
});
