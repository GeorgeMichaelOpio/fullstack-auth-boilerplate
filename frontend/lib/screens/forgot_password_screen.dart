import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    // Always show the same "check your email" outcome regardless of
    // success/failure of the underlying request, EXCEPT for a network-
    // level failure (no connection at all) - that's a real, actionable
    // problem worth telling the user about distinctly. Whether the email
    // is registered is never revealed either way (see AuthService).
    final ok = await auth.requestPasswordReset(_emailController.text);
    if (!mounted) return;

    if (ok) {
      setState(() => _submitted = true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isSubmitting);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _submitted ? _buildConfirmation(textTheme) : _buildForm(textTheme, isBusy),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme textTheme, bool isBusy) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Forgot your password?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            "Enter the email on your account and we'll send you a link to reset it.",
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !isBusy,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
            validator: Validators.email,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isBusy ? null : _submit,
            child: isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Send reset link'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: 24),
        Text('Check your email', style: textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "If an account exists for ${_emailController.text.trim()}, we've sent a link to reset your password.",
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to login')),
      ],
    );
  }
}
