import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

class ApiClient {
  final Dio dio;
  final Ref ref;

  ApiClient(this.dio, this.ref) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final authState = ref.read(authControllerProvider);
          final tokens = authState.tokens;
          if (tokens != null && options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final statusCode = error.response?.statusCode;

          final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/register') ||
              error.requestOptions.path.contains('/auth/refresh');

          if (statusCode == 401 &&
              !isAuthEndpoint &&
              !(error.requestOptions.extra['__retried'] == true)) {
            try {
              // Try refresh
              final authController = ref.read(authControllerProvider.notifier);
              final newTokens = await authController.refreshTokensIfPossible();
              if (newTokens == null) {
                return handler.next(error);
              }

              // Retry original request
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
              options.extra['__retried'] = true;

              final cloneResponse = await dio.fetch(options);
              return handler.resolve(cloneResponse);
            } catch (_) {
              // Logout on refresh failure
              await ref.read(authControllerProvider.notifier).logout();
              return handler.next(error);
            }
          }

          handler.next(error);
        },
      ),
    );
  }
}
