import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/catalog_provider.dart';
import '../state/session.dart';
import '../widgets/bike_cards.dart';
import '../widgets/common.dart';
import 'bike_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.select<Session, Set<String>>((s) => s.favorites);
    final catalog = context.watch<CatalogProvider>();
    final bikes = [for (final id in favorites) ?catalog.byId(id)];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: Center(child: BackButtonCircle())),
        title: const Text('Favorites'),
      ),
      body: bikes.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the heart on any bike to save it here.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemCount: bikes.length,
              itemBuilder: (context, i) {
                final bike = bikes[i];
                final tag = 'favorite-${bike.id}';
                return BikeGridCard(
                  bike: bike,
                  heroTag: tag,
                  onTap: () => BikeDetailScreen.open(context, bike, heroTag: tag),
                );
              },
            ),
    );
  }
}
