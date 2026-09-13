import 'package:flutter/material.dart';

enum LocationKind {
  showroom('Showroom', Icons.storefront_rounded),
  dealer('Dealer & service', Icons.two_wheeler_rounded),
  service('Service center', Icons.build_rounded);

  const LocationKind(this.label, this.icon);

  final String label;
  final IconData icon;
}

class Dealer {
  const Dealer({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.hours,
    required this.latitude,
    required this.longitude,
    this.bigBikeCenter = false,
    this.kind = LocationKind.showroom,
    this.phone,
    this.fromOsm = false,
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final String hours;
  final double latitude;
  final double longitude;
  final bool bigBikeCenter;
  final LocationKind kind;
  final String? phone;

  /// Mapped by OpenStreetMap contributors rather than part of the app's showroom list.
  final bool fromOsm;

  bool get offersTestRides => kind == LocationKind.showroom;

  /// e.g. https://www.openstreetmap.org/node/123 for places from OpenStreetMap.
  Uri? get osmUrl {
    if (!fromOsm) return null;
    final parts = id.split('-');
    return parts.length == 3 ? Uri.parse('https://www.openstreetmap.org/${parts[1]}/${parts[2]}') : null;
  }
}
