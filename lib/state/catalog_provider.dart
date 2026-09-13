import 'package:flutter/foundation.dart';

import '../data/thai_catalog.dart';
import '../models/motorcycle.dart';
import '../services/api_exception.dart';
import '../services/commons_image_api.dart';
import '../services/motorcycle_specs_api.dart';
import '../services/nhtsa_api.dart';
import '../utils/format.dart';

enum SortMode {
  featured('Featured'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  name('Name A–Z');

  const SortMode(this.label);

  final String label;
}

/// Motorcycle data: the Thai catalog, enriched with the live NHTSA lineup,
/// Wikimedia Commons photos and API Ninjas specs.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider({NhtsaApi? nhtsa, MotorcycleSpecsApi? specs, CommonsImageApi? images})
      : _nhtsa = nhtsa ?? NhtsaApi(),
        _specs = specs ?? MotorcycleSpecsApi(),
        _images = images ?? CommonsImageApi();

  final NhtsaApi _nhtsa;
  final MotorcycleSpecsApi _specs;
  final CommonsImageApi _images;

  List<Motorcycle> _thai = ThaiCatalog.bikes;
  List<Motorcycle> _global = const [];
  final _specCache = <String, Future<Map<String, String>?>>{};

  bool loadingLineup = false;
  String? lineupError;
  int? lineupYear;

  List<Motorcycle> get thaiBikes => _thai;
  List<Motorcycle> get globalBikes => _global;

  Motorcycle? byId(String id) {
    for (final bike in [..._thai, ..._global]) {
      if (bike.id == id) return bike;
    }
    return null;
  }

  Future<void> loadLineup() async {
    if (loadingLineup) return;
    loadingLineup = true;
    lineupError = null;
    notifyListeners();
    try {
      var year = DateTime.now().year;
      var models = await _nhtsa.suzukiMotorcycleModels(year);
      if (models.isEmpty) {
        year -= 1;
        models = await _nhtsa.suzukiMotorcycleModels(year);
      }
      final listed = {for (final m in models) normalizeModel(m)};
      _thai = [
        for (final bike in ThaiCatalog.bikes)
          bike.copyWith(
            nhtsaListed: bike.nhtsaAliases.any((alias) => listed.contains(normalizeModel(alias))),
            modelYear: year,
          ),
      ];
      final thaiByAlias = {
        for (final bike in _thai)
          for (final alias in bike.nhtsaAliases) normalizeModel(alias): bike,
      };
      final seen = <String>{};
      final global = <Motorcycle>[];
      for (final model in models) {
        if (_isAtv(model)) continue;
        final bike = thaiByAlias[normalizeModel(model)] ?? Motorcycle.fromNhtsa(model, year);
        if (seen.add(bike.id)) global.add(bike);
      }
      _global = global;
      lineupYear = year;
    } on ApiException catch (e) {
      lineupError = e.message;
    } catch (_) {
      lineupError = 'Could not reach the NHTSA vehicle API.';
    } finally {
      loadingLineup = false;
      notifyListeners();
    }
  }

  static bool _isAtv(String model) {
    final s = model.toLowerCase();
    return s.contains('kingquad') || s.contains('quadsport') || s.contains('quadrunner');
  }

  List<Motorcycle> search({
    String query = '',
    BikeCategory? category,
    bool global = false,
    SortMode sort = SortMode.featured,
  }) {
    final needle = normalizeModel(query);
    final results = (global ? _global : _thai)
        .where((b) => category == null || b.category == category)
        .where((b) => needle.isEmpty || normalizeModel('${b.name} ${b.category.label}').contains(needle))
        .toList();
    const missing = 1 << 40;
    switch (sort) {
      case SortMode.priceLow:
        results.sort((a, b) => (a.priceThb ?? missing).compareTo(b.priceThb ?? missing));
      case SortMode.priceHigh:
        results.sort((a, b) => (b.priceThb ?? -1).compareTo(a.priceThb ?? -1));
      case SortMode.name:
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortMode.featured:
        break;
    }
    return results;
  }

  Future<String?> imageFor(Motorcycle bike) {
    final url = bike.imageUrl;
    if (url != null) return SynchronousFuture(url);
    return _images.findImage(bike.imageQuery, mustContain: bike.baseName);
  }

  Future<Map<String, String>?> specsFor(Motorcycle bike) {
    return _specCache.putIfAbsent(bike.id, () {
      final future = _specs.fetchSpecs(bike.specsQuery);
      future.catchError((Object _) {
        _specCache.remove(bike.id);
        return null;
      });
      return future;
    });
  }
}
