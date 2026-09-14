class AppUser {
  const AppUser({required this.uid, required this.email, required this.displayName});

  final String uid;
  final String email;
  final String displayName;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the user dismisses a sign-in flow; not an error worth showing.
class AuthCancelled implements Exception {
  const AuthCancelled();
}

/// The Android Google account picker closed without a token. Play services
/// reports both a user cancel and an app signature that is not registered in
/// Firebase ("[16] Account reauth failed") this way, so offer the browser flow.
class GoogleSignInIncomplete implements Exception {
  const GoogleSignInIncomplete();
}

abstract class AuthService {
  bool get isDemo;

  bool get supportsGoogle;

  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String name, required String email, required String password});

  /// Native Google sign-in. Throws [GoogleSignInIncomplete] on Android when the
  /// account picker closes without a token.
  Future<void> signInWithGoogle();

  /// Google sign-in through Firebase's hosted web flow (browser tab or popup).
  /// Throws [AuthCancelled] if the user closes it.
  Future<void> signInWithGoogleInBrowser();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
