import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps token persistence. Auth tokens must never be kept in plain
/// SharedPreferences or in-memory-only state (that forces a re-login on
/// every app restart) - flutter_secure_storage uses Keychain on iOS and
/// EncryptedSharedPreferences/Keystore on Android.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) {
    return _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> readToken() {
    return _storage.read(
      key: _tokenKey,
    );
  }

  Future<void> clearToken() {
    return _storage.delete(
      key: _tokenKey,
    );
  }
}