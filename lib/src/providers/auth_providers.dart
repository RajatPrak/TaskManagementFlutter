import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/auth_tokens.dart';
import '../services/token_storage.dart';
import '../repositories/auth_repository.dart';
import 'dio_provider.dart';

class AuthState {
  final User? user;
  final AuthTokens? tokens;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.tokens,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && tokens != null;

  AuthState copyWith({
    User? user,
    AuthTokens? tokens,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory AuthState.initial() => AuthState(isLoading: false);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthController(this._repository, this._tokenStorage) : super(AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      return;
    }
    // Try to refresh to validate
    try {
      final authResponse = await _repository.refresh(tokens.refreshToken);
      await _tokenStorage.saveTokens(authResponse!.tokens);
      state = state.copyWith(
        user: authResponse.user,
        tokens: authResponse.tokens,
      );
    } catch (_) {
      await _tokenStorage.clearTokens();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.register(
        email: email,
        password: password,
        name: name,
      );
      await _tokenStorage.saveTokens(res!.tokens);
      state = AuthState(user: res.user, tokens: res.tokens, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed',
      );
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.login(email: email,password: password);
      await _tokenStorage.saveTokens(res!.tokens);
      state = AuthState(user: res.user, tokens: res.tokens, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid credentials',
      );
      rethrow;
    }
  }

  Future<AuthTokens?> refreshTokensIfPossible() async {
    final tokens = state.tokens ?? await _tokenStorage.readTokens();
    if (tokens == null) return null;

    try {
      final res = await _repository.refresh(tokens.refreshToken);
      await _tokenStorage.saveTokens(res!.tokens);
      state = state.copyWith(user: res.user, tokens: res.tokens);
      return res.tokens;
    } catch (_) {
      await _tokenStorage.clearTokens();
      state = AuthState.initial();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (state.tokens != null) {
        await _repository.logout();
      }
    } catch (_) {
      // ignore network error on logout
    }
    await _tokenStorage.clearTokens();
    state = AuthState.initial();
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.read(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final tokens = ref.read(tokenStorageProvider);
  return AuthController(repo, tokens);
});
