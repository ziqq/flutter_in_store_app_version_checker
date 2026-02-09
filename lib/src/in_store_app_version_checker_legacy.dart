// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker.dart'
    as new_impl;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// {@template android_store}
/// Possible types of android store
/// {@endtemplate}
enum AndroidStore {
  /// The default AAB
  googlePlayStore,

  /// The pure APK
  apkPure
}

/// {@template in_store_app_version_checker_result}
/// The result of check app version in AppStore or GooglePlay.
/// {@endtemplate}
@immutable
class InStoreAppVersionCheckerResult {
  /// {@macro in_store_app_version_checker_result}
  const InStoreAppVersionCheckerResult({
    required this.currentVersion,
    this.newVersion,
    this.appURL,
    this.errorMessage,
    this.stackTrace,
  });

  /// Return current app version
  final String currentVersion;

  /// Return the new app version
  final String? newVersion;

  /// Return the app url
  final String? appURL;

  /// Return error message if found else it will return `null`
  final String? errorMessage;

  /// Return error stack trace
  final StackTrace? stackTrace;

  /// Check can update app.
  /// Return `true` if update is available else `false`
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    var $versionA = versionA.trim();
    var $versionB = versionB.trim();

    String normalize(String v) =>
        v.split('+').first.replaceAll(RegExp(r'[^0-9a-zA-Z\.\-]'), '');

    $versionA = normalize($versionA);
    $versionB = normalize($versionB);

    final partsA = $versionA.split('-');
    final partsB = $versionB.split('-');

    final coreA = partsA.first;
    final coreB = partsB.first;
    final preA = partsA.length > 1 ? partsA.sublist(1).join('-') : null;
    final preB = partsB.length > 1 ? partsB.sublist(1).join('-') : null;

    final numsA = coreA
        .split('.')
        .map(int.tryParse)
        .map((e) => e ?? 0)
        .toList(growable: false);
    final numsB = coreB
        .split('.')
        .map(int.tryParse)
        .map((e) => e ?? 0)
        .toList(growable: false);

    final maxLen = math.max(numsA.length, numsB.length);
    for (int i = 0; i < maxLen; i++) {
      final a = i < numsA.length ? numsA[i] : 0;
      final b = i < numsB.length ? numsB[i] : 0;
      if (a > b) return false;
      if (a < b) return true;
    }

    if (preA != null && preB == null) return false; // 1.0.0-beta < 1.0.0
    if (preA == null && preB != null) return true; // 1.0.0 < 1.0.0-beta
    if (preA != null && preB != null) {
      final result = preA.compareTo(preB);
      if (result < 0) return true;
      if (result > 0) return false;
    }

    return false;
  }

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('Current version: $currentVersion')
      ..writeln('New version: $newVersion')
      ..writeln('App url: $appURL')
      ..writeln('Can update: $canUpdate');
    if (errorMessage != null) buffer.write('Error: $errorMessage');
    if (stackTrace != null) buffer.write('Stack trace: $stackTrace');
    return buffer.toString();
  }

  @override
  bool operator ==(covariant InStoreAppVersionCheckerResult other) {
    if (identical(this, other)) return true;
    return other.currentVersion == currentVersion &&
        other.newVersion == newVersion &&
        other.appURL == appURL &&
        other.canUpdate == canUpdate &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode =>
      currentVersion.hashCode ^
      newVersion.hashCode ^
      appURL.hashCode ^
      errorMessage.hashCode;
}

/// {@template in_store_app_version_checker}
/// [InStoreAppVersionChecker] is an interface for checking the current version
/// of an app available in app stores such as Google Play and ApkPure,
/// comparing it with the installed version on the device.
/// It supports both Android and iOS platforms.
///
/// Properties:
/// - [appId]: The app's identifier (if not provided, Flutter's app ID is used).
/// - [locale]: The language/locale of the app store (default is "ru").
/// - [currentVersion]: The current version of the app (if not provided, it is fetched from Flutter).
/// - [androidStore]: Specifies the Android app store (Google Play or ApkPure).
/// - [httpClient]: A custom HTTP client for making API requests.
///
/// Methods:
/// - `checkUpdate()`: Checks for app updates in the selected app store.
///
/// This class simplifies the process of checking for app updates by automating API
/// requests to app stores and is compatible with popular mobile platforms.
/// {@endtemplate}
abstract interface class InStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  @Deprecated('Use InStoreAppVersionChecker.instance')
  factory InStoreAppVersionChecker({
    String? appId,
    String? locale,
    String? currentVersion,
    http.Client? httpClient,
    AndroidStore? androidStore,
  }) = _InStoreAppVersionCheckerImpl;

  /// Returns the singleton instance of [InStoreAppVersionCheckerV2].
  static IInStoreAppVersionChecker get instance =>
      new_impl.InStoreAppVersionChecker.instance;

  /// The id of the app (com.exemple.your_app).
  /// If [appId] is null the [appId] will take the Flutter package identifier.
  String? get appId;

  /// The locale your app store
  /// Default value is `ru`
  String? get locale;

  /// The current version of the app.
  /// Default take the Flutter package version.
  String? get currentVersion;

  /// Select The marketplace of your app.
  /// Default will be `AndroidStore.GooglePlayStore`
  AndroidStore? get androidStore;

  /// Check update current store type.
  @Deprecated('Use InStoreAppVersionChecker.instance.checkUpdate()')
  Future<InStoreAppVersionCheckerResult> checkUpdate();
}

/// {@macro in_store_app_version_checker}
@Deprecated('Use InStoreAppVersionChecker.instance')
final class _InStoreAppVersionCheckerImpl implements InStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  @Deprecated('Use InStoreAppVersionChecker.instance')
  _InStoreAppVersionCheckerImpl({
    this.appId,
    this.locale = 'ru',
    this.currentVersion,
    this.androidStore = AndroidStore.googlePlayStore,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// The android store type of the app to check.
  /// Default `InStoreAppVersionChecker$AndroidStore.GooglePlayStore`.
  @override
  final AndroidStore? androidStore;

  /// The current version of the app.
  /// If [currentVersion] is null, it is taked from the Flutter package version.
  @override
  final String? currentVersion;

  /// The locale your app store.
  @override
  final String? locale;

  /// The id of the app (com.exemple.your_app).
  /// If [appId] is null the [appId] will take the Flutter package identifier.
  @override
  final String? appId;

  /// This is http client.
  late final http.Client _httpClient;

  /// Whether the current platform is iOS.
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the current platform is Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check update current store type.
  @override
  Future<InStoreAppVersionCheckerResult> checkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = appId ?? packageInfo.packageName;
    final currentVersion = this.currentVersion ?? packageInfo.version;
    if (_isAndroid) {
      return await switch (androidStore) {
        AndroidStore.apkPure =>
          _checkPlayStore$ApkPure(currentVersion, packageName),
        _ => _checkPlayStoreV2(currentVersion, packageName),
      };
    } else if (_isIOS) {
      return await _checkAppleStore(
        currentVersion,
        packageName,
        locale: locale,
      );
    } else {
      return InStoreAppVersionCheckerResult(
        currentVersion: currentVersion,
        newVersion: null,
        appURL: null,
        errorMessage:
            'This platform is not yet supported by this package. We support iOS or Android platforms.',
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Check update in Apple Store.
  Future<InStoreAppVersionCheckerResult> _checkAppleStore(
    String currentVersion,
    String packageName, {
    String? locale,
  }) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/$locale/lookup',
        {
          'bundleId': packageName,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Apple Store with the id: $packageName";
      } else {
        final jsonObj = jsonDecode(response.body);
        final results =
            List<dynamic>.from(jsonObj['results'] as Iterable<dynamic>);

        if (results.isEmpty) {
          errorMsg =
              "Can't find an app in the Apple Store with the id: $packageName";
        } else {
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
        }
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    return InStoreAppVersionCheckerResult(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }

  /// Check update in Play Store.
  /* Future<InStoreAppVersionCheckerResult> _checkPlayStore(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        {
          'id': packageName,
          'hl': locale,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri, headers: {
        if (locale != null && locale!.isNotEmpty) 'Accept-Language': locale!
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Google Play Store with the id: $packageName";
      } else {
        newVersion = RegExp(r',\[\[\["([0-9,\.]*)"]],')
            .firstMatch(response.body)
            ?.group(1);
        url = uri.toString();
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    if (newVersion == null && errorMsg == null) {
      errorMsg = 'Unable to parse version for package $packageName';
    }
    return InStoreAppVersionCheckerResult(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  } */

  /// Check update in Play Store.
  Future<InStoreAppVersionCheckerResult> _checkPlayStoreV2(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;
    try {
      final uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        <String, Object?>{
          'id': packageName,
          'hl': locale,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;

        newVersion =
            RegExp(r',\[\[\["([0-9,\.]*)"]],').firstMatch(body)?.group(1);

        newVersion ??=
            RegExp(r'\"([0-9]+\.[0-9]+\.[0-9]+)\"').firstMatch(body)?.group(1);

        if (newVersion != null) {
          url = uri.toString();
        }
      }

      if (newVersion == null) {
        final apiUri = Uri.https(
          'api.playstoreapi.com',
          '/v1.2/apps/$packageName',
        );

        final apiResponse =
            await _httpClient.get(apiUri).timeout(const Duration(seconds: 15));
        if (apiResponse.statusCode == 200) {
          final data = jsonDecode(apiResponse.body);
          newVersion = data['version']?.toString();
          url = 'https://play.google.com/store/apps/details?id=$packageName';
        } else {
          errorMsg =
              'PlayStoreApi error: ${apiResponse.statusCode} ${apiResponse.reasonPhrase}';
        }
      }

      if (newVersion == null) {
        errorMsg ??=
            'Cannot find version info for $packageName — possibly new Play UI or region restriction.';
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }

    return InStoreAppVersionCheckerResult(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }

  /// Check update in ApkPure Store.
  Future<InStoreAppVersionCheckerResult> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the ApkPure Store with the id: $packageName";
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)!.group(1)!.trim();
        url = uri.toString();
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    return InStoreAppVersionCheckerResult(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }
}
