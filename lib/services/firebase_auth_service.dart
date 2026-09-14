import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void>? _googleReady;

  @override
  bool get isDemo => false;

  @override
  bool get supportsGoogle => true;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_toAppUser);

  @override
  Future<void> signIn({required String email, required String password}) => _guard(
        () => _auth.signInWithEmailAndPassword(email: email.trim(), password: password),
      );

  @override
  Future<void> register({required String name, required String email, required String password}) => _guard(() async {
        final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final user = credential.user!;
        await user.updateDisplayName(name.trim());
        _saveProfile(user, name, email);
        await user.reload();
      });

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGooglePopup();
    final GoogleSignInAccount account;
    try {
      await _initGoogle();
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const GoogleSignInIncomplete();
      throw AuthFailure(_googleMessage(e));
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthFailure('Google did not return a sign-in token. Please try again.');

    await _guard(() async {
      final result = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      final user = result.user;
      if (user != null && (result.additionalUserInfo?.isNewUser ?? false)) {
        _saveProfile(user, account.displayName ?? user.displayName ?? '', account.email);
      }
    });
  }

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    // Also forget the Google session so the next sign-in can pick another account.
    if (!kIsWeb) {
      try {
        await _initGoogle();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out skipped: $e');
      }
    }
    await _auth.signOut();
  }

  @override
  Future<void> signInWithGoogleInBrowser() async {
    if (kIsWeb) return _signInWithGooglePopup();
    try {
      // Firebase's hosted Google sign-in page in a browser tab; independent of
      // the Play services account picker.
      final result = await _auth.signInWithProvider(GoogleAuthProvider());
      final user = result.user;
      if (user != null && (result.additionalUserInfo?.isNewUser ?? false)) {
        _saveProfile(user, user.displayName ?? '', user.email ?? '');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' || e.code == 'canceled') throw const AuthCancelled();
      throw AuthFailure(_message(e));
    }
  }

  /// Browsers use Firebase's Google popup instead of the Android account picker.
  Future<void> _signInWithGooglePopup() async {
    try {
      final result = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = result.user;
      if (user != null && (result.additionalUserInfo?.isNewUser ?? false)) {
        _saveProfile(user, user.displayName ?? '', user.email ?? '');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        throw const AuthCancelled();
      }
      throw AuthFailure(_message(e));
    }
  }

  Future<void> _initGoogle() => _googleReady ??= _initializeGoogle();

  Future<void> _initializeGoogle() async {
    try {
      await GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleWebClientId);
    } catch (_) {
      _googleReady = null;
      rethrow;
    }
  }

  void _saveProfile(User user, String name, String email) {
    // Not awaited: a Firestore write only completes once the server confirms it,
    // so sign-in must not wait on it. The write syncs when the database is reachable.
    unawaited(
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'name': name.trim(),
            'email': email.trim(),
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true))
          .catchError((Object e) => debugPrint('Could not save user profile document: $e')),
    );
  }

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final email = user.email ?? '';
    final displayName = user.displayName?.trim() ?? '';
    return AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName.isNotEmpty ? displayName : (email.contains('@') ? email.split('@').first : 'Rider'),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  /// Firebase rejects Google sign-in from an Android build whose signing
  /// certificate is not listed on the app in Project settings.
  static const _certNotRegistered =
      "Google sign-in is blocked because this app's SHA-1 fingerprint isn't registered in Firebase. "
      "Add C0:70:DD:A4:03:B5:8E:90:0F:86:46:80:71:8E:48:AB:76:46:1D:26 to the Android app suzuki.store.";

  static const _authNotSetUp =
      'Firebase Authentication is not set up yet. Open Authentication in the Firebase console and click Get started.';

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'account-exists-with-different-credential' =>
          'This email is already registered with a password. Sign in with your password instead.',
        'weak-password' => 'Password should be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'No internet connection.',
        'popup-blocked' => 'Allow pop-ups for this site to sign in with Google.',
        'unauthorized-domain' => 'This web address is not an authorized domain in Firebase Authentication settings.',
        'operation-not-allowed' => 'This sign-in method is not enabled in the Firebase console.',
        'invalid-cert-hash' => _certNotRegistered,
        _ when '${e.message}'.contains('INVALID_CERT_HASH') => _certNotRegistered,
        'configuration-not-found' => _authNotSetUp,
        'internal-error' when (e.message ?? '').contains('CONFIGURATION_NOT_FOUND') => _authNotSetUp,
        _ => e.message ?? 'Authentication failed (${e.code}).',
      };

  static String _googleMessage(GoogleSignInException e) => switch (e.code) {
        GoogleSignInExceptionCode.clientConfigurationError =>
          "Google sign-in isn't configured for this app yet. Add the app's SHA-1 fingerprint in Firebase, then try again.",
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google sign-in needs Google Play services on this device.',
        GoogleSignInExceptionCode.uiUnavailable => 'Could not open the Google account picker.',
        GoogleSignInExceptionCode.interrupted => 'Google sign-in was interrupted. Please try again.',
        _ => e.description ?? 'Google sign-in failed.',
      };
}
