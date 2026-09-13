import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// API Ninjas Motorcycles API – detailed technical specs.
/// https://api-ninjas.com/api/motorcycles
class MotorcycleSpecsApi {
  MotorcycleSpecsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _skipKeys = {'make', 'model', 'year'};

  /// Returns null when no API key is configured, an empty map when the API
  /// has no match, otherwise label → value pairs for the newest model year.
  Future<Map<String, String>?> fetchSpecs(String model) async {
    if (!AppConfig.hasApiNinjasKey) return null;
    final uri = Uri.https('api.api-ninjas.com', '/v1/motorcycles', {'make': 'suzuki', 'model': model});
    final response = await _client
        .get(uri, headers: {'X-Api-Key': AppConfig.apiNinjasKey})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException('API Ninjas responded ${response.statusCode}');
    }
    final rows = List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
    if (rows.isEmpty) return const {};
    int yearOf(Map<String, dynamic> row) => int.tryParse('${row['year']}') ?? 0;
    rows.sort((a, b) => yearOf(b).compareTo(yearOf(a)));
    final latest = rows.first;
    return {
      'Model year': '${latest['year']}',
      for (final entry in latest.entries)
        if (!_skipKeys.contains(entry.key) && '${entry.value}'.trim().isNotEmpty)
          _label(entry.key): '${entry.value}'.trim(),
    };
  }

  static String _label(String key) {
    final text = key.replaceAll('_', ' ');
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}
