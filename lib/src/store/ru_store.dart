/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads published application versions from public RuStore catalog pages.
final class RuStore {
  /// Creates a RuStore client.
  const RuStore(this._httpClient);

  static const _timeout = Duration(seconds: 15);
  static final _jsonLDPattern = RegExp(
    r'''<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>''',
    caseSensitive: false,
    dotAll: true,
  );

  final http.Client _httpClient;

  /// Returns the version published for [packageName].
  Future<({String appURL, String version})> getListing(
    String packageName,
  ) async {
    final uri = Uri.https('www.rustore.ru', '/catalog/app/$packageName');
    final response = await _httpClient.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'RuStore listing request failed (HTTP ${response.statusCode}) '
        'for package "$packageName".',
        uri,
      );
    }

    FormatException? decodeError;
    for (final match in _jsonLDPattern.allMatches(response.body)) {
      final source = match.group(1);
      if (source == null) continue;
      try {
        final Object? value = jsonDecode(source);
        final listing = _findSoftwareApplication(value);
        final version = listing?['softwareVersion']?.toString().trim();
        if (version != null && version.isNotEmpty) {
          return (appURL: uri.toString(), version: version);
        }
      } on FormatException catch (error) {
        decodeError = error;
      }
    }

    if (decodeError != null) throw decodeError;
    throw FormatException(
      'RuStore listing "$packageName" does not contain '
      'SoftwareApplication.softwareVersion.',
      response.body,
    );
  }

  static Map<String, Object?>? _findSoftwareApplication(Object? value) {
    switch (value) {
      case final Map<String, Object?> map:
        if (_isSoftwareApplicationType(map['@type'])) {
          return map;
        }
        for (final child in map.values) {
          final listing = _findSoftwareApplication(child);
          if (listing != null) return listing;
        }
      case final Iterable<Object?> values:
        for (final child in values) {
          final listing = _findSoftwareApplication(child);
          if (listing != null) return listing;
        }
    }
    return null;
  }

  static bool _isSoftwareApplicationType(Object? value) => switch (value) {
    'SoftwareApplication' => true,
    final Iterable<Object?> values => values.contains('SoftwareApplication'),
    _ => false,
  };
}
