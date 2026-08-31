import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';
import '../utils/jwt_utils.dart';
import 'secure_storage_service.dart';

/// A user-facing error with a message safe to show in the UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  /// Populated when the server returns a `Retry-After` header on a 429 -
  /// lets the UI show "try again in Ns" instead of a generic message.
  final int? retryAfterSeconds;

  const ApiException(this.message, {this.statusCode, this.retryAfterSeconds});

  @override
  String toString() => message;
}

/// Single shared Dio instance for the whole app.
///
/// Token lifecycle implemented here:
/// - Every outgoing authenticated request checks whether the stored access
///   token is a JWT that's about to expire and, if so, refreshes it BEFORE
///   sending the request (avoids a guaranteed-failing round trip).
/// - Any response that still comes back 401 (opaque token expired
///   server-side, clock drift, etc.) triggers exactly ONE refresh attempt
///   and retries the original request - concurrent requests that all hit
///   401 at once share a single in-flight refresh call instead of each
///   firing their own (a "thundering herd" of simultaneous refresh calls
///   is a common bug in naive implementations and can race the server
///   into invalidating a token your own app just issued).
/// - If refresh itself fails, tokens are cleared and [onSessionExpired] is
///   invoked so the app can drop the user back to login with an
///   explanation, rather than looping or silently hanging.
class ApiClient {
  ApiClient({
    SecureStorageService? storage,
    this.onSessionExpired,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: Environment.apiBaseUrl,
            connectTimeout: Environment.connectTimeout,
            receiveTimeout: Environment.receiveTimeout,
          ),
        ) {
    _configureCertificatePinning();
    _dio.interceptors.add(_authInterceptor());

    if (Environment.enableVerboseLogging) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  final Dio _dio;
  final SecureStorageService _storage;

  /// Called when the refresh token itself is invalid/expired - i.e. the
  /// user genuinely needs to log in again. Wire this to force-logout logic
  /// in AuthProvider from main.dart.
  final void Function()? onSessionExpired;

  Future<String?>? _refreshingFuture;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] == true) {
          return handler.next(options);
        }
        var token = await _storage.readAccessToken();
        if (token != null && JwtUtils.isExpiringSoon(token)) {
          token = await _refreshAccessToken();
        }
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final alreadyRetried = requestOptions.extra['retriedAfterRefresh'] == true;
        final isAuthEndpoint = requestOptions.extra['skipAuth'] == true;

        if (error.response?.statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
          final newToken = await _refreshAccessToken();
          if (newToken != null) {
            requestOptions.extra['retriedAfterRefresh'] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          } else {
            await _storage.clearTokens();
            onSessionExpired?.call();
          }
        }
        handler.next(error);
      },
    );
  }

  /// Single-flight guard: if a refresh is already in progress, every caller
  /// awaits the same future instead of starting a new refresh request.
  Future<String?> _refreshAccessToken() {
    return _refreshingFuture ??= _performRefresh().whenComplete(() => _refreshingFuture = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final newAccess = response.data?['access_token'] ?? response.data?['token'];
      final newRefresh = response.data?['refresh_token'];
      if (newAccess == null) return null;

      await _storage.saveAccessToken(newAccess.toString());
      if (newRefresh != null) {
        await _storage.saveRefreshToken(newRefresh.toString());
      }
      return newAccess.toString();
    } catch (e) {
      AppLogger.warning('Token refresh failed: $e');
      return null;
    }
  }

  /// Certificate pinning.
  ///
  /// IMPORTANT - what this hook actually does: `badCertificateCallback` on
  /// Dart's `HttpClient` only fires for certificates that ALREADY fail
  /// normal platform trust validation (expired, wrong host, self-signed,
  /// untrusted CA). It does NOT get called for a certificate that chains
  /// to a trusted root but simply isn't the one you expect - so this alone
  /// is not full SPKI pinning. What it DOES protect against: interception
  /// tooling (Charles, mitmproxy, Burp) whose root CA the OS doesn't
  /// already trust - a large share of real-world MITM attempts on mobile.
  ///
  /// For genuine pinning against any certificate (including ones from a
  /// compromised or coerced CA), pin at the OS level instead:
  /// - Android: `network_security_config.xml` with a `<pin-set>` - see
  ///   `native-config/android/network_security_config.xml` in this project.
  /// - iOS: App Transport Security + a native pinning library (e.g.
  ///   TrustKit) - Dart-level hooks on iOS cannot intercept the TLS
  ///   handshake as reliably as Android's Network Security Config does.
  ///
  /// Left with no fingerprints configured (the default), this is a no-op.
  void _configureCertificatePinning() {
    final pins = Environment.pinnedCertSha256Fingerprints;
    if (pins.isEmpty) return;

    final adapter = _dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          final fingerprint = sha256.convert(cert.der).toString().toUpperCase();
          final trusted = pins.contains(fingerprint);
          if (!trusted) {
            AppLogger.error('Certificate pinning rejected an untrusted cert for $host');
          }
          return trusted;
        };
        return client;
      };
    }
  }

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
        final data = e.response?.data;
        final serverMessage = data is Map ? (data['message'] ?? data['error']) : null;

        if (status == 401) {
          return ApiException(serverMessage?.toString() ?? 'Invalid email or password', statusCode: status);
        }
        if (status == 409 || status == 400) {
          return ApiException(serverMessage?.toString() ?? 'That email is already registered', statusCode: status);
        }
        if (status == 429) {
          final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '');
          return ApiException(
            serverMessage?.toString() ?? 'Too many attempts. Please wait before trying again.',
            statusCode: status,
            retryAfterSeconds: retryAfter,
          );
        }
        return ApiException(serverMessage?.toString() ?? 'Something went wrong (error $status)', statusCode: status);
      default:
        return const ApiException('Something went wrong. Please try again.');
    }
  }
}
