import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../data/dealers.dart';
import '../models/dealer.dart';
import '../services/api_exception.dart';
import '../services/osm_places_api.dart';

enum LocationFilter { all, showrooms, network }

/// Showrooms plus Suzuki dealers and service shops from OpenStreetMap,
/// with optional distance sorting from the rider's location.
class LocationsProvider extends ChangeNotifier {
  LocationsProvider({OsmPlacesApi? api}) : _api = api ?? OsmPlacesApi();

  final OsmPlacesApi _api;

  final List<Dealer> showrooms = Dealers.all;
  List<Dealer> osmPlaces = const [];
  OsmDataSource? source;
  DateTime? updatedAt;
  bool loading = false;
  String? error;

  LatLng? userLocation;
  bool locating = false;

  List<Dealer> get all => [...showrooms, ...osmPlaces];

  String get savedNote {
    final when = updatedAt;
    return when == null
        ? 'showing saved OpenStreetMap data'
        : 'showing OpenStreetMap data from ${DateFormat('d MMM yyyy').format(when.toLocal())}';
  }

  /// Paints saved data straight away, then refreshes from OpenStreetMap.
  Future<void> load({bool forceRefresh = false}) async {
    if (loading) return;
    loading = true;
    error = null;
    // Deferred because load() can be triggered while widgets are building.
    scheduleMicrotask(notifyListeners);
    try {
      if (osmPlaces.isEmpty) {
        final saved = await _api.saved();
        _apply(saved);
        notifyListeners();
        if (!forceRefresh && _api.isFresh(saved)) return;
      }
      _apply(await _api.live());
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load dealers from OpenStreetMap.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _apply(OsmPlacesResult result) {
    osmPlaces = result.places;
    source = result.source;
    updatedAt = result.updatedAt;
  }

  /// Returns null on success, otherwise a message explaining what went wrong.
  Future<String?> locateUser() async {
    locating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Turn on location services to find showrooms near you.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return 'Location permission is needed to sort showrooms by distance.';
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } on TimeoutException {
        // No fresh fix yet (indoors, or an emulator without a GPS feed).
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return 'Could not get a GPS fix yet. Please try again in a moment.';
      userLocation = LatLng(position.latitude, position.longitude);
      return null;
    } catch (e) {
      return 'Could not get your location: $e';
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  double? distanceKm(Dealer place) {
    final user = userLocation;
    if (user == null) return null;
    return Geolocator.distanceBetween(user.latitude, user.longitude, place.latitude, place.longitude) / 1000;
  }

  String filterLabel(LocationFilter filter) => switch (filter) {
        LocationFilter.all => 'All · ${showrooms.length + osmPlaces.length}',
        LocationFilter.showrooms => 'Showrooms · ${showrooms.length}',
        LocationFilter.network => 'Dealers & service · ${osmPlaces.length}',
      };

  /// Places for [filter], nearest first once the rider's location is known.
  List<Dealer> visible(LocationFilter filter) {
    final places = switch (filter) {
      LocationFilter.all => all,
      LocationFilter.showrooms => [...showrooms],
      LocationFilter.network => [...osmPlaces],
    };
    if (userLocation != null) {
      places.sort((a, b) => distanceKm(a)!.compareTo(distanceKm(b)!));
    }
    return places;
  }
}
