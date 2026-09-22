/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 28 October 2025
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_params.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_web_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/ru_store.dart';
import 'package:flutter_in_store_app_version_checker/src/util/app_gallery_native.dart';
import 'package:flutter_in_store_app_version_checker/src/util/app_metadata.dart';
import 'package:http/http.dart' as http;

/// {@template in_store_app_version_checker}
/// [InStoreAppVersionChecker] is an implementation
/// of [IInStoreAppVersionChecker] for checking the current version
/// of an app available in app stores such as `AppStore`, `Google Play`,
/// `ApkPure`, `RuStore`, and `AppGallery`, comparing it with the installed
/// version on the device.
/// It supports both `Android` and `iOS` platforms.
/// {@endtemplate}
final class InStoreAppVersionChecker implements IInStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  InStoreAppVersionChecker._([http.Client? httpClient])
    : _httpClient = httpClient ?? http.Client();

  /// Create a scoped instance of [InStoreAppVersionChecker]
  /// with your own http client.
  /// {@macro in_store_app_version_checker}
  factory InStoreAppVersionChecker.instanceFor({http.Client? httpClient}) =>
      InStoreAppVersionChecker._(httpClient);

  /// Create a scoped instance of [InStoreAppVersionChecker]
  /// with your own http client.
  @Deprecated('Use InStoreAppVersionChecker.instanceFor instead')
  factory InStoreAppVersionChecker.custom({http.Client? httpClient}) =>
      InStoreAppVersionChecker.instanceFor(httpClient: httpClient);

  /// HTTP client used for store requests.
  late final http.Client _httpClient;

  /// Returns the [InStoreAppVersionChecker] singleton instance.
  /// Also registers this with the default http client.
  // ignore: prefer_constructors_over_static_methods
  static InStoreAppVersionChecker get instance =>
      _instance ??= InStoreAppVersionChecker._();

  static InStoreAppVersionChecker? _instance;

  static final RegExp _localePattern = RegExp(
    '^([a-z]{2,3}|[a-z]{5,8})'
    '(?:[-_]([a-z]{4}))?'
    r'(?:[-_]([a-z]{2}|[0-9]{3}))?$',
    caseSensitive: false,
  );

  /// Whether the current platform is iOS.
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the current platform is Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check the current version of the app available in app stores
  /// such as `AppStore`, `Google Play`, `ApkPure`, `RuStore`, and `AppGallery`,
  /// comparing it with the installed version on the device.
  @override
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    InStoreAppVersionCheckerParams params,
  ) async {
    try {
      final appMetadata = await AppMetadata.fromPlatform();
      final packageName = params.packageName ?? appMetadata.packageName;
      final currentVersion = params.currentVersion ?? appMetadata.version;
      if (_isAndroid) {
        return await switch (params.androidStore) {
          InStoreAppVersionCheckerAndroidStoreType.apkPure =>
            _checkPlayStore$ApkPure(currentVersion, packageName),
          InStoreAppVersionCheckerAndroidStoreType.ruStore => _checkRuStore(
            currentVersion,
            packageName,
          ),
          InStoreAppVersionCheckerAndroidStoreType.appGallery =>
            _checkAppGallery(
              currentVersion: currentVersion,
              expectedPackageName: params.packageName,
              locale: params.locale,
              storeID: params.storeID,
            ),
          InStoreAppVersionCheckerAndroidStoreType.appGalleryNative =>
            _checkAppGallery$Native(
              currentPackageName: appMetadata.packageName,
              currentVersion: appMetadata.version,
              hasOverrides:
                  params.packageName != null || params.currentVersion != null,
            ),
          InStoreAppVersionCheckerAndroidStoreType.googlePlayStore =>
            _checkPlayStore(currentVersion, packageName, params.locale),
        };
      } else if (_isIOS) {
        return await _checkAppleStore(
          currentVersion,
          packageName,
          params.locale,
        );
      } else {
        return InStoreAppVersionCheckerResponse.error(
          currentVersion: currentVersion,
          newVersion: null,
          appURL: null,
          errorMessage:
              'This platform is not yet supported by this package. It supports only iOS and Android.',
          stackTrace: StackTrace.current,
          error: Exception('Unsupported platform'),
        );
      }
    } on Object catch (e, s) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: params.currentVersion ?? 'undefined',
        newVersion: null,
        appURL: null,
        error: e,
        stackTrace: s,
        errorMessage: 'Error checking for update: $e',
      );
    }
  }

  /// Check update in [Apple Store].
  Future<InStoreAppVersionCheckerResponse> _checkAppleStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
    try {
      final countryCode = _resolveCountryForAppleStore(locale);
      final uri = Uri.https(
        'itunes.apple.com',
        '/$countryCode/lookup',
        <String, Object?>{
          'bundleId': packageName,
          '_ts': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri);
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
        final jsonObj = jsonDecode(response.body);
        final results = List<Object?>.from(
          jsonObj['results'] as Iterable<Object?>,
        );

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
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
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

  /// Check update in [Play Store].
  Future<InStoreAppVersionCheckerResponse> _checkPlayStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
    try {
      final uri =
          Uri.https('play.google.com', '/store/apps/details', <String, Object?>{
            'id': packageName,
            'hl': _resolveLocaleForGooglePlay(locale),
            '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
          });

      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;

        newVersion = RegExp(
          r',\[\[\["([0-9,\.]*)"]],',
        ).firstMatch(body)?.group(1);

        newVersion ??= RegExp(
          r'\"([0-9]+\.[0-9]+\.[0-9]+)\"',
        ).firstMatch(body)?.group(1);

        if (newVersion != null) {
          return InStoreAppVersionCheckerResponse.success(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: uri.toString(),
          );
        }
      }

      final apiUri = Uri.https(
        'api.playstoreapi.com',
        '/v1.2/apps/$packageName',
      );

      final apiResponse = await _httpClient
          .get(apiUri)
          .timeout(const Duration(seconds: 15));

      if (apiResponse.statusCode == 200) {
        final data = jsonDecode(apiResponse.body);
        newVersion = data['version']?.toString();
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
              'PlayStoreApi error: ${apiResponse.statusCode} ${apiResponse.reasonPhrase}',
        );
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

  String _resolveLocaleForGooglePlay(String locale) {
    final value = locale.trim();
    final match = _localePattern.firstMatch(value);
    if (match == null || match.end != value.length) return locale;

    final scriptCode = match.group(2);
    final countryCode = match.group(3);
    return <String>[
      match.group(1)!.toLowerCase(),
      if (scriptCode != null)
        '${scriptCode[0].toUpperCase()}${scriptCode.substring(1).toLowerCase()}',
      if (countryCode != null) countryCode.toUpperCase(),
    ].join('-');
  }

  String _resolveCountryForAppleStore(String locale) {
    final value = locale.trim();
    final match = _localePattern.firstMatch(value);
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

  /// Check update in [ApkPure Store].
  Future<InStoreAppVersionCheckerResponse> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, url;
    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        return InStoreAppVersionCheckerResponse.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'Cannot find an app in the ApkPure Store with the id: $packageName',
        );
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)?.group(1)?.trim();
        return InStoreAppVersionCheckerResponse.success(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: uri.toString(),
        );
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

  /// Check update in [RuStore].
  Future<InStoreAppVersionCheckerResponse> _checkRuStore(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, url;
    try {
      final listing = await RuStore(_httpClient).getListing(packageName);
      newVersion = listing.version;
      url = listing.appURL;
      return InStoreAppVersionCheckerResponse.success(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
      );
    } on Object catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: error,
        stackTrace: stackTrace,
        errorMessage: error.toString(),
      );
    }
  }

  /// Check an arbitrary application in [AppGallery] by its store ID.
  Future<InStoreAppVersionCheckerResponse> _checkAppGallery({
    required String currentVersion,
    required String locale,
    required String? storeID,
    String? expectedPackageName,
  }) async {
    String? newVersion, url;
    try {
      final resolvedStoreID = storeID?.trim();
      if (resolvedStoreID == null ||
          !RegExp(r'^C\d+$').hasMatch(resolvedStoreID)) {
        throw FormatException(
          'AppGallery web checks require storeID in the format "C107631977".',
          storeID,
        );
      }

      final listing = await AppGalleryWebStore(_httpClient).getListing(
        storeID: resolvedStoreID,
        locale: locale,
        expectedPackageName: expectedPackageName,
      );
      newVersion = listing.version;
      url = listing.appURL;
      return InStoreAppVersionCheckerResponse.success(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
      );
    } on Object catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: error,
        stackTrace: stackTrace,
        errorMessage: error.toString(),
      );
    }
  }

  /// Check the installed application with Huawei `AppUpdateClient`.
  Future<InStoreAppVersionCheckerResponse> _checkAppGallery$Native({
    required String currentPackageName,
    required String currentVersion,
    required bool hasOverrides,
  }) async {
    String? newVersion, url;
    try {
      if (hasOverrides) {
        throw ArgumentError(
          'AppGallery native checks do not support packageName or '
          'currentVersion overrides.',
        );
      }

      final result = await AppGalleryNative.checkUpdate();
      if (result.packageName != null &&
          result.packageName != currentPackageName) {
        throw StateError(
          'Huawei AppUpdateClient returned package "${result.packageName}" '
          'for installed package "$currentPackageName".',
        );
      }

      newVersion = result.version;
      final storeID = result.storeID;
      if (storeID != null) {
        url = Uri(
          scheme: 'https',
          host: 'appgallery.huawei.com',
          path: '/',
          fragment: '/app/$storeID',
        ).toString();
      }
      return InStoreAppVersionCheckerResponse.success(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
      );
    } on Object catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: error,
        stackTrace: stackTrace,
        errorMessage: error.toString(),
      );
    }
  }
}
