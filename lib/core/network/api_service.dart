import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final Dio _dio;

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get client => _dio;
}
