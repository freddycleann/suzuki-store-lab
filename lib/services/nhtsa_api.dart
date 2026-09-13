import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// NHTSA vPIC – free public vehicle API, no key required.
/// https://vpic.nhtsa.dot.gov/api/
class NhtsaApi {
  NhtsaApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<String>> suzukiMotorcycleModels(int modelYear) async {
    final uri = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear'
      '/make/suzuki/modelyear/$modelYear/vehicletype/motorcycle?format=json',
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException('NHTSA API responded ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['Results'] as List?) ?? const [];
    final names = {
      for (final row in results)
        if ((row as Map)['Model_Name'] is String) (row['Model_Name'] as String).trim(),
    }.toList()
      ..sort();
    return names;
  }
}
