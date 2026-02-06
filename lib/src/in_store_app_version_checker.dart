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

/// {@template in_store_app_version_checker}
/// [InStoreAppVersionChecker] is an implementation
/// of [IInStoreAppVersionChecker] for checking the current version
/// of an app available in app stores such as `AppStore`, `Google Play`
/// and `ApkPure`, comparing it with the installed version on the device.
/// It supports both `Android` and `iOS` platforms.
/// {@endtemplate}
final class InStoreAppVersionChecker implements IInStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  InStoreAppVersionChecker._([
    http.Client? httpClient,
  ]) : _httpClient = httpClient ?? http.Client();

  /// Create custom instance of [InStoreAppVersionChecker]
  /// with your own http client.
  /// {@macro in_store_app_version_checker}
  factory InStoreAppVersionChecker.custom({
    http.Client? httpClient,
  }) =>
      InStoreAppVersionChecker._(httpClient);

  /// This is http client.
  late final http.Client _httpClient;

  /// Returns the [InStoreAppVersionChecker] singleton instance.
  /// Also registers this with the default http client.
  // ignore: prefer_constructors_over_static_methods
  static InStoreAppVersionChecker get instance =>
      _instance ??= InStoreAppVersionChecker._();

  static InStoreAppVersionChecker? _instance;

  /// Whether the current platform is iOS.
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the current platform is Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check the current version of the app available in app stores
  /// such as `AppStore`, `Google Play` and `ApkPure`,
  /// comparing it with the installed version on the device.
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
        return InStoreAppVersionChecker$Response.error(
          currentVersion: currentVersion,
          newVersion: null,
          appURL: null,
          errorMessage:
              'This platform is not yet supported by this package. Support only iOS or Android platrforms.',
          stackTrace: StackTrace.current,
          error: Exception('Unsupported platform'),
        );
      }
    } on Object catch (e, s) {
      return InStoreAppVersionChecker$Response.error(
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
  Future<InStoreAppVersionChecker$Response> _checkAppleStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
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
        return InStoreAppVersionChecker$Response.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'Can not find an app in the Apple Store with the id: $packageName',
        );
      } else {
        final jsonObj = jsonDecode(response.body);
        final results =
            List<Object?>.from(jsonObj['results'] as Iterable<Object?>);

        if (results.isEmpty) {
          return InStoreAppVersionChecker$Response.error(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
            stackTrace: StackTrace.current,
            errorMessage:
                'Can not find an app in the Apple Store with the id: $packageName',
          );
        } else {
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
          return InStoreAppVersionChecker$Response.success(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
          );
        }
      }
    } on Object catch (e, st) {
      return InStoreAppVersionChecker$Response.error(
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
  Future<InStoreAppVersionChecker$Response> _checkPlayStore(
    String currentVersion,
    String packageName,
    String locale,
  ) async {
    String? newVersion, url;
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
          return InStoreAppVersionChecker$Response.success(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: uri.toString(),
          );
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
          return InStoreAppVersionChecker$Response.success(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
          );
        } else {
          return InStoreAppVersionChecker$Response.error(
            currentVersion: currentVersion,
            newVersion: newVersion,
            appURL: url,
            stackTrace: StackTrace.current,
            errorMessage:
                'PlayStoreApi error: ${apiResponse.statusCode} ${apiResponse.reasonPhrase}',
          );
        }
      }

      return InStoreAppVersionChecker$Response.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        stackTrace: StackTrace.current,
        errorMessage:
            'Can not find an app in the Play Store with the id: $packageName',
      );
    } on Object catch (e, st) {
      return InStoreAppVersionChecker$Response.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: e,
        stackTrace: st,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check update in [ApkPure Store].
  Future<InStoreAppVersionChecker$Response> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, url;
    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        return InStoreAppVersionChecker$Response.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'Can not find an app in the ApkPure Store with the id: $packageName',
        );
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)?.group(1)?.trim();
        return InStoreAppVersionChecker$Response.success(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: uri.toString(),
        );
      }
    } on Object catch (e, st) {
      return InStoreAppVersionChecker$Response.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: e,
        stackTrace: st,
        errorMessage: e.toString(),
      );
    }
  }
}
