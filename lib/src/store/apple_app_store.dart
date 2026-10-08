/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'dart:convert';

import 'package:flutter_in_store_app_version_checker/src/constants.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_store.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Reads published application versions through the Apple iTunes lookup API.
@internal
final class AppStore$Apple implements AppStore {
  /// Creates an Apple App Store client.
  const AppStore$Apple(this._httpClient);

  final http.Client _httpClient;

  @override
  String get name => 'Apple App Store';

  /// Reads the listing of `packageName` in the storefront selected by `locale`.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  ) async {
    final AppStoreRequest(:packageName, :locale) = request;
    final countryCode = _resolveCountry(locale);
    final uri =
        Uri.https('itunes.apple.com', '/$countryCode/lookup', <String, Object?>{
          'bundleId': packageName,
          '_ts': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        });
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      final countryGuidance = response.statusCode == 400
          ? ' Check the storefront country code. Use a regional locale '
                'such as "en-US" or a country code such as "us"; '
                'a language such as "en" does not identify a storefront.'
          : '';
      throw AppStoreLookupException(
        'Apple Store lookup failed (HTTP ${response.statusCode}) '
        'for bundle ID "$packageName" in storefront "$countryCode" '
        '(locale: "$locale").$countryGuidance',
      );
    }

    final results = switch (jsonDecode(response.body)) {
      {'results': List<Object?> results} => results,
      _ => throw const FormatException('Apple Store returned invalid results.'),
    };
    if (results.isEmpty) {
      throw AppStoreLookupException(
        'App "$packageName" was not found in the Apple Store '
        'storefront "$countryCode" (locale: "$locale"). '
        'Check the bundle ID and availability in this storefront.',
      );
    }

    final app = results
        .whereType<Map<String, Object?>>()
        .where((item) => item['bundleId'] == packageName)
        .firstOrNull;
    if (app == null) {
      throw FormatException(
        'Apple Store results do not contain bundle ID "$packageName".',
      );
    }
    return (
      version: switch (app['version']) {
        String version when version.trim().isNotEmpty => version.trim(),
        _ => throw const FormatException(
          'Apple Store listing does not contain a version.',
        ),
      },
      appURL: switch (app['trackViewUrl']) {
        String appURL when appURL.trim().isNotEmpty => appURL.trim(),
        _ => null,
      },
    );
  }

  static String _resolveCountry(String locale) {
    final value = locale.trim();
    final match = kStoreLocalePattern.firstMatch(value);
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
