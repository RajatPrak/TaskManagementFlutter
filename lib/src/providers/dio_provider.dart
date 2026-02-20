import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

const String apiBaseUrl = 'http://192.168.1.25:3000'; // Android emulator <> backend

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Attach ApiClient to set interceptors
  ApiClient(dio, ref);

  return dio;
});
