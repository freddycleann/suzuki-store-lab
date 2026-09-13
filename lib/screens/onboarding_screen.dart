import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/thai_catalog.dart';
import '../models/motorcycle.dart';
import '../theme/app_theme.dart';
import '../utils/finance.dart';
import '../utils/format.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide({
    required this.bike,
    required this.eyebrow,
    required this.title,
    required this.highlight,
    required this.body,
    required this.chips,
    required this.accent,
  });

  final Motorcycle bike;
  final String eyebrow;
  final String title;
  final String highlight;
  final String body;
  final List<(IconData, String)> chips;
  final Color accent;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  late final List<_Slide> _slides;
  double _page = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    Motorcycle bike(String id) => ThaiCatalog.bikes.firstWhere((b) => b.id == id);
    final sport = bike('gsx-8r');
    final adventure = bike('v-strom-800de');
    final flagship = bike('hayabusa');
    _slides = [
      _Slide(
        bike: sport,
        eyebrow: 'DISCOVER',
        title: 'Every Suzuki,\n',
        highlight: 'one tap away.',
        body: 'Browse ${ThaiCatalog.bikes.length} Thai-market models with Bangkok prices, key specs and real photos.',
        chips: [
          (Icons.sell_rounded, '${sport.name} · ${formatThb(sport.priceThb!)}'),
          (Icons.verified_rounded, 'Live 2026 lineup'),
        ],
        accent: AppColors.primaryBright,
      ),
      _Slide(
        bike: adventure,
        eyebrow: 'TEST RIDE',
        title: 'Feel it before\n',
        highlight: 'you buy it.',
        body: 'Book a free 30-minute ride and find showrooms and service centers near you on the map.',
        chips: const [
          (Icons.sports_motorsports_rounded, 'Free 30-min ride'),
          (Icons.map_rounded, 'Showroom map'),
        ],
        accent: AppColors.cyan,
      ),
      _Slide(
        bike: flagship,
        eyebrow: 'RIDE HOME',
        title: 'Own it with\n',
        highlight: 'easy finance.',
        body: 'Check out in minutes with Suzuki Finance — from 10% down over 12 to 60 months.',
        chips: [
          (
            Icons.account_balance_rounded,
            'From ${formatThb(Finance.monthly(price: flagship.priceThb!, downPercent: 0.10, months: 60))}/mo',
          ),
          (Icons.percent_rounded, '10% down'),
        ],
        accent: AppColors.warning,
      ),
    ];
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Warm the image cache so later slides don't pop in mid-swipe.
    for (final slide in _slides) {
      final url = slide.bike.imageUrl;
      if (url == null) continue;
      precacheImage(
        CachedNetworkImageProvider(url, headers: AppConfig.identityHeaders),
        context,
        onError: (error, stackTrace) {},
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _index => _page.round().clamp(0, _slides.length - 1);

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            itemBuilder: (context, i) => _SlidePage(
              slide: _slides[i],
              offset: (_page - i).clamp(-1.0, 1.0),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 10, 0),
              child: Row(
                children: [
                  const SuzukiWordmark(size: 0.85),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : widget.onFinished,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  children: [
                    _PageIndicator(page: _page, count: _slides.length),
                    const Spacer(),
                    _NextButton(
                      progress: (_page + 1) / _slides.length,
                      isLast: _isLast,
                      onTap: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide, required this.offset});

  final _Slide slide;

  /// -1..1: how far this page is from the centre of the viewport.
  final double offset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = size.height * 0.64;
    final fade = (1 - offset.abs() * 1.4).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: ClipRect(
            // The photo drifts slower than the page for a parallax effect.
            child: Transform.translate(
              offset: Offset(offset * size.width * 0.45, 0),
              child: Transform.scale(
                scale: 1.1 + offset.abs() * 0.12,
                child: BikeImage(bike: slide.bike, iconSize: 120),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xA6000000), Color(0x00000000), Color(0xE60A0B10), AppColors.bg],
                stops: [0, 0.24, 0.5, 0.63],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 130 + MediaQuery.paddingOf(context).bottom,
          child: Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(offset * size.width * 0.2, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final (icon, label) in slide.chips) GlassPill(text: label, icon: icon)],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    slide.eyebrow,
                    style: TextStyle(
                      color: slide.accent,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: slide.title),
                        TextSpan(text: slide.highlight, style: TextStyle(color: slide.accent)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1.06, letterSpacing: -1.2),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.body,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 15.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.page, required this.count});

  final double page;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Builder(
            builder: (context) {
              final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8 + 26 * t,
                height: 8,
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.stroke, AppColors.primary, t),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.progress, required this.isLast, required this.onTap});

  final double progress;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 350);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: isLast ? 184 : 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: duration,
              opacity: isLast ? 0 : 1,
              child: SizedBox(
                width: 76,
                height: 76,
                child: CustomPaint(painter: _ProgressRingPainter(progress)),
              ),
            ),
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: isLast ? 184 : 58,
              height: isLast ? 64 : 58,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(isLast ? 22 : 29),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isLast
                      ? const Row(
                          key: ValueKey('start'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get started',
                              maxLines: 1,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        )
                      : const Icon(Icons.arrow_forward_rounded, key: ValueKey('next'), color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.stroke;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyan;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) => oldDelegate.progress != progress;
}
