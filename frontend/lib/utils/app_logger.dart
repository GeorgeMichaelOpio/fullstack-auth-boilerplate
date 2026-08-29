import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Thin logging wrapper.
///
/// `print()` statements ship straight to release console output, can leak
/// sensitive data (tokens, emails) into device logs, and give you no way to
/// filter by severity or wire up crash reporting later. Route everything
/// through here instead, and swap the body for Sentry/Crashlytics/etc. when
/// you add one, without touching call sites.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'DEBUG');
    }
  }

  static void info(String message) {
    developer.log(message, name: 'INFO');
  }

  static void warning(String message) {
    developer.log(message, name: 'WARNING');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    // TODO: forward to a crash-reporting service (Sentry, Crashlytics, etc.)
  }
}
