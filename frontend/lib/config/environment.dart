/// Centralized environment configuration.
///
/// Never hardcode API hosts directly in widgets/services. Pass the real
/// value at build/run time instead:
///
///   flutter run --dart-define=API_BASE_URL=https://api.yourapp.com
///   flutter build apk --dart-define=API_BASE_URL=https://api.yourapp.com \
///     --dart-define=PINNED_CERT_SHA256=AAAA...,BBBB... \
///     --obfuscate --split-debug-info=build/symbols
///
/// (--obfuscate + --split-debug-info on release builds is a real production
/// step, not busywork: it makes reversing your compiled Dart considerably
/// harder. Keep the generated symbol files private - you need them to
/// decode crash stack traces later.)
class Environment {
  Environment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const bool enableVerboseLogging = bool.fromEnvironment(
    'VERBOSE_LOGGING',
    defaultValue: false,
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);

  /// Comma-separated SHA-256 fingerprints (hex, no colons) of the server's
  /// leaf/intermediate certificate(s), e.g. from:
  ///   openssl x509 -in cert.pem -noout -fingerprint -sha256
  /// Pass via --dart-define=PINNED_CERT_SHA256=fingerprint1,fingerprint2
  /// (include the next cert too when you rotate, so old builds in the
  /// field don't hard-fail the moment you renew). Left empty, certificate
  /// pinning is a no-op - see ApiClient for exactly what this hook does
  /// and does not protect against.
  static const String _pinnedCertsRaw = String.fromEnvironment('PINNED_CERT_SHA256', defaultValue: '');

  static List<String> get pinnedCertSha256Fingerprints => _pinnedCertsRaw
      .split(',')
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Require Face ID/Touch ID/fingerprint/device PIN to re-enter the app
  /// after it's been backgrounded this long. Set to Duration.zero via
  /// --dart-define=APP_LOCK_SECONDS=0 to disable entirely.
  static const int _appLockSeconds = int.fromEnvironment('APP_LOCK_SECONDS', defaultValue: 60);
  static Duration get appLockThreshold => Duration(seconds: _appLockSeconds);
  static bool get appLockEnabled => _appLockSeconds > 0;
}
