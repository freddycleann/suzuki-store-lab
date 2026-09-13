import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../screens/map_screen.dart';
import '../state/locations_provider.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'map_widgets.dart';

/// Home-screen teaser: a non-interactive OpenStreetMap view of greater Bangkok.
class ShowroomMapPreview extends StatelessWidget {
  const ShowroomMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationsProvider>();
    final dealerCount = locations.osmPlaces.isEmpty ? '' : ' · ${locations.osmPlaces.length} dealers & service';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen())),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 196,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(13.76, 100.62),
                      initialZoom: 9.4,
                      interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      osmTileLayer(),
                      MarkerLayer(
                        markers: [
                          for (final place in locations.all)
                            Marker(
                              point: LatLng(place.latitude, place.longitude),
                              width: 26,
                              height: 26,
                              child: MapPin(dealer: place, size: 22),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xF00A0B10), Color(0x990A0B10), Color(0x100A0B10)],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  bottom: 20,
                  right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusPill('SHOWROOMS NEAR YOU', color: AppColors.cyan, icon: Icons.map_rounded),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find a showroom\nor service center',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${locations.showrooms.length} showrooms$dealerCount',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.north_east_rounded, color: Colors.black),
                  ),
                ),
                const Positioned(right: 76, bottom: 16, child: OsmAttribution()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
