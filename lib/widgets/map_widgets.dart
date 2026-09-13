import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/dealer.dart';
import '../theme/app_theme.dart';

/// OpenStreetMap standard tiles, recoloured to suit the app's dark theme.
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'suzuki.store',
      tileBuilder: darkModeTileBuilder,
    );

class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.dealer, this.selected = false, this.size = 40, this.onTap});

  final Dealer dealer;
  final bool selected;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showroom = dealer.kind == LocationKind.showroom;
    final diameter = selected ? size * 1.25 : size;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: showroom ? AppColors.primaryGradient : null,
          color: showroom ? null : AppColors.surfaceHigh,
          border: Border.all(
            color: selected
                ? Colors.white
                : (showroom ? Colors.white.withValues(alpha: 0.35) : AppColors.cyan.withValues(alpha: 0.7)),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (showroom ? AppColors.primary : Colors.black).withValues(alpha: 0.45),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(dealer.kind.icon, size: diameter * 0.46, color: showroom ? Colors.white : AppColors.cyan),
      ),
    );
  }
}

class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyan,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4)],
      ),
    );
  }
}

/// Required credit for OpenStreetMap data; links to the copyright page.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
