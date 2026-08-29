import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

// A single main() / MyApp definition. The original project had main() and
// a MyApp/MaterialApp defined in BOTH main.dart and profile_page.dart -
// two competing app roots and two competing entry points can't coexist in
// one build target, so that project would not have compiled as shipped.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: MaterialApp(
        title: 'Nimbus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RootRouter(),
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
