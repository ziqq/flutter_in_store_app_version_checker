/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 28 October 2025
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_params.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_in_store_app_version_checker/src/store/apk_pure_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_native_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_web_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/apple_app_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/google_play_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/ru_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_extension.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
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

  /// Check the current version of the app available in app stores
  /// such as `AppStore`, `Google Play`, `ApkPure`, `RuStore`, and `AppGallery`,
  /// comparing it with the installed version on the device.
  @override
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    InStoreAppVersionCheckerParams params,
  ) async {
    try {
      final platform = defaultTargetPlatform;
      final isAppGalleryNative =
          platform == .android && params.androidStore == .appGalleryNative;
      // HTTP checks skip installed-app metadata when both overrides are set;
      // AppGallery native always checks the installed application.
      final appMetadata = switch ((params.packageName, params.currentVersion)) {
        (String packageName, String version) when !isAppGalleryNative => (
          packageName: packageName,
          version: version,
        ),
        _ => await AppMetadata.fromPlatform(),
      };
      // AppGallery native always reports the installed application.
      final request = StoreRequest(
        currentVersion: isAppGalleryNative
            ? appMetadata.version
            : params.currentVersion ?? appMetadata.version,
        packageName: isAppGalleryNative
            ? appMetadata.packageName
            : params.packageName ?? appMetadata.packageName,
        locale: params.locale,
        storeID: params.storeID,
        expectedPackageName: params.packageName,
        hasOverrides:
            params.packageName != null || params.currentVersion != null,
      );
      final store = switch (platform) {
        .android => switch (params.androidStore) {
          .googlePlayStore => Store$GooglePlay(_httpClient),
          .apkPure => Store$ApkPure(_httpClient),
          .ruStore => Store$RuStore(_httpClient),
          .appGallery => Store$AppGalleryWeb(_httpClient),
          .appGalleryNative => const Store$AppGalleryNative(),
        },
        .iOS => Store$AppStore(_httpClient),
        _ => null,
      };
      return await switch (store) {
        IStore store => store.checkUpdate(request),
        null => Future.value(
          InStoreAppVersionCheckerResponse.error(
            currentVersion: request.currentVersion,
            errorMessage:
                'This platform is not yet supported by this package. It supports only iOS and Android.',
            stackTrace: StackTrace.current,
            error: Exception('Unsupported platform'),
          ),
        ),
      };
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
}
