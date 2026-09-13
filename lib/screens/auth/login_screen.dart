import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/demo_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'google_auth_action.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    try {
      await auth.signIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, 'Sign-in failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final auth = context.read<AuthService>();
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We'll email you a link to set a new password.",
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    if (validateEmail(email) != null) {
      showAppSnack(context, 'Enter a valid email address', error: true);
      return;
    }
    try {
      await auth.sendPasswordReset(email);
      if (mounted) showAppSnack(context, 'Reset link sent to $email');
    } on AuthFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = context.read<AuthService>().isDemo;
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
              'Welcome back',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your garage, orders and test rides.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (isDemo) ...[
              DemoHint(
                onUse: () {
                  _email.text = DemoAuthService.demoEmail;
                  _password.text = DemoAuthService.demoPassword;
                },
              ),
              const SizedBox(height: 18),
            ],
            AppTextField(
              controller: _email,
              hint: 'Email address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _password,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              autofillHints: const [AutofillHints.password],
              suffix: ExcludeFocus(
                child: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
            if (!isDemo) ...[
              const OrDivider(),
              GoogleSignInButton(onPressed: () => continueWithGoogle(context)),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New to Suzuki Moto? ', style: TextStyle(color: AppColors.textMuted)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    'Create account',
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

class DemoHint extends StatelessWidget {
  const DemoHint({super.key, required this.onUse});

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: AppColors.warning),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo mode', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning)),
                SizedBox(height: 2),
                Text(
                  'Firebase keys not added yet. Use ${DemoAuthService.demoEmail} / '
                  '${DemoAuthService.demoPassword} or create any account.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onUse, child: const Text('Fill')),
        ],
      ),
    );
  }
}
