import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/dealer.dart';
import 'api_exception.dart';

enum OsmDataSource { live, cache, snapshot }

class OsmPlacesResult {
  const OsmPlacesResult(this.places, this.source, this.updatedAt);

  final List<Dealer> places;
  final OsmDataSource source;
  final DateTime? updatedAt;
}

/// Suzuki motorcycle dealers and service shops in Thailand, as mapped by
/// OpenStreetMap contributors, via the Overpass API.
///
/// Overpass servers are often busy, so the app paints saved data first
/// (device cache, or the snapshot bundled with the app) and refreshes live
/// in the background.
class OsmPlacesApi {
  OsmPlacesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const snapshotAsset = 'assets/data/osm_suzuki_th.json';
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const _cacheKey = 'osm_suzuki_places_v1';
  static const _cacheTtl = Duration(hours: 24);

  // Single pass: motorcycle shops whose name, English name or brand mentions Suzuki.
  static const _query = r'[out:json][timeout:45];'
      r'area["ISO3166-1"="TH"][admin_level=2]->.th;'
      r'nwr["shop"~"^(motorcycle|motorcycle_repair)$"][~"^(name|name:en|brand)$"~"suzuki|ซูซูกิ",i](area.th);'
      r'out center tags;';

  /// Data available without the network: the device cache, else the bundled snapshot.
  Future<OsmPlacesResult> saved() async => await _readCache() ?? await _snapshot();

  bool isFresh(OsmPlacesResult result) {
    final updatedAt = result.updatedAt;
    return result.source != OsmDataSource.snapshot &&
        updatedAt != null &&
        DateTime.now().difference(updatedAt) < _cacheTtl;
  }

  /// Fresh data from Overpass, trying each server in turn.
  Future<OsmPlacesResult> live() async {
    var lastError = const ApiException('Could not reach OpenStreetMap');
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(Uri.parse(endpoint), headers: AppConfig.identityHeaders, body: {'data': _query})
            .timeout(const Duration(seconds: 50));
        if (response.statusCode != 200) {
          lastError = ApiException('OpenStreetMap is busy (HTTP ${response.statusCode})');
          continue;
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        // A timed-out Overpass query still answers 200, with a "remark" and no elements.
        if (body['remark'] != null && ((body['elements'] as List?)?.isEmpty ?? true)) {
          lastError = const ApiException('OpenStreetMap query timed out');
          continue;
        }
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode({'fetchedAt': now.millisecondsSinceEpoch, 'body': body}));
        return OsmPlacesResult(parseOverpass(body), OsmDataSource.live, now);
      } on TimeoutException {
        lastError = const ApiException('OpenStreetMap took too long to respond');
      } on FormatException {
        lastError = const ApiException('OpenStreetMap sent an unreadable response');
      } catch (_) {
        lastError = const ApiException('Could not reach OpenStreetMap');
      }
    }
    throw lastError;
  }

  Future<OsmPlacesResult?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return OsmPlacesResult(
        parseOverpass(data['body'] as Map<String, dynamic>),
        OsmDataSource.cache,
        DateTime.fromMillisecondsSinceEpoch((data['fetchedAt'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<OsmPlacesResult> _snapshot() async {
    final body = jsonDecode(await rootBundle.loadString(snapshotAsset)) as Map<String, dynamic>;
    final stamp = (body['osm3s'] as Map?)?['timestamp_osm_base'] as String?;
    return OsmPlacesResult(
      parseOverpass(body),
      OsmDataSource.snapshot,
      stamp == null ? null : DateTime.tryParse(stamp),
    );
  }

  @visibleForTesting
  static List<Dealer> parseOverpass(Map<String, dynamic> body) {
    final places = <Dealer>[];
    for (final raw in (body['elements'] as List?) ?? const []) {
      final element = Map<String, dynamic>.from(raw as Map);
      final center = element['center'] as Map?;
      final lat = (element['lat'] ?? center?['lat']) as num?;
      final lon = (element['lon'] ?? center?['lon']) as num?;
      if (lat == null || lon == null) continue;

      final tags = Map<String, dynamic>.from((element['tags'] as Map?) ?? const {});
      String? tag(String key) {
        final value = tags[key];
        return value is String && value.trim().isNotEmpty ? value.trim() : null;
      }

      final repairOnly = tag('shop') == 'motorcycle_repair';
      final street = [tag('addr:housenumber'), tag('addr:street')].whereType<String>().join(' ');
      final area = tag('addr:province') ?? tag('addr:city') ?? tag('addr:district') ?? '';
      final address = {street, tag('addr:subdistrict') ?? '', tag('addr:district') ?? '', area}
          .where((part) => part.isNotEmpty)
          .join(', ');

      places.add(
        Dealer(
          id: 'osm-${element['type']}-${element['id']}',
          name: tag('name:en') ?? tag('name') ?? (repairOnly ? 'Suzuki service' : 'Suzuki dealer'),
          area: area,
          address: address,
          hours: tag('opening_hours') ?? '',
          phone: tag('phone') ?? tag('contact:phone'),
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
          kind: repairOnly ? LocationKind.service : LocationKind.dealer,
          fromOsm: true,
        ),
      );
    }
    return places;
  }
}
