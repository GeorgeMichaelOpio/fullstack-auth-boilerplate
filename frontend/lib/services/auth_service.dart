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
      'email': email.trim(),
      'password': password,
    });

    final token = response.data?['token'];
    final userJson = response.data?['user'];
    if (token == null || userJson == null) {
      throw const ApiException('Unexpected response from server.');
    }

    await _storage.saveToken(token.toString());
    return AuthResult(UserModel.fromJson(Map<String, dynamic>.from(userJson)));
  }

  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _api.post('/signup', data: {
      'email': email.trim(),
      'password': password,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
    });
    // Deliberately not auto-logging-in here: many APIs require email
    // verification before a token is issued. Signup succeeding means
    // "show the user a confirmation", not "assume they're authenticated".
  }

  /// Called on app startup to restore a session, and after any request
  /// that comes back 401, to confirm whether the stored token is still
  /// valid server-side.
  ///
  /// Returns `null` when there is genuinely no session to restore (no
  /// token stored, or the server confirmed the token is invalid/expired -
  /// both are normal, silent paths back to the login screen). Rethrows
  /// [ApiException] for anything else (offline, timeout, server error) so
  /// the caller can tell the user their session couldn't be *verified*,
  /// which is a materially different situation from being logged out.
  Future<UserModel?> fetchCurrentUser() async {
    String? token;
    try {
      token = await _storage.readToken();
    } catch (_) {
      // Secure storage itself failed to read (corrupted keychain entry,
      // platform-level error, etc). Treat as "no session" rather than
      // crashing the app on startup.
      return null;
    }
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _api.get('/me');
      final userJson = response.data?['user'] ?? response.data;
      if (userJson == null) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(userJson));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storage.clearToken();
        return null;
      }
      // Network/timeout/5xx: the token might still be perfectly valid -
      // we just couldn't confirm it right now. Don't swallow this as a
      // silent logout; let the caller decide how to inform the user.
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }
}
