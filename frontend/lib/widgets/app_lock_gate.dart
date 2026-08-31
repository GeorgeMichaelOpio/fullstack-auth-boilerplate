import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../config/environment.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import 'app_logo.dart';

/// Requires Face ID / fingerprint / device PIN before the app content is
/// shown again, once it's been backgrounded for longer than
/// [Environment.appLockThreshold]. This matters because a stolen-token
/// scenario isn't the only risk on mobile - a phone left unlocked and
/// physically accessible is often the easier attack, and most banking/
/// health/finance apps treat this as table stakes.
///
/// Disabled entirely when `Environment.appLockEnabled` is false (see
/// environment.dart to configure via --dart-define=APP_LOCK_SECONDS=0).
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _backgroundedAt;
  bool _locked = false;
  bool _checkingSupport = true;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    if (!Environment.appLockEnabled) {
      setState(() => _checkingSupport = false);
      return;
    }
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      setState(() {
        _biometricsAvailable = supported || canCheck;
        _checkingSupport = false;
      });
    } catch (e) {
      AppLogger.warning('Biometric availability check failed: $e');
      setState(() => _checkingSupport = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Environment.appLockEnabled || !_biometricsAvailable) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      if (backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= Environment.appLockThreshold) {
        setState(() => _locked = true);
      }
    }
  }

  Future<void> _authenticate() async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock to continue',
        biometricOnly: false,
        persistAcrossBackgrounding: true, // Replaces stickyAuth in newer versions
      );
      if (success && mounted) {
        setState(() => _locked = false);
      }
    } catch (e) {
      AppLogger.warning('Authentication attempt failed: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_checkingSupport) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(light: true, size: 56),
                    const SizedBox(height: 40),
                    const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'App locked for your security',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
