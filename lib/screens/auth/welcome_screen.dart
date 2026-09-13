import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dealers.dart';
import '../../data/thai_catalog.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bike_image.dart';
import '../../widgets/common.dart';
import 'google_auth_action.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: BikeImage(bike: ThaiCatalog.heroBike, iconSize: 120),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000), Color(0xCC0A0B10), AppColors.bg],
                stops: [0, 0.22, 0.5, 0.64],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [SuzukiWordmark(), Spacer(), BackendPill()]),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassPill(text: '${ThaiCatalog.bikes.length} models', icon: Icons.two_wheeler_rounded),
                      GlassPill(text: '${Dealers.all.length} showrooms', icon: Icons.storefront_rounded),
                      const GlassPill(text: 'Finance from 10% down', icon: Icons.percent_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ride the\nWay of Life.',
                    style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, height: 1.02, letterSpacing: -1.4),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Discover, finance and book test rides for genuine Suzuki motorcycles across Thailand.',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Create account',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'I already have an account',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                  if (context.read<AuthService>().supportsGoogle) ...[
                    const SizedBox(height: 12),
                    GoogleSignInButton(onPressed: () => continueWithGoogle(context)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
