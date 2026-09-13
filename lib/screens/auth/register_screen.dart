import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'google_auth_action.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    try {
      await auth.register(name: _name.text, email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, 'Registration failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Excluded from focus so the keyboard's "next" action jumps field to field.
    final visibility = ExcludeFocus(
      child: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textMuted,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: Center(child: BackButtonCircle())),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const Text(
              'Create account',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save favorites, reserve bikes and book test rides at any showroom.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            AppTextField(
              controller: _name,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _email,
              hint: 'Email address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _password,
              hint: 'Password (min. 6 characters)',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              suffix: visibility,
              validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirm,
              hint: 'Confirm password',
              icon: Icons.lock_reset_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 26),
            PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
            if (context.read<AuthService>().supportsGoogle) ...[
              const OrDivider(),
              GoogleSignInButton(
                label: 'Sign up with Google',
                onPressed: () => continueWithGoogle(context),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already riding with us? ', style: TextStyle(color: AppColors.textMuted)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(color: AppColors.primaryBright, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
