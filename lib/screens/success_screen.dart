import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.reference,
    required this.primaryLabel,
    required this.primaryTab,
  });

  final String title;
  final String message;
  final String? reference;
  final String primaryLabel;
  final int primaryTab;

  void _finish(BuildContext context, int tab) {
    context.read<ShellController>().go(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish(context, ShellController.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 50, spreadRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 68, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.6),
                ),
                if (reference != null) ...[
                  const SizedBox(height: 18),
                  StatusPill('REF #$reference', color: AppColors.cyan, icon: Icons.confirmation_number_outlined),
                ],
                const Spacer(),
                PrimaryButton(label: primaryLabel, onPressed: () => _finish(context, primaryTab)),
                const SizedBox(height: 12),
                SecondaryButton(label: 'Back to home', onPressed: () => _finish(context, ShellController.home)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
