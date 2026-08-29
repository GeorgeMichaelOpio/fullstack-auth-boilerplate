import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

/// A user-facing error with a message safe to show in the UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Single shared Dio instance for the whole app.
///
/// Why this exists instead of `Dio().post(...)` scattered through widgets:
/// - One place sets the base URL, so no hardcoded IPs/ports in UI code.
/// - One place sets connect/receive timeouts, so a dead server doesn't hang
///   a request (and the loading spinner) forever.
/// - An interceptor automatically attaches the auth token to every request
///   once the user is logged in.
/// - DioException is translated into a single ApiException with a message
///   that's actually safe and useful to show a user, instead of every
///   call site re-implementing its own status-code switch.
class ApiClient {
  ApiClient({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: Environment.apiBaseUrl,
            connectTimeout: Environment.connectTimeout,
            receiveTimeout: Environment.receiveTimeout,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    if (Environment.enableVerboseLogging) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;
  final SecureStorageService _storage;

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    AppLogger.error('API error on ${e.requestOptions.path}', error: e);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'The connection timed out. Please check your internet and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Could not reach the server. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final serverMessage = e.response?.data is Map
            ? (e.response?.data['message'] ?? e.response?.data['error'])
            : null;
        if (status == 401) {
          return ApiException(
            serverMessage?.toString() ?? 'Invalid email or password',
            statusCode: status,
          );
        }
        if (status == 409 || status == 400) {
          return ApiException(
            serverMessage?.toString() ?? 'That email is already registered',
            statusCode: status,
          );
        }
        return ApiException(
          serverMessage?.toString() ?? 'Something went wrong (error $status)',
          statusCode: status,
        );
      default:
        return const ApiException('Something went wrong. Please try again.');
    }
  }
}
