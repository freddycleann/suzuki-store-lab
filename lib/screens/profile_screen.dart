import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'data_sources_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';
import 'test_ride_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final session = context.read<Session>();
    final shell = context.read<ShellController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Your cart, favorites and bookings stay saved to your account.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    shell.reset();
    await session.signOut();
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2350D8), Color(0xFF0C1440)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AvatarCircle(initials: user?.initials ?? 'R', size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Rider',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          const BackendPill(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _Stat(value: session.orders.length, label: 'Orders'),
                      const _StatDivider(),
                      _Stat(value: session.upcomingRideCount, label: 'Upcoming rides'),
                      const _StatDivider(),
                      _Stat(value: session.favorites.length, label: 'Favorites'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _MenuGroup(
            children: [
              _MenuTile(
                icon: Icons.favorite_border_rounded,
                title: 'Favorites',
                onTap: () => _push(context, const FavoritesScreen()),
              ),
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'My orders & test rides',
                onTap: () => context.read<ShellController>().go(ShellController.activity),
              ),
              _MenuTile(
                icon: Icons.sports_motorsports_outlined,
                title: 'Book a test ride',
                onTap: () => _push(context, const TestRideScreen()),
              ),
              _MenuTile(
                icon: Icons.map_outlined,
                title: 'Showroom & service map',
                onTap: () => _push(context, const MapScreen()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuGroup(
            children: [
              _MenuTile(
                icon: Icons.api_rounded,
                title: 'Data sources & APIs',
                onTap: () => _push(context, const DataSourcesScreen()),
              ),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Suzuki Moto',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Flutter lab project. Not affiliated with Suzuki Motor Corporation.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuGroup(
            children: [
              _MenuTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                color: AppColors.red,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.15));
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap, this.color});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primaryBright;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color ?? AppColors.text),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
