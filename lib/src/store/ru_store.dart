/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'dart:convert';

import 'package:flutter_in_store_app_version_checker/src/store/app_store.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Reads published application versions from public RuStore catalog pages.
@internal
final class AppStore$RuStore implements AppStore {
  /// Creates a RuStore client.
  const AppStore$RuStore(this._httpClient);

  static const _timeout = Duration(seconds: 15);
  static final _jsonLDPattern = RegExp(
    r'''<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>''',
    caseSensitive: false,
    dotAll: true,
  );

  final http.Client _httpClient;

  @override
  String get name => 'RuStore';

  /// Reads the RuStore catalog page of `packageName`.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  ) async {
    final listing = await _getListing(request.packageName);
    return (version: listing.version, appURL: listing.appURL);
  }

  /// Returns the version published for [packageName].
  Future<({String appURL, String version})> _getListing(
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

  static Map<String, Object?>? _findSoftwareApplication(Object? value) =>
      switch (value) {
        Map<String, Object?> map
            when _isSoftwareApplicationType(map['@type']) =>
          map,
        Map<String, Object?> map => _findFirstSoftwareApplication(map.values),
        Iterable<Object?> values => _findFirstSoftwareApplication(values),
        _ => null,
      };

  /// Returns the first `SoftwareApplication` found in [values], searching lazily.
  static Map<String, Object?>? _findFirstSoftwareApplication(
    Iterable<Object?> values,
  ) => values.map(_findSoftwareApplication).nonNulls.firstOrNull;

  static bool _isSoftwareApplicationType(Object? value) => switch (value) {
    'SoftwareApplication' => true,
    Iterable<Object?> values => values.contains('SoftwareApplication'),
    _ => false,
  };
}
