import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import '../services/osm_places_api.dart';
import '../state/catalog_provider.dart';
import '../state/locations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final locations = context.watch<LocationsProvider>();
    final demo = context.read<AuthService>().isDemo;
    final osmStatus = locations.loading
        ? 'Checking OpenStreetMap for updates…'
        : switch (locations.source) {
            OsmDataSource.live => 'Live · ${locations.osmPlaces.length} Suzuki dealer & service locations',
            OsmDataSource.cache || OsmDataSource.snapshot =>
              '${locations.osmPlaces.length} locations · ${locations.savedNote}',
            null => locations.error ?? 'Not loaded yet',
          };
    final lineupStatus = catalog.loadingLineup
        ? 'Loading…'
        : catalog.lineupError ??
            'Loaded ${catalog.globalBikes.length} Suzuki motorcycle models for ${catalog.lineupYear}';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(padding: EdgeInsets.only(left: 20), child: Center(child: BackButtonCircle())),
        title: const Text('Data sources & APIs'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          _SourceCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Firebase Auth + Cloud Firestore',
            status: demo
                ? 'Demo mode — add your keys to lib/firebase_options.dart'
                : 'Connected to project ${DefaultFirebaseOptions.android.projectId}',
            ok: !demo,
            body: 'Email sign-in, plus each user’s cart, favorites, orders and test-ride bookings under users/{uid}.',
          ),
          _SourceCard(
            icon: Icons.public_rounded,
            title: 'NHTSA vPIC API',
            status: lineupStatus,
            ok: !catalog.loadingLineup && catalog.lineupError == null,
            body: 'vpic.nhtsa.dot.gov — official Suzuki motorcycle model-year lineup. Powers the Global tab '
                'and the “NHTSA listed” badges.',
            action: catalog.lineupError != null
                ? TextButton(onPressed: catalog.loadLineup, child: const Text('Retry'))
                : null,
          ),
          const _SourceCard(
            icon: Icons.photo_library_outlined,
            title: 'Wikimedia Commons API',
            status: 'Photos found on demand and cached on the device',
            ok: true,
            body: 'commons.wikimedia.org — Creative Commons photos of each model.',
          ),
          _SourceCard(
            icon: Icons.map_outlined,
            title: 'OpenStreetMap',
            status: osmStatus,
            ok: !locations.loading && locations.source == OsmDataSource.live,
            body: 'Map tiles from tile.openstreetmap.org and Suzuki dealer & service locations from the '
                'Overpass API, with a bundled snapshot for offline use. © OpenStreetMap contributors (ODbL).',
            action: locations.loading
                ? null
                : TextButton(onPressed: () => locations.load(forceRefresh: true), child: const Text('Refresh')),
          ),
          _SourceCard(
            icon: Icons.tune_rounded,
            title: 'API Ninjas — Motorcycles API',
            status: AppConfig.hasApiNinjasKey
                ? 'API key configured'
                : 'No key — run with --dart-define=API_NINJAS_KEY=your_key',
            ok: AppConfig.hasApiNinjasKey,
            body: 'Full technical specifications (engine, chassis, dimensions) on each bike page.',
          ),
          const _SourceCard(
            icon: Icons.sell_outlined,
            title: 'Thai price list',
            status: 'Bundled catalog',
            ok: true,
            body: 'Bangkok on-the-road prices compiled from 9carthai.com and ZigWheels Thailand (September 2026). '
                'Colors, key specs, showrooms and finance rates are sample data for this lab project.',
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.ok,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool ok;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final statusColor = ok ? AppColors.success : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primaryBright),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, size: 16, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
