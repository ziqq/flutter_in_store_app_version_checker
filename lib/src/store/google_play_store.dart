/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'dart:convert';

import 'package:flutter_in_store_app_version_checker/src/constants.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_store.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Reads published application versions on Google Play, falling back to
/// the third-party PlayStoreApi when the web listing cannot be read.
@internal
final class AppStore$GooglePlay implements AppStore {
  /// Creates a Google Play client.
  const AppStore$GooglePlay(this._httpClient);

  final http.Client _httpClient;

  @override
  String get name => 'Google Play';

  /// Reads the Google Play listing of `packageName` in `locale`.
  ///
  /// Failures after the primary lookup are reported together with the
  /// primary lookup error.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  ) async {
    final AppStoreRequest(:packageName, :locale) = request;
    Object? primaryError;
    try {
      final uri =
          Uri.https('play.google.com', '/store/apps/details', <String, Object?>{
            'id': packageName,
            'hl': _resolveLocale(locale),
            '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
          });

      try {
        final response = await _httpClient
            .get(uri)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          if (_parseVersion(response.body, packageName) case String version) {
            return (version: version, appURL: uri.toString());
          }
          primaryError = const FormatException(
            'Google Play listing does not contain a version.',
          );
        } else {
          primaryError = http.ClientException(
            'Google Play lookup failed (HTTP ${response.statusCode}).',
            uri,
          );
        }
      } on Object catch (error) {
        primaryError = error;
      }

      final apiUri = Uri.https(
        'api.playstoreapi.com',
        '/v1.2/apps/$packageName',
      );
      final apiResponse = await _httpClient
          .get(apiUri)
          .timeout(const Duration(seconds: 15));
      if (apiResponse.statusCode != 200) {
        throw AppStoreLookupException(
          'PlayStoreApi error: ${apiResponse.statusCode} '
          '${apiResponse.reasonPhrase}. '
          'Google Play lookup: $primaryError',
        );
      }
      return (
        version: switch (jsonDecode(apiResponse.body)) {
          {'version': String version} when version.trim().isNotEmpty =>
            version.trim(),
          _ => throw const FormatException(
            'PlayStoreApi response does not contain a version.',
          ),
        },
        appURL: 'https://play.google.com/store/apps/details?id=$packageName',
      );
    } on AppStoreLookupException {
      rethrow;
    } on Object catch (error) {
      throw AppStoreLookupException(
        '$error Google Play lookup: $primaryError',
        cause: error,
      );
    }
  }

  static String? _parseVersion(String body, String packageName) {
    final source = RegExp(
      r"AF_initDataCallback\(\{key:\s*'ds:5',\s*hash:\s*'[^']*',"
      r'\s*data:(.*?),\s*sideChannel:',
      dotAll: true,
    ).firstMatch(body)?.group(1);
    if (source == null) return null;
    final Object? data = jsonDecode(source);
    if (_readValue(data, const [1, 2, 77, 0]) != packageName) {
      return null;
    }
    // Google Play uses both indexed arrays and sparse fields in its web data.
    for (final field in const [141, 140]) {
      final value = _readValue(data, [1, 2, field, 0, 0, 0]);
      if (value case String version when version.trim().isNotEmpty) {
        return version.trim();
      }
    }
    return null;
  }

  static Object? _readValue(Object? data, List<int> path) => path.fold(
    data,
    (value, index) => switch (value) {
      List<Object?> fields when index < fields.length => fields[index],
      List<Object?>(lastOrNull: Map<String, Object?> sparse) =>
        sparse['$index'],
      Map<String, Object?> fields => fields['$index'],
      _ => null,
    },
  );

  static String _resolveLocale(String locale) {
    final value = locale.trim();
    final match = kStoreLocalePattern.firstMatch(value);
    if (match == null || match.end != value.length) return locale;

    return switch (match.groups(const [1, 2, 3])) {
      [String languageCode, String? scriptCode, String? countryCode] => <String>[
        languageCode.toLowerCase(),
        if (scriptCode != null)
          '${scriptCode[0].toUpperCase()}${scriptCode.substring(1).toLowerCase()}',
        if (countryCode != null) countryCode.toUpperCase(),
      ].join('-'),
      _ => locale,
    };
  }
}
