import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/motorcycle.dart';
import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bike_cards.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';
import '../widgets/showroom_map_preview.dart';
import 'bike_detail_screen.dart';
import 'favorites_screen.dart';
import 'test_ride_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController(viewportFraction: 0.84);
  BikeCategory? _category;
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectCategory(BikeCategory? category) {
    setState(() {
      _category = category;
      _page = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _open(Motorcycle bike, String heroTag) => BikeDetailScreen.open(context, bike, heroTag: heroTag);

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final shell = context.read<ShellController>();
    final bikes = catalog.thaiBikes.where((b) => _category == null || b.category == _category).toList();
    final featured = bikes.where((b) => b.featured).toList();
    final carousel = featured.length >= 2 ? featured : bikes.take(4).toList();
    final popular = bikes.where((b) => !carousel.contains(b)).take(6).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: catalog.loadLineup,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: _Headline(onSearch: () => shell.openExplore(global: false))),
            SliverToBoxAdapter(child: CategoryChips(selected: _category, onSelected: _selectCategory)),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (carousel.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Nothing here yet',
                  message: 'No bikes in this category.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: carousel.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final bike = carousel[i];
                      final tag = 'featured-${bike.id}';
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          var delta = (_page - i).toDouble();
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            delta = (_pageController.page ?? _page.toDouble()) - i;
                          }
                          final scale = 1.0 - math.min(delta.abs(), 1.0) * 0.07;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: FeaturedBikeCard(bike: bike, heroTag: tag, onTap: () => _open(bike, tag)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _Dots(count: carousel.length, index: _page)),
            ],
            const SliverToBoxAdapter(child: _TestRidePromo()),
            const SliverToBoxAdapter(child: ShowroomMapPreview()),
            if (popular.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Popular in Thailand',
                  subtitle: 'Bangkok on-the-road prices',
                  actionLabel: 'See all',
                  onAction: () => shell.openExplore(global: false),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final bike = popular[i];
                      final tag = 'popular-${bike.id}';
                      return BikeGridCard(bike: bike, heroTag: tag, onTap: () => _open(bike, tag));
                    },
                    childCount: popular.length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: _LineupSection(onOpen: _open)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final name = context.select<Session, String>((s) => s.user?.displayName ?? 'Rider');
    final initials = context.select<Session, String>((s) => s.user?.initials ?? 'R');
    final cartCount = context.select<Session, int>((s) => s.cartCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          AvatarCircle(initials: initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sawasdee 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.favorite_border_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          const SizedBox(width: 10),
          CircleIconButton(
            icon: Icons.shopping_bag_outlined,
            badge: cartCount,
            onTap: () => context.read<ShellController>().go(ShellController.cart),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Find your\n'),
                TextSpan(text: 'perfect ride.', style: TextStyle(color: AppColors.primaryBright)),
              ],
            ),
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -1.1),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onSearch,
            child: Container(
              height: 58,
              padding: const EdgeInsets.only(left: 18, right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Search GSX-8R, Hayabusa, Burgman…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? AppColors.primary : AppColors.stroke,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestRidePromo extends StatelessWidget {
  const _TestRidePromo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C3FAA), Color(0xFF0B1235)],
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusPill('FREE · 30 MIN', color: AppColors.cyan),
                  const SizedBox(height: 12),
                  const Text('Book a test ride', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Feel the torque before you buy. Pick a showroom, a date and ride.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 150,
                    child: PrimaryButton(
                      label: 'Book now',
                      height: 46,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestRideScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.sports_motorsports_rounded, size: 50, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupSection extends StatelessWidget {
  const _LineupSection({required this.onOpen});

  final void Function(Motorcycle bike, String heroTag) onOpen;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final year = catalog.lineupYear ?? DateTime.now().year;
    final bikes = catalog.globalBikes.take(12).toList();

    final Widget body;
    if (catalog.loadingLineup && bikes.isEmpty) {
      body = const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (catalog.lineupError != null && bikes.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ErrorCard(message: catalog.lineupError!, onRetry: catalog.loadLineup),
      );
    } else {
      body = SizedBox(
        height: 176,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: bikes.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final bike = bikes[i];
            final tag = 'lineup-${bike.id}';
            return _LineupCard(bike: bike, heroTag: tag, onTap: () => onOpen(bike, tag));
          },
        ),
      );
    }

    return Column(
      children: [
        SectionHeader(
          title: 'Global $year lineup',
          subtitle: 'Live from the NHTSA vPIC API',
          actionLabel: 'View all',
          onAction: () => context.read<ShellController>().openExplore(global: true),
        ),
        body,
      ],
    );
  }
}

class _LineupCard extends StatelessWidget {
  const _LineupCard({required this.bike, required this.heroTag, required this.onTap});

  final Motorcycle bike;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return SizedBox(
      width: 150,
      child: Material(
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
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(tag: heroTag, child: BikeImage(bike: bike, iconSize: 36)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bike.inThailand ? 'Sold in Thailand' : bike.category.label,
                        style: TextStyle(
                          color: bike.inThailand ? AppColors.success : AppColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
