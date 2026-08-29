/// Centralized environment configuration.
///
/// Never hardcode API hosts (e.g. `http://192.168.100.13:3000`) directly in
/// widgets/services. Instead, pass the real value at build/run time:
///
///   flutter run --dart-define=API_BASE_URL=https://api.yourapp.com
///   flutter build apk --dart-define=API_BASE_URL=https://api.yourapp.com
///
/// This lets you point at a local server during development, a staging
/// server for QA, and your real production host for release builds,
/// without ever touching the source code.
class Environment {
  Environment._();

  /// Falls back to a local emulator loopback for convenience during dev,
  /// but production builds MUST supply --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.13:3000',
  );

  /// Toggle verbose network/debug logging. Keep this off in release builds.
  static const bool enableVerboseLogging = bool.fromEnvironment(
    'VERBOSE_LOGGING',
    defaultValue: false,
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);
}
