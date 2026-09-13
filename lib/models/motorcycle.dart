import 'package:flutter/material.dart';

enum BikeCategory {
  sport('Sport', Icons.speed_rounded),
  naked('Naked', Icons.bolt_rounded),
  adventure('Adventure', Icons.terrain_rounded),
  scooter('Scooter', Icons.moped_rounded),
  family('Family', Icons.two_wheeler_rounded),
  offroad('Off-road', Icons.landscape_rounded);

  const BikeCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class BikeColor {
  const BikeColor(this.name, this.color);

  final String name;
  final Color color;
}

class Motorcycle {
  const Motorcycle({
    required this.id,
    required this.name,
    required this.category,
    this.engineCc,
    this.priceThb,
    this.tagline = '',
    this.description = '',
    this.imageUrl,
    this.colors = const [],
    this.keySpecs = const {},
    this.apiModelName,
    this.nhtsaAliases = const [],
    this.inThailand = true,
    this.featured = false,
    this.nhtsaListed = false,
    this.modelYear,
  });

  /// A model from the NHTSA lineup that is not part of the Thai catalog.
  factory Motorcycle.fromNhtsa(String modelName, int year) {
    final slug = modelName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return Motorcycle(
      id: 'global-$slug',
      name: modelName,
      category: guessCategory(modelName),
      tagline: "Part of Suzuki's $year model-year lineup registered with NHTSA.",
      inThailand: false,
      nhtsaListed: true,
      modelYear: year,
    );
  }

  final String id;
  final String name;
  final BikeCategory category;
  final int? engineCc;
  final int? priceThb;
  final String tagline;
  final String description;
  final String? imageUrl;
  final List<BikeColor> colors;
  final Map<String, String> keySpecs;

  /// Model name to query on the API Ninjas Motorcycles API.
  final String? apiModelName;

  /// Names this bike is listed under in the NHTSA vPIC lineup.
  final List<String> nhtsaAliases;
  final bool inThailand;
  final bool featured;
  final bool nhtsaListed;
  final int? modelYear;

  String get fullName => 'Suzuki $name';
  String get baseName => name.split('/').first.trim();
  bool get isBigBike => (engineCc ?? 0) >= 400;
  bool get purchasable => inThailand && priceThb != null;
  String get specsQuery => apiModelName ?? baseName;
  String get imageQuery => 'Suzuki $baseName';

  Motorcycle copyWith({bool? nhtsaListed, int? modelYear}) => Motorcycle(
        id: id,
        name: name,
        category: category,
        engineCc: engineCc,
        priceThb: priceThb,
        tagline: tagline,
        description: description,
        imageUrl: imageUrl,
        colors: colors,
        keySpecs: keySpecs,
        apiModelName: apiModelName,
        nhtsaAliases: nhtsaAliases,
        inThailand: inThailand,
        featured: featured,
        nhtsaListed: nhtsaListed ?? this.nhtsaListed,
        modelYear: modelYear ?? this.modelYear,
      );

  static BikeCategory guessCategory(String modelName) {
    final s = modelName.toLowerCase();
    if (s.contains('burgman')) return BikeCategory.scooter;
    if (s.contains('v-strom') || s.contains('dr650') || s.contains('dr-z4')) return BikeCategory.adventure;
    if (s.startsWith('rm') || s.contains('dr-z')) return BikeCategory.offroad;
    if (s.contains('gsx-8t')) return BikeCategory.naked;
    if (s.contains('gsx-r') || s.contains('hayabusa') || s.contains('8r') || s.contains('250r') || s.contains('gt')) {
      return BikeCategory.sport;
    }
    return BikeCategory.naked;
  }
}
