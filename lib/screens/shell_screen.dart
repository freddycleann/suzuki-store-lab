import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import 'activity_screen.dart';
import 'cart_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _tabs = [
    _TabData(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _TabData(Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    _TabData(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Cart'),
    _TabData(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Activity'),
    _TabData(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final cartCount = context.select<Session, int>((s) => s.cartCount);
    return PopScope(
      canPop: shell.index == ShellController.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) shell.go(ShellController.home);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: shell.index,
          children: const [HomeScreen(), ExploreScreen(), CartScreen(), ActivityScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        _NavItem(
                          data: _tabs[i],
                          selected: i == shell.index,
                          badge: i == ShellController.cart ? cartCount : 0,
                          onTap: () => shell.go(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.data, required this.selected, required this.badge, required this.onTap});

  final _TabData data;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              backgroundColor: AppColors.suzukiRed,
              child: Icon(
                selected ? data.activeIcon : data.icon,
                size: 23,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        data.label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
