import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

class ApiClient {
  ApiClient({
    required ApiConfig config,
    Dio? dio,
  }) : _dio = dio ?? _buildDio(config);

  final Dio _dio;

  Future<Response<T>> postFormData<T>(
    String path, {
    required Map<String, dynamic> fields,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: FormData.fromMap(fields),
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Dio _buildDio(ApiConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          'Authorization': config.bearerToken,
        },
      ),
    );

    // В release логи отключены; в debug/profile — видны POST (в т.ч. save) в консоли.
    if (!kReleaseMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return dio;
  }
}

