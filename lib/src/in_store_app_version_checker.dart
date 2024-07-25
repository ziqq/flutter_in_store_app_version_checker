// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/src/model/in_store_app_version_checker_result.dart';
import 'package:flutter_in_store_app_version_checker/src/model/pubspec.yaml.g.dart';
import 'package:http/http.dart' as http;

/// Possible types of android store
enum AndroidStore {
  /// The default AAB
  googlePlayStore,

  /// The pure APK
  apkPure
}

/// {@template in_store_app_version_checker}
/// InStoreAppVersionChecker
/// {@endtemplate}
abstract interface class InStoreAppVersionChecker {
  factory InStoreAppVersionChecker({
    String? appId,
    String? locale,
    String? currentVersion,
    AndroidStore? androidStore,
  }) = _InStoreAppVersionCheckerImpl;

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

  /// The overriden http client.
  void setHttpClient(http.Client client);

  /// Check update current store type.
  Future<InStoreAppVersionCheckerResult> checkUpdate();
}

/// {@template in_store_app_version_checker}
/// InStoreAppVersionChecker implementation
/// {@endtemplate}
final class _InStoreAppVersionCheckerImpl implements InStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  _InStoreAppVersionCheckerImpl({
    this.appId,
    this.locale = 'ru',
    this.currentVersion,
    this.androidStore = AndroidStore.googlePlayStore,
  }) : _httpClient = http.Client();

  @override
  final AndroidStore? androidStore;

  @override
  final String? currentVersion;

  @override
  final String? locale;

  @override
  final String? appId;

  @override
  void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// This is http client.
  late http.Client _httpClient;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // ignore: unused_field
  static bool _kIsWeb = false;

  /// {@macro in_store_app_version_checker}
  @override
  Future<InStoreAppVersionCheckerResult> checkUpdate() async {
    try {
      if (_isAndroid || _isIOS) {
        _kIsWeb = false;
      } else {
        _kIsWeb = true;
      }
    } on Object catch (_, __) {
      _kIsWeb = true;
    }

    final packageName = appId ?? Pubspec.name;
    final currentVersion = this.currentVersion ?? Pubspec.version.canonical;

    if (_isAndroid) {
      return await switch (androidStore) {
        AndroidStore.apkPure =>
          _checkPlayStore$ApkPure(currentVersion, packageName),
        _ => _checkPlayStore(currentVersion, packageName),
      };
    } else if (_isIOS) {
      return await _checkAppleStore(
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

    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/$locale/lookup',
        {'bundleId': packageName},
      );
      final response = await _httpClient.get(uri);
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
    } on Object catch (error, __) {
      errorMsg = '$error';
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
    String? newVersion;
    String? errorMsg;
    String? url;

    try {
      final uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        {'id': packageName},
      );
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
    } on Object catch (error, __) {
      errorMsg = '$error';
    }
    return InStoreAppVersionCheckerResult(
      currentVersion,
      newVersion,
      url,
      errorMsg,
    );
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionCheckerResult> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion;
    String? errorMsg;
    String? url;

    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the ApkPure Store with the id: $packageName";
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)!.group(1)!.trim();
        url = uri.toString();
      }
    } on Object catch (error, __) {
      errorMsg = '$error';
    }
    return InStoreAppVersionCheckerResult(
      currentVersion,
      newVersion,
      url,
      errorMsg,
    );
  }
}
