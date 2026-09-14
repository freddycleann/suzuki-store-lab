import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Runs Google sign-in from any auth screen and returns to the app root on success.
Future<void> continueWithGoogle(BuildContext context) async {
  final auth = context.read<AuthService>();
  final navigator = Navigator.of(context);
  try {
    await auth.signInWithGoogle();
    navigator.popUntil((route) => route.isFirst);
  } on GoogleSignInIncomplete {
    if (!context.mounted) return;
    showAppSnack(
      context,
      "Google sign-in didn't finish. You can sign in with Google in the browser instead.",
      error: true,
      duration: const Duration(seconds: 8),
      actionLabel: 'USE BROWSER',
      onAction: () => _signInInBrowser(context, auth, navigator),
    );
  } on AuthCancelled {
    return;
  } on AuthFailure catch (e) {
    if (context.mounted) showAppSnack(context, e.message, error: true);
  } catch (e) {
    if (context.mounted) showAppSnack(context, 'Google sign-in failed: $e', error: true);
  }
}

Future<void> _signInInBrowser(BuildContext context, AuthService auth, NavigatorState navigator) async {
  try {
    await auth.signInWithGoogleInBrowser();
    navigator.popUntil((route) => route.isFirst);
  } on AuthCancelled {
    return;
  } on AuthFailure catch (e) {
    if (context.mounted) showAppSnack(context, e.message, error: true);
  } catch (e) {
    if (context.mounted) showAppSnack(context, 'Google sign-in failed: $e', error: true);
  }
}
