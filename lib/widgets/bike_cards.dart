import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/motorcycle.dart';
import '../state/session.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'bike_image.dart';
import 'common.dart';

String priceLabel(Motorcycle bike) {
  final price = bike.priceThb;
  if (price != null) return formatThb(price);
  return bike.inThailand ? 'Ask showroom' : 'Global model';
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.bikeId, this.size = 44});

  final String bikeId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final favorite = context.select<Session, bool>((s) => s.favorites.contains(bikeId));
    return GestureDetector(
      onTap: () => context.read<Session>().toggleFavorite(bikeId),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            color: Colors.black.withValues(alpha: 0.3),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(favorite),
                color: favorite ? AppColors.red : Colors.white,
                size: size * 0.46,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedBikeCard extends StatelessWidget {
  const FeaturedBikeCard({super.key, required this.bike, required this.heroTag, required this.onTap});

  final Motorcycle bike;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: heroTag, child: BikeImage(bike: bike, iconSize: 90)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55000000), Color(0x00000000), Color(0xF2000000)],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Positioned(top: 18, left: 18, child: GlassPill(text: bike.category.label, icon: bike.category.icon)),
            Positioned(top: 14, right: 14, child: FavoriteButton(bikeId: bike.id)),
            Positioned(
              left: 22,
              right: 18,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bike.engineCc != null ? 'SUZUKI · ${bike.engineCc} CC' : 'SUZUKI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bike.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          priceLabel(bike),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.cyan),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.north_east_rounded, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BikeGridCard extends StatelessWidget {
  const BikeGridCard({super.key, required this.bike, required this.heroTag, required this.onTap});

  final Motorcycle bike;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: heroTag, child: BikeImage(bike: bike, iconSize: 44)),
                      Positioned(top: 8, right: 8, child: FavoriteButton(bikeId: bike.id, size: 34)),
                      if (bike.nhtsaListed && bike.inThailand)
                        const Positioned(
                          left: 8,
                          top: 8,
                          child: GlassPill(text: 'NHTSA', icon: Icons.verified_rounded),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bike.category.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bike.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel(bike),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: bike.priceThb != null ? AppColors.cyan : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                          child: Icon(
                            bike.purchasable ? Icons.add_rounded : Icons.north_east_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories = thaiCategories,
  });

  static const thaiCategories = [
    BikeCategory.sport,
    BikeCategory.naked,
    BikeCategory.adventure,
    BikeCategory.scooter,
    BikeCategory.family,
  ];

  final BikeCategory? selected;
  final ValueChanged<BikeCategory?> onSelected;
  final List<BikeCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(label: 'All', icon: Icons.apps_rounded, selected: selected == null, onTap: () => onSelected(null)),
          for (final category in categories)
            _Chip(
              label: category.label,
              icon: category.icon,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primary : AppColors.stroke),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: selected ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
