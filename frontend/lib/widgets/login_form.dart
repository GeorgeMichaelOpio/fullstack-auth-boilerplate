import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/forgot_password_screen.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = false;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    // Ticks the lockout countdown text below the button. Cheap no-op when
    // there's no active lockout - just triggers a rebuild each second so
    // the countdown (and its own disappearance once expired) stays live.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isSubmitting);
    final lockoutRemaining = context.select<AuthProvider, Duration?>((a) => a.lockoutRemaining);
    final isLocked = lockoutRemaining != null;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Welcome back', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Sign in to continue', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !isBusy && !isLocked,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            enabled: !isBusy && !isLocked,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: Validators.loginPassword,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                onTap: isBusy ? null : () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: isBusy ? null : (v) => setState(() => _rememberMe = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember me', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: isBusy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          if (isLocked) ...[
            const SizedBox(height: 8),
            Text(
              'Too many attempts. Try again in ${lockoutRemaining!.inSeconds}s.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (isBusy || isLocked) ? null : _submit,
            child: isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Sign In'),
          ),
          const SizedBox(height: 20),
          _orDivider(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SocialButton(icon: Icons.g_mobiledata_rounded, onTap: null),
              SizedBox(width: 16),
              _SocialButton(icon: Icons.apple_rounded, onTap: null),
              SizedBox(width: 16),
              _SocialButton(icon: Icons.facebook_rounded, onTap: null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Social sign-in buttons are visibly present but intentionally disabled
/// (onTap: null) until real OAuth is wired up - see auth_screen.dart notes.
/// A tappable button that silently does nothing is worse than a disabled one.
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IconButton(icon: Icon(icon, size: 26), onPressed: onTap),
      ),
    );
  }
}
