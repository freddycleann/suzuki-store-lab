import 'dart:async';

import 'auth_service.dart';

/// In-memory auth used until Firebase keys are added to firebase_options.dart.
class DemoAuthService implements AuthService {
  DemoAuthService() {
    _accounts[demoEmail] = const _DemoAccount(
      demoPassword,
      AppUser(uid: 'demo-rider', email: demoEmail, displayName: 'Demo Rider'),
    );
  }

  static const demoEmail = 'demo@suzuki.co.th';
  static const demoPassword = 'demo1234';

  final _accounts = <String, _DemoAccount>{};
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  bool get isDemo => true;

  @override
  bool get supportsGoogle => false;

  @override
  Future<void> signInWithGoogle() async =>
      throw const AuthFailure('Google sign-in is available once Firebase is connected.');

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _latency();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthFailure('Incorrect email or password.');
    }
    _set(account.user);
  }

  @override
  Future<void> register({required String name, required String email, required String password}) async {
    await _latency();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw const AuthFailure('An account already exists for that email.');
    if (password.length < 6) throw const AuthFailure('Password should be at least 6 characters.');
    final user = AppUser(uid: 'demo-${DateTime.now().microsecondsSinceEpoch}', email: key, displayName: name.trim());
    _accounts[key] = _DemoAccount(password, user);
    _set(user);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _latency();
    if (!_accounts.containsKey(email.trim().toLowerCase())) {
      throw const AuthFailure('No account found for that email.');
    }
  }

  @override
  Future<void> signOut() async => _set(null);

  void _set(AppUser? user) {
    _current = user;
    _changes.add(user);
  }

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 600));
}

class _DemoAccount {
  const _DemoAccount(this.password, this.user);

  final String password;
  final AppUser user;
}
