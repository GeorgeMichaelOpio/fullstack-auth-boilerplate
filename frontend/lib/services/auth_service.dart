import '../models/user_model.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class AuthResult {
  final UserModel user;
  const AuthResult(this.user);
}

class AuthService {
  AuthService({ApiClient? apiClient, SecureStorageService? storage})
      : _api = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  final ApiClient _api;
  final SecureStorageService _storage;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/login', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    // Accept either an {access_token, refresh_token} pair or a legacy
    // single `token` field, so this works whether or not your backend has
    // been upgraded to issue refresh tokens yet.
    final accessToken = response.data?['access_token'] ?? response.data?['token'];
    final refreshToken = response.data?['refresh_token'];
    final userJson = response.data?['user'];
    if (accessToken == null || userJson == null) {
      throw const ApiException('Unexpected response from server.');
    }

    await _storage.saveAccessToken(accessToken.toString());
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken.toString());
    }
    return AuthResult(UserModel.fromJson(Map<String, dynamic>.from(userJson)));
  }

  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _api.post('/signup', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
    });
    // Deliberately not auto-logging-in here: many APIs require email
    // verification before a token is issued. Signup succeeding means
    // "show the user a confirmation", not "assume they're authenticated".
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.post('/password-reset/request', data: {'email': email.trim().toLowerCase()});
    // Deliberately does not reveal whether the email exists - the caller
    // should show the same "check your inbox" message either way. Doing
    // otherwise (e.g. throwing a distinct "email not found" error) lets an
    // attacker enumerate registered accounts.
  }

  /// Called on app startup to restore a session. Relies on ApiClient's
  /// interceptor to transparently refresh an expiring/expired access token
  /// using the stored refresh token - this method doesn't need its own
  /// refresh logic.
  ///
  /// Returns `null` when there is genuinely no session to restore (no
  /// token stored, or the server confirmed both tokens are invalid/expired
  /// - both are normal, silent paths back to the login screen). Rethrows
  /// [ApiException] for anything else (offline, timeout, server error) so
  /// the caller can tell the user their session couldn't be *verified*,
  /// which is materially different from being logged out.
  Future<UserModel?> fetchCurrentUser() async {
    String? accessToken;
    try {
      accessToken = await _storage.readAccessToken();
    } catch (_) {
      return null;
    }
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      final response = await _api.get('/me');
      final userJson = response.data?['user'] ?? response.data;
      if (userJson == null) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(userJson));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // ApiClient already attempted a refresh internally before this
        // reached us; a 401 here means the refresh token is also invalid.
        await _storage.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      try {
        // Best-effort server-side revocation so the refresh token can't be
        // replayed after this device logs out. Never block local logout on
        // this - if the network is down, the user should still be able to
        // sign out of the app on their device.
        await _api.post('/logout', data: {'refresh_token': refreshToken});
      } catch (_) {
        // Ignore - local token clearing below still fully logs this device out.
      }
    }
    await _storage.clearTokens();
  }
}
