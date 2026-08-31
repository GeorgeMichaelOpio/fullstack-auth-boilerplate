import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

/// Screen-level state only. This deliberately does NOT have an
/// "authenticating" value - see [AuthProvider.isSubmitting] for why.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Single source of truth for "is anyone logged in, and who".
///
/// IMPORTANT: [status] drives which *entire screen* `RootRouter` shows
/// (splash vs. auth vs. profile). It must only change when the screen
/// itself should actually change - see [isSubmitting] for the flag forms
/// actually use for their own busy state, and [refreshCurrentUser] for why
/// a background refresh never touches [status] either.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;

  bool isSubmitting = false;
  String? errorMessage;
  String? sessionMessage;

  // --- Client-side login lockout -------------------------------------
  // This is a UX/friction measure, not a security control - real rate
  // limiting has to live on the server, since a client can always be
  // bypassed. Its job here is just to (a) stop obviously-automated rapid
  // retries from a well-behaved client, and (b) surface a 429 from the
  // server with an actual countdown instead of a generic error.
  int _consecutiveFailures = 0;
  DateTime? _lockedUntil;

  Duration? get lockoutRemaining {
    if (_lockedUntil == null) return null;
    final remaining = _lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<void> tryAutoLogin() async {
    status = AuthStatus.unknown;
    notifyListeners();

    try {
      final user = await _authService.fetchCurrentUser();
      if (user != null) {
        currentUser = user;
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
      }
    } on ApiException catch (e) {
      AppLogger.warning('Session restore failed: ${e.message}');
      sessionMessage = "Couldn't restore your session: ${e.message}";
      status = AuthStatus.unauthenticated;
    } catch (e, st) {
      AppLogger.error('Unexpected error restoring session', error: e, stackTrace: st);
      sessionMessage = 'Something went wrong loading your account. Please log in again.';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Called by ApiClient when a refresh token turns out to be invalid too -
  /// i.e. the session is genuinely over, not just momentarily unreachable.
  void forceLogout({String? reason}) {
    currentUser = null;
    status = AuthStatus.unauthenticated;
    sessionMessage = reason ?? 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  /// Show a session-restore/force-logout message exactly once.
  String? consumeSessionMessage() {
    final message = sessionMessage;
    sessionMessage = null;
    return message;
  }

  Future<bool> login(String email, String password) async {
    final remaining = lockoutRemaining;
    if (remaining != null) {
      errorMessage = 'Too many attempts. Try again in ${remaining.inSeconds}s.';
      notifyListeners();
      return false;
    }

    errorMessage = null;
    isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);
      currentUser = result.user;
      status = AuthStatus.authenticated;
      _consecutiveFailures = 0;
      _lockedUntil = null;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      _registerFailure(serverRetryAfter: e.statusCode == 429 ? e.retryAfterSeconds : null);
      return false;
    } catch (e, st) {
      AppLogger.error('Unexpected login error', error: e, stackTrace: st);
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _registerFailure({int? serverRetryAfter}) {
    _consecutiveFailures++;
    if (serverRetryAfter != null) {
      _lockedUntil = DateTime.now().add(Duration(seconds: serverRetryAfter));
      return;
    }
    // Client-side backoff after repeated failures: 5th failure -> 15s,
    // growing from there. Purely a speed bump - see note above.
    if (_consecutiveFailures >= 5) {
      final backoffSeconds = 15 * (_consecutiveFailures - 4);
      _lockedUntil = DateTime.now().add(Duration(seconds: backoffSeconds.clamp(15, 300)));
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    errorMessage = null;
    isSubmitting = true;
    notifyListeners();

    try {
      await _authService.signup(email: email, password: password, firstName: firstName, lastName: lastName);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e, st) {
      AppLogger.error('Unexpected signup error', error: e, stackTrace: st);
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    errorMessage = null;
    isSubmitting = true;
    notifyListeners();
    try {
      await _authService.requestPasswordReset(email);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e, st) {
      AppLogger.error('Unexpected password reset error', error: e, stackTrace: st);
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Silently re-fetches the current user (e.g. for pull-to-refresh on the
  /// profile screen) without touching [status]. Deliberately does NOT use
  /// [tryAutoLogin] here - that resets status to `unknown`, which would
  /// make RootRouter tear down the profile screen mid-refresh, the same
  /// class of bug that was breaking the login/signup forms. A failed
  /// background refresh should leave the user on their last-known profile,
  /// not bounce them anywhere.
  Future<void> refreshCurrentUser() async {
    try {
      final user = await _authService.fetchCurrentUser();
      if (user != null) {
        currentUser = user;
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.error('Profile refresh failed', error: e, stackTrace: st);
      // Intentionally not surfaced as an error - a pull-to-refresh that
      // can't reach the server just leaves the existing data in place.
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
