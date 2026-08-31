import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'widgets/app_logo.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/connectivity_banner.dart';

// A single main() / MyApp definition. The original project had main() and
// a MyApp/MaterialApp defined in BOTH main.dart and profile_page.dart -
// two competing app roots and two competing entry points can't coexist in
// one build target, so that project would not have compiled as shipped.
void main() {
  // runZonedGuarded + FlutterError.onError together catch essentially every
  // uncaught error in a Flutter app: framework-layer errors (widget build
  // failures) and Dart-layer async errors that would otherwise vanish
  // silently in release mode or crash the isolate. Route both to the
  // logger now, and to a crash reporter later - see AppLogger.error's TODO.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('Flutter framework error', error: details.exception, stackTrace: details.stack);
    };

    // Replaces the red "exception" screen in release builds with something
    // a real user won't be confused/alarmed by. Left as the default debug
    // red screen in debug mode, since that's genuinely useful while developing.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) return ErrorWidget(details.exception);
      return const _FriendlyErrorScreen();
    };

    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    AppLogger.error('Uncaught zone error', error: error, stackTrace: stack);
  });
}

/// Builds the dependency graph for auth: storage -> API client -> auth
/// service -> provider. The API client needs to be able to force a logout
/// (when a refresh token turns out to be invalid) on a provider that
/// doesn't exist until after the client is constructed - `late final`
/// resolves that: the closure isn't actually *called* until well after
/// this function returns and `authProvider` has been assigned.
AuthProvider _buildAuthProvider() {
  final storage = SecureStorageService();
  late final AuthProvider authProvider;
  final apiClient = ApiClient(
    storage: storage,
    onSessionExpired: () => authProvider.forceLogout(),
  );
  final authService = AuthService(apiClient: apiClient, storage: storage);
  authProvider = AuthProvider(authService: authService);
  return authProvider;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _buildAuthProvider()..tryAutoLogin(),
      child: MaterialApp(
        title: 'Flutter Auth Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const RootRouter(),
        // Wraps every screen (including dialogs/snackbars, since this sits
        // around the Navigator) with the offline banner and the app-lock
        // overlay, without breaking the Localization/Theme context those
        // widgets need - wrapping outside MaterialApp instead would.
        builder: (context, child) => ConnectivityBanner(
          child: AppLockGate(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Chooses which screen to show based on auth state, instead of screens
/// manually calling Navigator.pushReplacement on each other. This means
/// logging out from anywhere in the app correctly and immediately returns
/// to the auth screen without every call site needing to know how to
/// navigate there.
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return const ProfileScreen();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}

/// Branded splash shown while `AuthProvider.tryAutoLogin()` checks for a
/// stored session - a bare spinner on a blank white screen is the single
/// most common "unfinished app" tell, so this gets the same background
/// gradient and wordmark as the rest of the app instead.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(light: true, size: 56),
              SizedBox(height: 32),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendlyErrorScreen extends StatelessWidget {
  const _FriendlyErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                "Please restart the app. If this keeps happening, contact support.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
