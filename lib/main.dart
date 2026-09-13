import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'services/auth_service.dart';
import 'services/demo_auth_service.dart';
import 'services/demo_store_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_store_service.dart';
import 'services/store_service.dart';
import 'state/app_prefs.dart';
import 'state/catalog_provider.dart';
import 'state/locations_provider.dart';
import 'state/session.dart';
import 'state/shell_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final useFirebase = DefaultFirebaseOptions.isConfigured;
  if (useFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  final prefs = AppPrefs(await SharedPreferences.getInstance());

  runApp(
    SuzukiMotoApp(
      auth: useFirebase ? FirebaseAuthService() : DemoAuthService(),
      store: useFirebase ? FirestoreStoreService() : DemoStoreService(),
      prefs: prefs,
    ),
  );
}

class SuzukiMotoApp extends StatelessWidget {
  const SuzukiMotoApp({super.key, required this.auth, required this.store, required this.prefs});

  final AuthService auth;
  final StoreService store;
  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppPrefs>.value(value: prefs),
        Provider<AuthService>.value(value: auth),
        Provider<StoreService>.value(value: store),
        ChangeNotifierProvider(create: (_) => Session(auth: auth, store: store)),
        ChangeNotifierProvider(create: (_) => CatalogProvider()..loadLineup()),
        ChangeNotifierProvider(create: (_) => LocationsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: MaterialApp(
        title: 'Suzuki Moto',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, uid) = context.select<Session, (bool, String?)>((s) => (s.ready, s.user?.uid));
    final onboardingCompleted = context.select<AppPrefs, bool>((p) => p.onboardingCompleted);
    final Widget child;
    if (!ready) {
      child = const _Splash();
    } else if (uid == null && !onboardingCompleted) {
      child = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinished: context.read<AppPrefs>().completeOnboarding,
      );
    } else if (uid == null) {
      child = const WelcomeScreen(key: ValueKey('welcome'));
    } else {
      child = const ShellScreen(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: child);
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuzukiWordmark(size: 1.4),
            SizedBox(height: 28),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
