/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'dart:convert';

import 'package:flutter_in_store_app_version_checker/src/constants.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Checks published application versions on Google Play, falling back to
/// the third-party PlayStoreApi when the web listing cannot be read.
@internal
final class GooglePlayStore {
  /// Creates a Google Play client.
  const GooglePlayStore(this._httpClient);

  final http.Client _httpClient;

  /// Checks the Google Play listing of [packageName] in [locale].
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
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
          newVersion = _parseVersion(response.body, packageName);
          if (newVersion != null) {
            return InStoreAppVersionCheckerResponse.success(
              currentVersion: currentVersion,
              newVersion: newVersion,
              appURL: uri.toString(),
            );
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

      if (apiResponse.statusCode == 200) {
        final Object? data = jsonDecode(apiResponse.body);
        if (data case {
          'version': String version,
        } when version.trim().isNotEmpty) {
          newVersion = version.trim();
        } else {
          throw const FormatException(
            'PlayStoreApi response does not contain a version.',
          );
        }
        url = 'https://play.google.com/store/apps/details?id=$packageName';
        return InStoreAppVersionCheckerResponse.success(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
        );
      } else {
        return InStoreAppVersionCheckerResponse.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'PlayStoreApi error: ${apiResponse.statusCode} '
              '${apiResponse.reasonPhrase}. '
              'Google Play lookup: $primaryError',
        );
      }
    } on Object catch (e, st) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: e,
        stackTrace: st,
        errorMessage: '$e Google Play lookup: $primaryError',
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
