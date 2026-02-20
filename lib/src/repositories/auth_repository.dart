import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/auth_tokens.dart';

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json),
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse?> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      });

      print('Register Response: ${res.data}');
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioError catch (e) {
      print('Register Error: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected Register Error: $e');
      return null;
    }
  }

  Future<AuthResponse?> login({
    required String email,
    required String password
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password':password
      });

      print('Login Response: ${res.data}');
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioError catch (e) {
      print('Login Error: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected Login Error: $e');
      return null;
    }
  }

  Future<AuthResponse?> refresh(String refreshToken) async {
    try {
      final res = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      print('Refresh Response: ${res.data}');
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioError catch (e) {
      print('Refresh Error: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected Refresh Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final res = await _dio.post('/auth/logout');
      print('Logout Response: ${res.data}');
    } on DioError catch (e) {
      print('Logout Error: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('Unexpected Logout Error: $e');
    }
  }
}
