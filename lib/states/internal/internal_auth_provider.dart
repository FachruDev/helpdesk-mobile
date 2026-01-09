// Placeholder for Internal Auth Provider
// This will be implemented later for internal/employee users

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/user_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_auth_repository.dart';

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
  @override
  InternalAuthState build() {
    return InternalAuthState();
  }

  // TODO: Implement internal auth methods
  Future<bool> login({required String email, required String password}) async {
    throw UnimplementedError('Internal login not implemented yet');
  }

  Future<void> fetchProfile() async {
    throw UnimplementedError('Internal fetchProfile not implemented yet');
  }

  Future<void> logout() async {
    throw UnimplementedError('Internal logout not implemented yet');
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final internalAuthProvider = NotifierProvider<InternalAuthNotifier, InternalAuthState>(() {
  return InternalAuthNotifier();
});
