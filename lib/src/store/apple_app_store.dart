/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'dart:convert';

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_in_store_app_version_checker/src/util/store_locale.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Checks published application versions through the Apple iTunes lookup API.
@internal
final class AppleAppStore {
  /// Creates an Apple App Store client.
  const AppleAppStore(this._httpClient);

  final http.Client _httpClient;

  /// Checks the App Store storefront selected by [locale] for [packageName].
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
    try {
      final countryCode = _resolveCountry(locale);
      final uri = Uri.https(
        'itunes.apple.com',
        '/$countryCode/lookup',
        <String, Object?>{
          'bundleId': packageName,
          '_ts': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        final countryGuidance = response.statusCode == 400
            ? ' Check the storefront country code. Use a regional locale '
                  'such as "en-US" or a country code such as "us"; '
                  'a language such as "en" does not identify a storefront.'
            : '';
        return InStoreAppVersionCheckerResponse.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'Apple Store lookup failed (HTTP ${response.statusCode}) '
              'for bundle ID "$packageName" in storefront "$countryCode" '
              '(locale: "$locale").$countryGuidance',
        );
      } else {
        final Object? data = jsonDecode(response.body);
        if (data is! Map<String, Object?> ||
            data['results'] is! List<Object?>) {
          throw const FormatException('Apple Store returned invalid results.');
        }
        final results = data['results']! as List<Object?>;

        if (results.isEmpty) {
          return InStoreAppVersionCheckerResponse.error(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
            stackTrace: StackTrace.current,
            errorMessage:
                'App "$packageName" was not found in the Apple Store '
                'storefront "$countryCode" (locale: "$locale"). '
                'Check the bundle ID and availability in this storefront.',
          );
        } else {
          final listing = results.whereType<Map<String, Object?>>().where(
            (item) => item['bundleId'] == packageName,
          );
          if (listing.isEmpty) {
            throw FormatException(
              'Apple Store results do not contain bundle ID "$packageName".',
            );
          }
          final app = listing.first;
          if (app['version'] case final String version
              when version.trim().isNotEmpty) {
            newVersion = version.trim();
          } else {
            throw const FormatException(
              'Apple Store listing does not contain a version.',
            );
          }
          if (app['trackViewUrl'] case final String appURL
              when appURL.trim().isNotEmpty) {
            url = appURL.trim();
          }
          return InStoreAppVersionCheckerResponse.success(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
          );
        }
      }
    } on Object catch (e, st) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: e,
        stackTrace: st,
        errorMessage: e.toString(),
      );
    }
  }

  static String _resolveCountry(String locale) {
    final value = locale.trim();
    final match = storeLocalePattern.firstMatch(value);
    if (match != null && match.end == value.length) {
      final countryCode = match.group(3);
      if (countryCode != null && countryCode.length == 2) {
        return countryCode.toLowerCase();
      }
      if (value.length == 2) return value.toLowerCase();
    }

    throw FormatException(
      'Invalid locale "$locale" for the Apple Store. '
      'Use language-REGION ("en-US"), language-Script-REGION '
      '("zh-Hant-TW"), or a country code ("us"). '
      'A two-letter storefront country is required.',
      locale,
    );
  }
}
