import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../utils/format.dart';
import 'api_exception.dart';

/// Finds CC-licensed motorcycle photos through the Wikimedia Commons API.
/// Lookups run one at a time and results are cached on the device.
class CommonsImageApi {
  CommonsImageApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _lookups = <String, Future<String?>>{};
  Future<void> _queue = Future.value();

  Future<String?> findImage(String query, {required String mustContain}) =>
      _lookups.putIfAbsent(query, () => _lookup(query, mustContain));

  Future<String?> _lookup(String query, String mustContain) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'commons_image_v1:$query';
    final cached = prefs.getString(cacheKey);
    if (cached != null) return cached.isEmpty ? null : cached;

    final result = Completer<String?>();
    _queue = _queue.then((_) async {
      try {
        result.complete(await _search(query, mustContain));
      } catch (error) {
        result.completeError(error);
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    try {
      final url = await result.future;
      await prefs.setString(cacheKey, url ?? '');
      return url;
    } catch (_) {
      // Allow a retry the next time this bike is shown.
      _lookups.remove(query);
      return null;
    }
  }

  Future<String?> _search(String query, String mustContain) async {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'generator': 'search',
      'gsrnamespace': '6',
      'gsrlimit': '8',
      'gsrsearch': '$query filetype:bitmap',
      'prop': 'imageinfo',
      'iiprop': 'url',
      'iiurlwidth': '960',
    });
    final response = await _client
        .get(uri, headers: AppConfig.identityHeaders)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException('Wikimedia Commons responded ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = List<Map<String, dynamic>>.from(
      ((body['query'] as Map<String, dynamic>?)?['pages'] as List?) ?? const [],
    )..sort((a, b) => ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0));

    final needle = normalizeModel(mustContain);
    for (final page in pages) {
      if (!normalizeModel(page['title'] as String? ?? '').contains(needle)) continue;
      final info = page['imageinfo'] as List?;
      if (info == null || info.isEmpty) continue;
      final first = info.first as Map<String, dynamic>;
      final url = (first['thumburl'] ?? first['url']) as String?;
      if (url != null) return url;
    }
    return null;
  }
}
