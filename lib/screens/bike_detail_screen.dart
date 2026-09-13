import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/motorcycle.dart';
import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../state/shell_controller.dart';
import '../theme/app_theme.dart';
import '../utils/finance.dart';
import '../utils/format.dart';
import '../widgets/bike_cards.dart';
import '../widgets/bike_image.dart';
import '../widgets/common.dart';
import 'test_ride_screen.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({super.key, required this.bike, required this.heroTag});

  final Motorcycle bike;
  final String heroTag;

  static Future<void> open(BuildContext context, Motorcycle bike, {required String heroTag}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BikeDetailScreen(bike: bike, heroTag: heroTag)),
      );

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  int _colorIndex = 0;
  bool _adding = false;

  static List<BikeColor> _colorsOf(Motorcycle bike) =>
      bike.colors.isEmpty ? const [BikeColor('Standard', AppColors.primary)] : bike.colors;

  Future<void> _addToCart(Motorcycle bike) async {
    final session = context.read<Session>();
    final shell = context.read<ShellController>();
    final navigator = Navigator.of(context);
    setState(() => _adding = true);
    try {
      await session.addToCart(bike, _colorsOf(bike)[_colorIndex]);
      if (!mounted) return;
      showAppSnack(
        context,
        '${bike.name} added to your cart',
        actionLabel: 'VIEW CART',
        onAction: () {
          shell.go(ShellController.cart);
          navigator.popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      if (mounted) showAppSnack(context, 'Could not add to cart: $e', error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bike = context.select<CatalogProvider, Motorcycle>((c) => c.byId(widget.bike.id) ?? widget.bike);
    final colors = _colorsOf(bike);
    final color = colors[_colorIndex.clamp(0, colors.length - 1)];
    final stageHeight = MediaQuery.sizeOf(context).height * 0.46;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: stageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: widget.heroTag, child: BikeImage(bike: bike, iconSize: 110)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x99000000), Color(0x00000000), Color(0x000A0B10), AppColors.bg],
                        stops: [0, 0.3, 0.72, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BackButtonCircle(background: Colors.black.withValues(alpha: 0.35)),
                          const Spacer(),
                          FavoriteButton(bikeId: bike.id),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(bike.category.label.toUpperCase(), icon: bike.category.icon),
                      if (bike.nhtsaListed)
                        StatusPill(
                          'NHTSA ${bike.modelYear ?? ''} LISTED',
                          color: AppColors.success,
                          icon: Icons.verified_rounded,
                        ),
                      if (bike.isBigBike) const StatusPill('BIG BIKE', color: AppColors.warning),
                      if (!bike.inThailand) const StatusPill('NOT SOLD IN THAILAND', color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    bike.fullName,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1),
                  ),
                  if (bike.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(bike.tagline, style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  _PriceCard(bike: bike),
                  if (bike.purchasable) ...[
                    const SizedBox(height: 24),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Color   ', style: TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(
                            text: color.name,
                            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < colors.length; i++)
                          _Swatch(
                            color: colors[i].color,
                            selected: i == _colorIndex,
                            onTap: () => setState(() => _colorIndex = i),
                          ),
                      ],
                    ),
                  ],
                  if (bike.keySpecs.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const Text('Key specs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _KeySpecs(specs: bike.keySpecs),
                  ],
                  if (bike.description.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const Text('About this bike', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      bike.description,
                      style: const TextStyle(color: AppColors.textMuted, height: 1.6, fontSize: 14.5),
                    ),
                  ],
                  const SizedBox(height: 26),
                  _FullSpecs(key: ValueKey(bike.id), bike: bike),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Test ride',
                    icon: Icons.sports_motorsports_outlined,
                    onPressed: bike.inThailand
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TestRideScreen(bike: bike)),
                            )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: bike.purchasable ? 'Add to cart' : 'Unavailable',
                    icon: bike.purchasable ? Icons.shopping_bag_outlined : null,
                    loading: _adding,
                    onPressed: bike.purchasable ? () => _addToCart(bike) : null,
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

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.bike});

  final Motorcycle bike;

  @override
  Widget build(BuildContext context) {
    final price = bike.priceThb;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price != null ? 'Bangkok on-the-road price' : 'Availability',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  price != null
                      ? formatThb(price)
                      : (bike.inThailand ? 'Ask your showroom' : 'Not sold in Thailand'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                if (price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'or ${formatThb(Finance.monthly(price: price, downPercent: 0.25, months: 48))}/mo '
                    'with Suzuki Finance',
                    style: const TextStyle(color: AppColors.cyan, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (bike.engineCc != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('${bike.engineCc}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Text('cc', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.primaryBright : AppColors.stroke, width: 2),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
      ),
    );
  }
}

class _KeySpecs extends StatelessWidget {
  const _KeySpecs({required this.specs});

  final Map<String, String> specs;

  static const _icons = <String, IconData>{
    'Power': Icons.bolt_rounded,
    'Weight': Icons.scale_rounded,
    'Seat height': Icons.height_rounded,
    'Fuel tank': Icons.local_gas_station_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final entries = specs.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_icons[entry.key] ?? Icons.info_outline_rounded, color: AppColors.primaryBright, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(entry.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FullSpecs extends StatefulWidget {
  const _FullSpecs({super.key, required this.bike});

  final Motorcycle bike;

  @override
  State<_FullSpecs> createState() => _FullSpecsState();
}

class _FullSpecsState extends State<_FullSpecs> {
  late Future<Map<String, String>?> _future;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<CatalogProvider>().specsFor(widget.bike);
  }

  void _retry() => setState(() => _future = context.read<CatalogProvider>().specsFor(widget.bike));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.primaryBright, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text('Full specifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              Text(
                'API Ninjas',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, String>?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _Note(
                  icon: Icons.cloud_off_rounded,
                  text: 'Could not load specs: ${snapshot.error}',
                  action: TextButton(onPressed: _retry, child: const Text('Retry')),
                );
              }
              final specs = snapshot.data;
              if (specs == null) {
                return const _Note(
                  icon: Icons.key_rounded,
                  text: 'Add a free API Ninjas key (--dart-define=API_NINJAS_KEY=…) to load the full '
                      'technical sheet for this model.',
                );
              }
              if (specs.isEmpty) {
                return const _Note(
                  icon: Icons.search_off_rounded,
                  text: 'API Ninjas has no detailed record for this model yet.',
                );
              }
              final entries = specs.entries.toList();
              final visible = _expanded ? entries : entries.take(8).toList();
              return Column(
                children: [
                  for (final entry in visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(entry.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (entries.length > 8)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(_expanded ? 'Show less' : 'Show all ${entries.length} specs'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45)),
        ),
        ?action,
      ],
    );
  }
}
