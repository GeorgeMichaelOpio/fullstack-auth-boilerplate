import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access and refresh tokens separately - see AuthService/
/// ApiClient for the refresh flow that uses them.
///
/// Storage backends:
/// - Android: EncryptedSharedPreferences (AES-256), backed by the Android
///   Keystore.
/// - iOS: Keychain, with `first_unlock` accessibility - the values are
///   inaccessible until the device has been unlocked at least once since
///   boot, and are excluded from iCloud/iTunes backups, so a restored
///   backup on a new device never carries a live session token with it.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveAccessToken(String token) => _storage.write(key: _accessTokenKey, value: token);
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) => _storage.write(key: _refreshTokenKey, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
