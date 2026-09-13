import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suzuki_moto/data/thai_catalog.dart';
import 'package:suzuki_moto/models/cart_item.dart';
import 'package:suzuki_moto/models/dealer.dart';
import 'package:suzuki_moto/models/motorcycle.dart';
import 'package:suzuki_moto/models/shop_order.dart';
import 'package:suzuki_moto/services/osm_places_api.dart';
import 'package:suzuki_moto/utils/finance.dart';
import 'package:suzuki_moto/utils/format.dart';

void main() {
  test('normalizeModel ignores case, spaces and hyphens', () {
    expect(normalizeModel('V-Strom 800DE'), 'vstrom800de');
    expect(normalizeModel('GSX-S1000GT/GSX-S1000GT+'), 'gsxs1000gtgsxs1000gt');
  });

  test('formatThb uses the baht sign and thousands separators', () {
    expect(formatThb(379000), '฿379,000');
  });

  test('finance installment adds flat-rate interest on the financed amount', () {
    // 400,000 with 25% down → 300,000 financed; 2.99% × 4 years = 35,880 interest.
    expect(Finance.downPayment(400000, 0.25), 100000);
    expect(Finance.monthly(price: 400000, downPercent: 0.25, months: 48), 6998);
  });

  test('catalog ids are unique and every bike can be bought', () {
    final ids = ThaiCatalog.bikes.map((b) => b.id).toSet();
    expect(ids.length, ThaiCatalog.bikes.length);
    for (final bike in ThaiCatalog.bikes) {
      expect(bike.purchasable, isTrue, reason: bike.name);
      expect(bike.colors, isNotEmpty, reason: bike.name);
    }
  });

  test('NHTSA model names map to sensible categories', () {
    expect(Motorcycle.guessCategory('GSX-R600'), BikeCategory.sport);
    expect(Motorcycle.guessCategory('Burgman 400'), BikeCategory.scooter);
    expect(Motorcycle.guessCategory('RM-Z450'), BikeCategory.offroad);
    expect(Motorcycle.guessCategory('V-Strom 1050'), BikeCategory.adventure);
    expect(Motorcycle.guessCategory('SV650'), BikeCategory.naked);
  });

  test('OpenStreetMap Overpass results become map locations', () {
    final places = OsmPlacesApi.parseOverpass({
      'elements': [
        {
          'type': 'node',
          'id': 42,
          'lat': 12.9338,
          'lon': 100.8946,
          'tags': {
            'shop': 'motorcycle',
            'name': 'Mityon Pattaya',
            'phone': '+66 38 410846',
            'opening_hours': '08:00-20:00',
            'addr:province': 'Chon Buri',
          },
        },
        {
          'type': 'way',
          'id': 7,
          'center': {'lat': 13.7042, 'lon': 100.5449},
          'tags': {'shop': 'motorcycle_repair'},
        },
        {'type': 'node', 'id': 8, 'tags': {'shop': 'motorcycle'}},
      ],
    });
    expect(places, hasLength(2));
    expect(places.first.name, 'Mityon Pattaya');
    expect(places.first.kind, LocationKind.dealer);
    expect(places.first.osmUrl.toString(), 'https://www.openstreetmap.org/node/42');
    expect(places.last.name, 'Suzuki service');
    expect(places.last.kind, LocationKind.service);
    expect(places.last.latitude, 13.7042);
  });

  test('bundled OpenStreetMap snapshot parses into Thai locations', () {
    final body = jsonDecode(File(OsmPlacesApi.snapshotAsset).readAsStringSync()) as Map<String, dynamic>;
    final places = OsmPlacesApi.parseOverpass(body);
    expect(places.length, greaterThan(20));
    for (final place in places) {
      expect(place.fromOsm, isTrue);
      expect(place.latitude, inInclusiveRange(5.0, 21.0), reason: place.id);
      expect(place.longitude, inInclusiveRange(97.0, 106.0), reason: place.id);
    }
  });

  test('distances are formatted for riders', () {
    expect(formatKm(0.42), '420 m');
    expect(formatKm(3.26), '3.3 km');
    expect(formatKm(128.6), '129 km');
  });

  test('orders survive a Firestore map round trip', () {
    final order = ShopOrder(
      id: 'abc',
      items: const [
        CartItem(
          id: 'gsx-8r_blue',
          bikeId: 'gsx-8r',
          bikeName: 'GSX-8R',
          colorName: 'Blue',
          colorValue: 0xFF1E4DB7,
          unitPrice: 419000,
          quantity: 2,
        ),
      ],
      subtotal: 838000,
      plan: PaymentPlan.finance,
      downPayment: 209500,
      months: 48,
      monthlyInstallment: 14000,
      dealerId: 'bkk-rama9',
      dealerName: 'Suzuki Showroom Rama 9',
      phone: '0812345678',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1757800000000),
    );
    final copy = ShopOrder.fromMap('abc', order.toMap());
    expect(copy.plan, PaymentPlan.finance);
    expect(copy.items.single.id, 'gsx-8r_blue');
    expect(copy.itemCount, 2);
    expect(copy.createdAt, order.createdAt);
  });
}
