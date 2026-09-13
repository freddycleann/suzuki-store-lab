import 'package:flutter/material.dart';

import '../models/motorcycle.dart';

/// Suzuki motorcycles sold in Thailand.
///
/// Prices are Bangkok on-the-road, compiled from 9carthai.com and ZigWheels
/// Thailand (September 2026). Photos were resolved through the Wikimedia
/// Commons API. Colors and key specs are approximate sample data.
class ThaiCatalog {
  ThaiCatalog._();

  static const _commons = 'https://thumb.wikimedia.org/wikipedia/commons/thumb';

  static const _tritonBlue = BikeColor('Metallic Triton Blue', Color(0xFF1E4DB7));
  static const _sparkleBlack = BikeColor('Glass Sparkle Black', Color(0xFF141518));
  static const _mechanicalGray = BikeColor('Matte Mechanical Gray', Color(0xFF5E6166));
  static const _vigorBlue = BikeColor('Pearl Vigor Blue', Color(0xFF1F4FB5));
  static const _championYellow = BikeColor('Champion Yellow No.2', Color(0xFFF2C300));

  static Motorcycle get heroBike => bikes.firstWhere((b) => b.id == 'gsx-8r');

  static const bikes = <Motorcycle>[
    Motorcycle(
      id: 'gsx-8r',
      name: 'GSX-8R',
      category: BikeCategory.sport,
      engineCc: 776,
      priceThb: 419000,
      featured: true,
      tagline: 'Twin-cylinder sport bike built for real roads.',
      description: 'A full-fairing sports machine powered by Suzuki’s 776 cc parallel twin with a 270° crank. '
          'Ride modes, traction control and a bi-directional quick shifter make it as happy on a weekend '
          'mountain run as on the daily commute.',
      imageUrl: '$_commons/d/d6/Suzuki_GSX-8R_mit_Heckumbau.jpg/960px-Suzuki_GSX-8R_mit_Heckumbau.jpg',
      colors: [_tritonBlue, _mechanicalGray, BikeColor('Pearl Ignite Yellow', Color(0xFFE8C21A))],
      keySpecs: {'Power': '83 hp', 'Weight': '205 kg', 'Seat height': '810 mm', 'Fuel tank': '14 L'},
      nhtsaAliases: ['GSX-8R'],
    ),
    Motorcycle(
      id: 'hayabusa',
      name: 'Hayabusa',
      category: BikeCategory.sport,
      engineCc: 1340,
      priceThb: 899000,
      featured: true,
      tagline: 'The legendary ultimate sport bike.',
      description: 'Suzuki’s flagship hyperbike pairs a 1,340 cc inline-four with a full electronics suite — '
          'launch control, cruise control and cornering ABS — wrapped in its unmistakable aerodynamic bodywork.',
      imageUrl: '$_commons/1/10/2005_Suzuki_Hayabusa.jpg/960px-2005_Suzuki_Hayabusa.jpg',
      colors: [_sparkleBlack, _vigorBlue, BikeColor('Matte Sword Silver', Color(0xFF8D9096))],
      keySpecs: {'Power': '190 hp', 'Weight': '264 kg', 'Seat height': '800 mm', 'Fuel tank': '20 L'},
      nhtsaAliases: ['Hayabusa'],
    ),
    Motorcycle(
      id: 'v-strom-800de',
      name: 'V-Strom 800DE',
      category: BikeCategory.adventure,
      engineCc: 776,
      priceThb: 479000,
      featured: true,
      tagline: 'Adventure-ready on and off the tarmac.',
      description: 'A dual-purpose tourer with a 21-inch front wheel, long-travel suspension and the 776 cc twin. '
          'Gravel traction mode and switchable rear ABS let it take on unpaved mountain roads with confidence.',
      imageUrl: '$_commons/6/61/Suzuki_V-Strom_800DE_%283%29.jpg/960px-Suzuki_V-Strom_800DE_%283%29.jpg',
      colors: [_championYellow, _mechanicalGray, _vigorBlue],
      keySpecs: {'Power': '83 hp', 'Weight': '230 kg', 'Seat height': '855 mm', 'Fuel tank': '20 L'},
      nhtsaAliases: ['V-Strom 800DE'],
    ),
    Motorcycle(
      id: 'gsx-8s',
      name: 'GSX-8S',
      category: BikeCategory.naked,
      engineCc: 776,
      priceThb: 379000,
      featured: true,
      tagline: 'Street fighter with a stacked-LED face.',
      description: 'The naked sibling of the GSX-8R: the same torquey 776 cc twin, upright ergonomics and a sharp, '
          'futuristic look. Light, agile and ideal for city riding.',
      imageUrl: '$_commons/0/03/Suzuki_GSX-8S%2C_Auto_2024%2C_Zurich_%28PANA0820%29.jpg/'
          '960px-Suzuki_GSX-8S%2C_Auto_2024%2C_Zurich_%28PANA0820%29.jpg',
      colors: [_tritonBlue, _mechanicalGray, BikeColor('Pearl Tech White', Color(0xFFE9EAEC))],
      keySpecs: {'Power': '83 hp', 'Weight': '202 kg', 'Seat height': '810 mm', 'Fuel tank': '14 L'},
      nhtsaAliases: ['GSX-8S'],
    ),
    Motorcycle(
      id: 'gsx-r1000r',
      name: 'GSX-R1000R',
      category: BikeCategory.sport,
      engineCc: 999,
      priceThb: 811000,
      tagline: 'MotoGP-derived superbike technology.',
      description: 'A 999 cc inline-four with variable valve timing, Showa Balance Free suspension and an IMU-based '
          'electronics package — the most track-focused GSX-R Suzuki has built.',
      imageUrl: '$_commons/8/8c/GSX-R1000R_L7_%282017%29.jpg/960px-GSX-R1000R_L7_%282017%29.jpg',
      colors: [_tritonBlue, _sparkleBlack, BikeColor('Metallic Matte Black', Color(0xFF2A2B2E))],
      keySpecs: {'Power': '199 hp', 'Weight': '203 kg', 'Seat height': '825 mm', 'Fuel tank': '16 L'},
      nhtsaAliases: ['GSX-R1000R', 'GSX-R1000'],
    ),
    Motorcycle(
      id: 'v-strom-1050de',
      name: 'V-Strom 1050DE',
      category: BikeCategory.adventure,
      engineCc: 1037,
      priceThb: 659000,
      tagline: 'Big-twin adventure tourer.',
      description: 'A 1,037 cc V-twin with ride-by-wire, a six-axis IMU, cornering ABS and a 21-inch front wheel. '
          'Built for crossing borders two-up with luggage.',
      imageUrl: '$_commons/8/8a/Suzuki_V-Strom_1050.jpg/960px-Suzuki_V-Strom_1050.jpg',
      colors: [_championYellow, _sparkleBlack, _vigorBlue],
      keySpecs: {'Power': '107 hp', 'Weight': '252 kg', 'Seat height': '880 mm', 'Fuel tank': '20 L'},
      apiModelName: 'V-Strom 1050',
      nhtsaAliases: ['V-Strom 1050DE', 'V-Strom 1050'],
    ),
    Motorcycle(
      id: 'sv650x',
      name: 'SV650X',
      category: BikeCategory.naked,
      engineCc: 645,
      priceThb: 301000,
      tagline: 'Café-racer style, V-twin soul.',
      description: 'Clip-on bars, a tuck-and-roll seat and a headlight cowl give the SV650X its café-racer '
          'character, while the proven 645 cc V-twin delivers smooth, friendly torque.',
      imageUrl: '$_commons/3/32/SV650X_2021model.jpg/960px-SV650X_2021model.jpg',
      colors: [_sparkleBlack, BikeColor('Matte Steel Green', Color(0xFF4F5B4A))],
      keySpecs: {'Power': '73 hp', 'Weight': '199 kg', 'Seat height': '790 mm', 'Fuel tank': '13.8 L'},
      nhtsaAliases: ['SV650X', 'SV650'],
    ),
    Motorcycle(
      id: 'dr-z4s',
      name: 'DR-Z4S',
      category: BikeCategory.adventure,
      engineCc: 398,
      priceThb: 339000,
      tagline: 'Lightweight dual-sport, reborn.',
      description: 'The legendary DR-Z400 returns with fuel injection, ride modes, traction control and switchable '
          'ABS. Light and tall, it is equally at home on trails and back roads.',
      imageUrl: '$_commons/5/50/2025_Suzuki_DR-Z4S.jpg/960px-2025_Suzuki_DR-Z4S.jpg',
      colors: [_championYellow, BikeColor('Solid Special White', Color(0xFFF4F4F2))],
      keySpecs: {'Power': '38 hp', 'Weight': '151 kg', 'Seat height': '920 mm', 'Fuel tank': '8.7 L'},
      nhtsaAliases: ['DR-Z4S'],
    ),
    Motorcycle(
      id: 'burgman-400',
      name: 'Burgman 400',
      category: BikeCategory.scooter,
      engineCc: 399,
      priceThb: 239000,
      tagline: 'Premium maxi-scooter comfort.',
      description: 'A 399 cc single with a smooth CVT, a spacious under-seat storage bay and a relaxed, '
          'weather-protected riding position — made for long city commutes.',
      imageUrl: '$_commons/3/36/Suzuki_Burgman_400_2025.jpg/960px-Suzuki_Burgman_400_2025.jpg',
      colors: [
        BikeColor('Pearl Brilliant White', Color(0xFFF1F1EF)),
        BikeColor('Matte Stellar Blue', Color(0xFF2B3A55)),
        _sparkleBlack,
      ],
      keySpecs: {'Power': '29 hp', 'Weight': '218 kg', 'Seat height': '755 mm', 'Fuel tank': '13.5 L'},
      nhtsaAliases: ['Burgman 400'],
    ),
    Motorcycle(
      id: 'v-strom-sx',
      name: 'V-Strom SX',
      category: BikeCategory.adventure,
      engineCc: 249,
      priceThb: 179000,
      tagline: 'Entry-level adventure for every day.',
      description: 'A 249 cc oil-cooled single in a rugged adventure package with a tall screen, knuckle guards and '
          'a bash plate. Easy to ride, cheap to run and ready to explore.',
      imageUrl: '$_commons/8/84/2022_Suzuki_V-Strom_SX_250_%2820221105%29.jpg/'
          '960px-2022_Suzuki_V-Strom_SX_250_%2820221105%29.jpg',
      colors: [_championYellow, BikeColor('Pearl Blaze Orange', Color(0xFFE5642B)), _sparkleBlack],
      keySpecs: {'Power': '26 hp', 'Weight': '167 kg', 'Seat height': '835 mm', 'Fuel tank': '12 L'},
      apiModelName: 'V-Strom 250',
    ),
    Motorcycle(
      id: 'burgman-street',
      name: 'Burgman Street 125',
      category: BikeCategory.scooter,
      engineCc: 124,
      priceThb: 69900,
      tagline: 'Maxi-scooter style for the city.',
      description: 'Big-scooter looks in a nimble 125 cc package, with LED lighting, a USB charger and a generous '
          'seat. Frugal fuel injection keeps running costs low.',
      imageUrl: '$_commons/e/eb/2023_Suzuki_Burgman_Street_125_EX.jpg/960px-2023_Suzuki_Burgman_Street_125_EX.jpg',
      colors: [
        BikeColor('Pearl Mirage White', Color(0xFFEDEDEA)),
        BikeColor('Metallic Matte Black', Color(0xFF2A2B2E)),
        BikeColor('Matte Bordeaux Red', Color(0xFF6E1F2B)),
      ],
      keySpecs: {'Power': '8.6 hp', 'Weight': '111 kg', 'Seat height': '780 mm', 'Fuel tank': '5.5 L'},
      apiModelName: 'Burgman Street',
    ),
    Motorcycle(
      id: 'smash-115',
      name: 'Smash 115 Fi',
      category: BikeCategory.family,
      engineCc: 113,
      priceThb: 52400,
      tagline: 'Thailand’s everyday workhorse.',
      description: 'A fuel-injected 113 cc family bike with a semi-automatic gearbox, light weight and excellent '
          'economy — built for errands, school runs and daily commuting.',
      imageUrl: '$_commons/4/48/2012_Suzuki_Smash_Titan_115_R_%2820210914%29.jpg/'
          '960px-2012_Suzuki_Smash_Titan_115_R_%2820210914%29.jpg',
      colors: [
        BikeColor('Racing Red', Color(0xFFC8102E)),
        BikeColor('Titan Black', Color(0xFF1A1A1C)),
        BikeColor('Pearl White', Color(0xFFF0F0EE)),
      ],
      keySpecs: {'Power': '9 hp', 'Weight': '98 kg', 'Seat height': '765 mm', 'Fuel tank': '4 L'},
      apiModelName: 'Smash',
    ),
    Motorcycle(
      id: 'nex-crossover',
      name: 'Nex Crossover',
      category: BikeCategory.family,
      engineCc: 113,
      priceThb: 49900,
      tagline: 'Compact automatic with crossover attitude.',
      description: 'An easy-to-ride 113 cc automatic with block-pattern tyres, a sporty handlebar and a light, '
          'compact body. Suzuki’s most affordable way onto two wheels.',
      imageUrl: '$_commons/7/79/2021_Suzuki_Nex_Crossover_115_%2820211029%29.jpg/'
          '960px-2021_Suzuki_Nex_Crossover_115_%2820211029%29.jpg',
      colors: [
        BikeColor('Matte Gray', Color(0xFF6B6E73)),
        BikeColor('Matte Blue', Color(0xFF34507A)),
      ],
      keySpecs: {'Power': '9 hp', 'Weight': '95 kg', 'Seat height': '760 mm', 'Fuel tank': '4.2 L'},
      apiModelName: 'Nex',
    ),
  ];
}
