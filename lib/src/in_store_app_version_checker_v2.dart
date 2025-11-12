/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 28 October 2025
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_params.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// {@template in_store_app_version_checker_v2}
/// [InStoreAppVersionCheckerV2] is an interface for checking the current version
/// of an app available in app stores such as Google Play and ApkPure,
/// comparing it with the installed version on the device.
/// It supports both Android and iOS platforms.
/// {@endtemplate}
final class InStoreAppVersionCheckerV2 implements IInStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  InStoreAppVersionCheckerV2._([
    http.Client? httpClient,
  ]) : _httpClient = httpClient ?? http.Client();

  /// Create custom instance of [InStoreAppVersionCheckerV2]
  /// with your own http client.
  /// {@macro in_store_app_version_checker}
  factory InStoreAppVersionCheckerV2.custom({
    http.Client? httpClient,
  }) =>
      InStoreAppVersionCheckerV2._(httpClient);

  /// This is http client.
  late final http.Client _httpClient;

  static InStoreAppVersionCheckerV2? _instance;

  /// Returns the [InStoreAppVersionChecker] singleton instance.
  /// Also registers this with the default http client.
  // ignore: prefer_constructors_over_static_methods
  static InStoreAppVersionCheckerV2 get instance =>
      _instance ??= InStoreAppVersionCheckerV2._();

  /// Whether the current platform is iOS.
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the current platform is Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check update current store type.
  @override
  Future<InStoreAppVersionChecker$Response> checkUpdate(
    InStoreAppVersionChecker$Params params,
  ) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = params.packageName ?? packageInfo.packageName;
      final currentVersion = params.currentVersion ?? packageInfo.version;
      if (_isAndroid) {
        return await switch (params.androidStore) {
          InStoreAppVersionChecker$AndroidStore.apkPure =>
            _checkPlayStore$ApkPure(currentVersion, packageName),
          _ => _checkPlayStore(currentVersion, packageName, params.locale),
        };
      } else if (_isIOS) {
        return await _checkAppleStore(
          currentVersion,
          packageName,
          params.locale,
        );
      } else {
        return InStoreAppVersionChecker$Response(
          currentVersion: currentVersion,
          newVersion: null,
          appURL: '',
          errorMessage:
              'This platform is not yet supported by this package. Support only iOS or Android platrforms.',
          stackTrace: StackTrace.current,
        );
      }
    } on Object catch (e, s) {
      Error.throwWithStackTrace(e, s);
    }
  }

  /// Check update in Apple Store.
  Future<InStoreAppVersionChecker$Response> _checkAppleStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, errorMessage, url;
    StackTrace? stackTrace;
    Object? error;

    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/$locale/lookup',
        <String, Object?>{
          'bundleId': packageName,
          '_ts': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMessage =
            "Can't find an app in the Apple Store with the id: $packageName";
      } else {
        final jsonObj = jsonDecode(response.body);
        final results =
            List<Object?>.from(jsonObj['results'] as Iterable<Object?>);

        if (results.isEmpty) {
          errorMessage =
              "Can't find an app in the Apple Store with the id: $packageName";
        } else {
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
        }
      }
    } on Object catch (e, st) {
      errorMessage = '$e';
      stackTrace = st;
      error = e;
    }
    return InStoreAppVersionChecker$Response(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      error: error,
      stackTrace: stackTrace,
      errorMessage: errorMessage,
    );
  }

  /// Check update in Play Store.
  Future<InStoreAppVersionChecker$Response> _checkPlayStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, errorMessage, url;
    StackTrace? stackTrace;
    Object? error;

    try {
      final uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        <String, Object?>{
          'id': packageName,
          'hl': locale,
          '_ts': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMessage =
            'Can not find an app in the Google Play Store with the id: $packageName';
      } else {
        newVersion = RegExp(r',\[\[\["([0-9,\.]*)"]],')
            .firstMatch(response.body)
            ?.group(1);
        url = uri.toString();
      }
    } on Object catch (e, st) {
      errorMessage = '$e';
      stackTrace = st;
      error = e;
    }
    return InStoreAppVersionChecker$Response(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      error: error,
      stackTrace: stackTrace,
      errorMessage: errorMessage,
    );
  }

  /// Check update in ApkPure Store.
  Future<InStoreAppVersionChecker$Response> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMessage, url;
    StackTrace? stackTrace;
    Object? error;

    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMessage =
            'Can not find an app in the ApkPure Store with the id: $packageName';
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)!.group(1)!.trim();
        url = uri.toString();
      }
    } on Object catch (e, st) {
      errorMessage = '$e';
      stackTrace = st;
      error = e;
    }
    return InStoreAppVersionChecker$Response(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      error: error,
      stackTrace: stackTrace,
      errorMessage: errorMessage,
    );
  }
}
