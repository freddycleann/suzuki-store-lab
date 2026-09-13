import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/dealer.dart';
import '../state/locations_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';
import 'test_ride_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialDealerId});

  final String? initialDealerId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  /// The map extends this far above the screen so that its centre — where a
  /// focused pin lands — sits above the location cards.
  static const _mapLift = 220.0;
  static const _cardsHeight = 204.0;
  static final _thailand = LatLngBounds(const LatLng(5.6, 97.4), const LatLng(20.4, 105.6));

  final _map = MapController();
  final _pages = PageController(viewportFraction: 0.88);
  AnimationController? _flight;
  LocationFilter _filter = LocationFilter.all;
  String? _selectedId;
  bool _mapReady = false;
  bool _syncingPage = false;
  double _zoom = 5.5;

  /// Smaller pins when zoomed out so the country view isn't a pile of markers.
  static double _pinSizeFor(double zoom) => zoom < 7 ? 26 : (zoom < 10 ? 32 : 40);

  void _onZoomChanged(double zoom) {
    final resize = _pinSizeFor(zoom) != _pinSizeFor(_zoom);
    _zoom = zoom;
    if (!resize) return;
    // Camera callbacks can fire during layout, so rebuild after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    final locations = context.read<LocationsProvider>();
    if (locations.osmPlaces.isEmpty && !locations.loading) locations.load();
  }

  @override
  void dispose() {
    _flight?.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _mapReady = true;
    final id = widget.initialDealerId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final places = context.read<LocationsProvider>().visible(_filter);
      final index = places.indexWhere((p) => p.id == id);
      if (index < 0) return;
      _focus(places[index]);
      _syncPage(index, animate: false);
    });
  }

  void _flyTo(LatLng target, double zoom) {
    if (!_mapReady) return;
    final camera = _map.camera;
    final lat = Tween<double>(begin: camera.center.latitude, end: target.latitude);
    final lng = Tween<double>(begin: camera.center.longitude, end: target.longitude);
    final z = Tween<double>(begin: camera.zoom, end: zoom);
    _flight?.dispose();
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    controller.addListener(() {
      _map.move(LatLng(lat.evaluate(curve), lng.evaluate(curve)), z.evaluate(curve));
    });
    _flight = controller;
    controller.forward();
  }

  void _focus(Dealer place) {
    setState(() => _selectedId = place.id);
    final zoom = _mapReady ? math.max(_map.camera.zoom, 13.5) : 13.5;
    _flyTo(LatLng(place.latitude, place.longitude), zoom);
  }

  Future<void> _syncPage(int index, {bool animate = true}) async {
    if (!_pages.hasClients) return;
    _syncingPage = true;
    if (animate) {
      await _pages.animateToPage(index, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      _pages.jumpToPage(index);
    }
    _syncingPage = false;
  }

  void _onMarkerTap(Dealer place, List<Dealer> places) {
    _focus(place);
    final index = places.indexWhere((p) => p.id == place.id);
    if (index >= 0) _syncPage(index);
  }

  void _onPageChanged(int index, List<Dealer> places) {
    if (_syncingPage || index >= places.length) return;
    _focus(places[index]);
  }

  void _fitAll(List<Dealer> places) {
    if (!_mapReady || places.isEmpty) return;
    if (places.length == 1) {
      _focus(places.first);
      return;
    }
    _flight?.stop();
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([for (final p in places) LatLng(p.latitude, p.longitude)]),
        padding: const EdgeInsets.fromLTRB(48, _mapLift + 190, 48, _cardsHeight + 90),
        maxZoom: 14,
      ),
    );
  }

  void _setFilter(LocationFilter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _selectedId = null;
    });
    if (_pages.hasClients) {
      _syncingPage = true;
      _pages.jumpToPage(0);
      _syncingPage = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitAll(context.read<LocationsProvider>().visible(filter));
    });
  }

  Future<void> _locate() async {
    final locations = context.read<LocationsProvider>();
    final problem = await locations.locateUser();
    if (!mounted) return;
    if (problem != null) {
      showAppSnack(context, problem, error: true);
      return;
    }
    final places = locations.visible(_filter);
    if (places.isEmpty) {
      _flyTo(locations.userLocation!, 12);
      return;
    }
    final nearest = places.first;
    _focus(nearest);
    _syncPage(0, animate: false);
    showAppSnack(context, 'Nearest: ${nearest.name} · ${formatKm(locations.distanceKm(nearest)!)} away');
  }

  Future<void> _open(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) showAppSnack(context, 'No app available to open this link', error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, 'No app available to open this link', error: true);
    }
  }

  void _directions(Dealer place, LatLng? from) {
    final to = '${place.latitude},${place.longitude}';
    _open(
      from == null
          ? Uri.parse('https://www.openstreetmap.org/?mlat=${place.latitude}&mlon=${place.longitude}'
              '#map=17/${place.latitude}/${place.longitude}')
          : Uri.parse('https://www.openstreetmap.org/directions?engine=fossgis_osrm_car'
              '&route=${from.latitude},${from.longitude};$to'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationsProvider>();
    final places = locations.visible(_filter);
    final user = locations.userLocation;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Paint order: OpenStreetMap pins, then showrooms, then the selected pin on top.
    final ordered = [
      ...places.where((p) => p.fromOsm && p.id != _selectedId),
      ...places.where((p) => !p.fromOsm && p.id != _selectedId),
      ...places.where((p) => p.id == _selectedId),
    ];
    final pinSize = _pinSizeFor(_zoom);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -_mapLift,
            bottom: 0,
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: _thailand,
                  padding: const EdgeInsets.fromLTRB(24, _mapLift + 170, 24, _cardsHeight + 70),
                ),
                minZoom: 4.5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: _onMapReady,
                onPositionChanged: (camera, hasGesture) => _onZoomChanged(camera.zoom),
                onTap: (tapPosition, point) => setState(() => _selectedId = null),
              ),
              children: [
                osmTileLayer(),
                MarkerLayer(
                  markers: [
                    if (user != null) Marker(point: user, width: 24, height: 24, child: const UserLocationDot()),
                    for (final place in ordered)
                      Marker(
                        point: LatLng(place.latitude, place.longitude),
                        width: 56,
                        height: 56,
                        child: Center(
                          child: MapPin(
                            dealer: place,
                            selected: place.id == _selectedId,
                            size: place.fromOsm ? pinSize : pinSize + 4,
                            onTap: () => _onMarkerTap(place, places),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _TopBar(
            locations: locations,
            filter: _filter,
            onFilter: _setFilter,
          ),
          Positioned(
            right: 16,
            bottom: _cardsHeight + bottomInset + 30,
            child: Column(
              children: [
                CircleIconButton(icon: Icons.fit_screen_rounded, onTap: () => _fitAll(places)),
                const SizedBox(height: 10),
                CircleIconButton(
                  icon: locations.locating ? Icons.more_horiz_rounded : Icons.my_location_rounded,
                  iconColor: user != null ? AppColors.cyan : null,
                  onTap: locations.locating ? null : _locate,
                ),
              ],
            ),
          ),
          Positioned(left: 16, bottom: _cardsHeight + bottomInset + 34, child: const OsmAttribution()),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 14,
            height: _cardsHeight,
            child: places.isEmpty
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _pages,
                    itemCount: places.length,
                    onPageChanged: (index) => _onPageChanged(index, places),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return _LocationCard(
                        place: place,
                        selected: place.id == _selectedId,
                        distanceKm: locations.distanceKm(place),
                        onTap: () => _focus(place),
                        onDirections: () => _directions(place, user),
                        onOpen: _open,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.locations, required this.filter, required this.onFilter});

  final LocationsProvider locations;
  final LocationFilter filter;
  final ValueChanged<LocationFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final subtitle = locations.loading && locations.osmPlaces.isEmpty
        ? 'Loading Suzuki dealers from OpenStreetMap…'
        : '${locations.showrooms.length} showrooms · ${locations.osmPlaces.length} dealers & service on OpenStreetMap';

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF20A0B10), Color(0xB30A0B10), Color(0x000A0B10)],
            stops: [0, 0.65, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BackButtonCircle(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Showrooms & service',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleIconButton(
                      icon: Icons.refresh_rounded,
                      size: 44,
                      onTap: locations.loading ? null : () => locations.load(forceRefresh: true),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final option in LocationFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: locations.filterLabel(option),
                            selected: option == filter,
                            onTap: () => onFilter(option),
                          ),
                        ),
                    ],
                  ),
                ),
                if (locations.loading || locations.error != null) ...[
                  const SizedBox(height: 10),
                  _StatusBanner(locations: locations),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.locations});

  final LocationsProvider locations;

  @override
  Widget build(BuildContext context) {
    final loading = locations.loading;
    final hasData = locations.osmPlaces.isNotEmpty;
    final String message;
    if (loading) {
      message = hasData ? 'Checking OpenStreetMap for updates…' : 'Loading Suzuki dealers from OpenStreetMap…';
    } else if (hasData) {
      message = 'Live update unavailable — ${locations.savedNote}';
    } else {
      message = locations.error ?? '';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(
              hasData ? Icons.info_outline_rounded : Icons.cloud_off_rounded,
              color: hasData ? AppColors.warning : AppColors.red,
              size: 18,
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
          if (!loading)
            TextButton(onPressed: () => locations.load(forceRefresh: true), child: const Text('Retry'))
          else
            const SizedBox(width: 8, height: 36),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.place,
    required this.selected,
    required this.distanceKm,
    required this.onTap,
    required this.onDirections,
    required this.onOpen,
  });

  final Dealer place;
  final bool selected;
  final double? distanceKm;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final showroom = place.kind == LocationKind.showroom;
    final phone = place.phone;
    final distance = distanceKm;

    final Widget action;
    if (place.offersTestRides) {
      action = PrimaryButton(
        label: 'Test ride',
        icon: Icons.sports_motorsports_rounded,
        height: 46,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TestRideScreen(dealer: place)),
        ),
      );
    } else if (phone != null) {
      action = PrimaryButton(
        label: 'Call',
        icon: Icons.call_rounded,
        height: 46,
        onPressed: () => onOpen(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''))),
      );
    } else {
      action = PrimaryButton(
        label: 'On OSM',
        icon: Icons.open_in_new_rounded,
        height: 46,
        onPressed: place.osmUrl == null ? null : () => onOpen(place.osmUrl!),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 1.6 : 1),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MapPin(dealer: place, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            StatusPill(
                              place.kind.label.toUpperCase(),
                              color: showroom ? AppColors.primaryBright : AppColors.cyan,
                            ),
                            if (place.bigBikeCenter) const StatusPill('BIG BIKE', color: AppColors.warning),
                            if (place.fromOsm) const StatusPill('OSM', color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      formatKm(distance),
                      style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              StatusRow(
                icon: Icons.place_outlined,
                text: place.address.isNotEmpty ? place.address : 'Mapped by OpenStreetMap contributors',
              ),
              const SizedBox(height: 5),
              StatusRow(
                icon: Icons.schedule_rounded,
                text: place.hours.isNotEmpty ? place.hours : 'Opening hours not listed',
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Directions',
                      icon: Icons.directions_rounded,
                      height: 46,
                      onPressed: onDirections,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: action),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
