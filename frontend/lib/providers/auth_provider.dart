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
/// itself should actually change. A login/signup attempt should NOT flip
/// [status] mid-flight - doing that previously caused RootRouter to tear
/// down and rebuild the whole AuthScreen on every submit, which:
///   1. destroyed the form's TextEditingControllers (typed input vanished), and
///   2. unmounted the widget before it could show the error SnackBar, so
///      failures were silently swallowed and it just "went back to login".
///
/// [isSubmitting] is the separate, narrow flag forms use to show a spinner
/// and disable inputs - it never causes a screen change.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;

  /// True only while a login/signup request is in flight. Forms watch this
  /// (not [status]) to show their spinner, so submitting never triggers a
  /// screen swap.
  bool isSubmitting = false;

  /// Set when a login or signup attempt fails. Forms read this right after
  /// their own await completes and show it in a SnackBar.
  String? errorMessage;

  /// Set only when restoring a session on cold start fails for a reason
  /// other than "there simply was no session" (e.g. no internet, server
  /// unreachable, unexpected error) - see [tryAutoLogin]. The auth screen
  /// shows this once via [consumeSessionMessage] so the user understands
  /// why they landed back on the login screen instead of assuming the app
  /// is just broken or that they were silently logged out for no reason.
  String? sessionMessage;

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
      // A stored token existed but we couldn't confirm it (offline, server
      // down, timeout, unexpected server error) - this is different from
      // "no token" or "token expired", and the user deserves to know their
      // session wasn't necessarily invalidated, just unverifiable right now.
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

  /// Call once when the auth screen is ready to show a session-restore
  /// message, so it displays exactly once rather than every rebuild.
  String? consumeSessionMessage() {
    final message = sessionMessage;
    sessionMessage = null;
    return message;
  }

  Future<bool> login(String email, String password) async {
    errorMessage = null;
    isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);
      currentUser = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e, st) {
      // Catch-all so a bug or unexpected response shape never leaves the
      // user staring at a stuck spinner with no explanation.
      AppLogger.error('Unexpected login error', error: e, stackTrace: st);
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
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
      await _authService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
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
