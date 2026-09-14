import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? AppColors.red : AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null && !loading ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: loading ? null : onPressed,
            child: SizedBox(
              height: height,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon, this.height = 58});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.stroke),
    );
    final color = onPressed == null ? AppColors.textMuted : AppColors.text;
    return Material(
      color: AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, color: color, size: 20), const SizedBox(width: 10)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = 0,
    this.size = 48,
    this.background,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: background ?? AppColors.surface,
          shape: const CircleBorder(side: BorderSide(color: AppColors.stroke)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.44, color: iconColor ?? AppColors.text),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 21),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.suzukiRed,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bg, width: 2),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({super.key, this.background});

  final Color? background;

  @override
  Widget build(BuildContext context) => CircleIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        size: 44,
        background: background,
        onTap: () => Navigator.of(context).maybePop(),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.color = AppColors.primaryBright, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
          Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color),
          ),
        ],
      ),
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: Colors.black.withValues(alpha: 0.28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 6)],
              Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 30, 20, 14),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(color: AppColors.primaryBright, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primaryBright, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: AppColors.textMuted, size: 21),
        suffixIcon: suffix,
      ),
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: i == index ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.stroke),
              ),
              child: Icon(icon, size: 42, color: AppColors.primaryBright),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              SizedBox(width: 220, child: PrimaryButton(label: actionLabel!, onPressed: onAction, height: 52)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.initials, this.size = 48});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36),
      ),
    );
  }
}

class SuzukiWordmark extends StatelessWidget {
  const SuzukiWordmark({super.key, this.size = 1});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34 * size,
          height: 34 * size,
          decoration: BoxDecoration(color: AppColors.suzukiRed, borderRadius: BorderRadius.circular(10 * size)),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 21 * size,
            ),
          ),
        ),
        SizedBox(width: 10 * size),
        Text(
          'SUZUKI',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4 * size, fontSize: 16 * size),
        ),
      ],
    );
  }
}

class BackendPill extends StatelessWidget {
  const BackendPill({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = context.read<AuthService>().isDemo;
    return StatusPill(
      demo ? 'DEMO MODE' : 'FIREBASE LIVE',
      color: demo ? AppColors.warning : AppColors.success,
      icon: demo ? Icons.science_outlined : Icons.cloud_done_rounded,
    );
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.label = 'Continue with Google'});

  final Future<void> Function() onPressed;
  final String label;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _tap() async {
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    return Material(
      color: Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: _loading ? null : _tap,
        child: SizedBox(
          height: 58,
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleLogoPainter())),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The four-colour Google "G".
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    double rad(double degrees) => degrees * math.pi / 180;
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect, rad(-160), rad(115), false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, rad(135), rad(65), false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, rad(45), rad(90), false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, rad(-2), rad(47), false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTRB(size.width / 2, size.height / 2 - stroke / 2, size.width - stroke / 4, size.height / 2 + stroke / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email';
  return null;
}

String? validatePhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 9 || digits.length > 10) return 'Enter a valid Thai mobile number';
  return null;
}
