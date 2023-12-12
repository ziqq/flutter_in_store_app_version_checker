// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff
// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Possible types of android store
enum AndroidStore {
  /// The default AAB
  googlePlayStore,

  /// The pure APK
  apkPure
}

/// {@template in_store_app_version_checker}
/// InStoreAppVersionChecker widget.
/// {@endtemplate}
class InStoreAppVersionChecker {
  /// The current version of the app.
  /// Default take the Flutter package version.
  final String? currentVersion;

  /// The locale your app store
  /// Default value is `ru`
  final String? locale;

  /// The id of the app (com.exemple.your_app).
  /// If [appId] is null the [appId] will take the Flutter package identifier.
  final String? appId;

  /// Select The marketplace of your app.
  /// Default will be `AndroidStore.GooglePlayStore`
  final AndroidStore androidStore;

  /// This is http client.
  final http.Client _httpClient;

  /// {@macro in_store_app_version_checker}
  InStoreAppVersionChecker({
    this.appId,
    this.locale = 'ru',
    this.currentVersion,
    this.androidStore = AndroidStore.googlePlayStore,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // ignore: unused_field
  static bool _kIsWeb = false;

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionCheckerResult> checkUpdate() async {
    try {
      if (_isAndroid || _isIOS) {
        _kIsWeb = false;
      } else {
        _kIsWeb = true;
      }
    } catch (e) {
      _kIsWeb = true;
    }

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final String currentVersion = this.currentVersion ?? packageInfo.version;
    final String packageName = appId ?? packageInfo.packageName;

    if (_isAndroid) {
      switch (androidStore) {
        case AndroidStore.apkPure:
          return _checkPlayStoreApkPure(currentVersion, packageName);
        default:
          return _checkPlayStore(currentVersion, packageName);
      }
    } else if (_isIOS) {
      return _checkAppleStore(
        currentVersion,
        packageName,
        locale: locale,
      );
    } else {
      return InStoreAppVersionCheckerResult(
        currentVersion,
        null,
        '',
        'This platform is not yet supported by this package. We support iOS or Android platrforms.',
      );
    }
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionCheckerResult> _checkAppleStore(
    String currentVersion,
    String packageName, {
    String? locale,
  }) async {
    String? errorMsg;
    String? newVersion;
    String? url;

    final uri = Uri.https(
      'itunes.apple.com',
      '/$locale/lookup',
      {'bundleId': packageName},
    );

    try {
      final response = await _httpClient.get(uri);

      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Apple Store with the id: $packageName";
      } else {
        final jsonObj = jsonDecode(response.body);

        final List<dynamic> results = List.from(
          jsonObj['results'] as Iterable<dynamic>,
        );

        if (results.isEmpty) {
          errorMsg =
              "Can't find an app in the Apple Store with the id: $packageName";
        } else {
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
        }
      }
    } catch (e) {
      errorMsg = '$e';
    }
    return InStoreAppVersionCheckerResult(
      currentVersion,
      newVersion,
      url,
      errorMsg,
    );
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionCheckerResult> _checkPlayStore(
    String currentVersion,
    String packageName,
  ) async {
    String? errorMsg;
    String? newVersion;
    String? url;

    final uri = Uri.https(
      'play.google.com',
      '/store/apps/details',
      {'id': packageName},
    );

    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Google Play Store with the id: $packageName";
      } else {
        newVersion = RegExp(r',\[\[\["([0-9,\.]*)"]],')
            .firstMatch(response.body)
            ?.group(1);
        url = uri.toString();
      }
    } catch (e) {
      errorMsg = '$e';
    }

    return InStoreAppVersionCheckerResult(
      currentVersion,
      newVersion,
      url,
      errorMsg,
    );
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionCheckerResult> _checkPlayStoreApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? errorMsg;
    String? newVersion;
    String? url;

    final Uri uri = Uri.https('apkpure.com', '$packageName/$packageName');

    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the ApkPure Store with the id: $packageName";
      } else {
        debugPrint('[DEBUG]: ApkPure | response.body: ${response.body}');

        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)!.group(1)!.trim();
        url = uri.toString();
      }
    } catch (e) {
      errorMsg = '$e';
    }
    return InStoreAppVersionCheckerResult(
      currentVersion,
      newVersion,
      url,
      errorMsg,
    );
  }
}

/// {@template in_store_app_version_checker_result}
/// The result data model for [InStoreAppVersionChecker]
/// {@endtemplate}
class InStoreAppVersionCheckerResult {
  /// return current app version
  final String currentVersion;

  /// return the new app version
  final String? newVersion;

  /// return the app url
  final String? appURL;

  /// return error message if found else it will return `null`
  final String? errorMessage;

  /// {@macro in_store_app_version_checker_result}
  InStoreAppVersionCheckerResult(
    this.currentVersion,
    this.newVersion,
    this.appURL,
    this.errorMessage,
  );

  /// return `true` if update is available
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    final versionNumbersA =
        versionA.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final versionNumbersB =
        versionB.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final int versionASize = versionNumbersA.length;
    final int versionBSize = versionNumbersB.length;
    final int maxSize = math.max(versionASize, versionBSize);

    for (int i = 0; i < maxSize; i++) {
      if ((i < versionASize ? versionNumbersA[i] : 0) >
          (i < versionBSize ? versionNumbersB[i] : 0)) {
        return false;
      } else if ((i < versionASize ? versionNumbersA[i] : 0) <
          (i < versionBSize ? versionNumbersB[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => 'Current Version: $currentVersion\n'
      'New Version: $newVersion\n'
      'App URL: $appURL\n'
      'can update: $canUpdate\n'
      'error: $errorMessage';

  @override
  bool operator ==(covariant InStoreAppVersionCheckerResult other) {
    if (identical(this, other)) return true;

    return other.currentVersion == currentVersion &&
        other.newVersion == newVersion &&
        other.appURL == appURL &&
        other.errorMessage == errorMessage;
  }

  // coverage:ignore-start
  @override
  int get hashCode {
    return currentVersion.hashCode ^
        newVersion.hashCode ^
        appURL.hashCode ^
        errorMessage.hashCode;
  }
  // coverage:ignore-end
}
