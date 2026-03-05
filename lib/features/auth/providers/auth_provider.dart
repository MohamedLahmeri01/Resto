import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({User? user, bool? isLoading, bool? isAuthenticated, String? error}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    error: error,
  );

  static const initial = AuthState();
  static const loading = AuthState(isLoading: true);
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState.initial);

  Future<void> initialize() async {
    state = AuthState.loading;
    final token = await _repo.accessToken;
    if (token == null) {
      state = AuthState.initial;
      return;
    }
    final result = await _repo.getMe();
    if (result.isSuccess && result.data != null) {
      state = AuthState(user: result.data, isAuthenticated: true);
    } else {
      // Try refresh
      final refresh = await _repo.refresh();
      if (refresh.isSuccess && refresh.data != null) {
        state = AuthState(user: refresh.data!.user, isAuthenticated: true);
      } else {
        await _repo.clearTokens();
        state = AuthState.initial;
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.login(email, password);
    if (result.isSuccess && result.data != null) {
      state = AuthState(user: result.data!.user, isAuthenticated: true);
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error?.message ?? 'Login failed');
    return false;
  }

  Future<bool> loginPin(String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    final tenantId = await _repo.tenantId;
    if (tenantId == null) {
      state = state.copyWith(isLoading: false, error: 'No tenant configured');
      return false;
    }
    final result = await _repo.loginPin(pin, tenantId);
    if (result.isSuccess && result.data != null) {
      state = AuthState(user: result.data!.user, isAuthenticated: true);
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error?.message ?? 'Invalid PIN');
    return false;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState.initial;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
