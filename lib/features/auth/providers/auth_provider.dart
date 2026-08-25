import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/secure_storage.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await SecureStorage.getToken();
      if (token != null) {
        final user = await _authService.getProfile();
        state = state.copyWith(user: user, isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      await SecureStorage.deleteToken();
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(email, password);
      final token = response['access_token'] as String;
      await SecureStorage.saveToken(token);
      
      final user = await _authService.getProfile();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please check your email and password.');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
