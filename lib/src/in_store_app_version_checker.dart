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
      final packageName = params.packageName ?? appMetadata.packageName;
      final currentVersion = params.currentVersion ?? appMetadata.version;
      switch (platform) {
        case .android:
          return await switch (params.androidStore) {
            .apkPure => ApkPureStore(
              _httpClient,
            ).checkUpdate(currentVersion, packageName),
            .ruStore => RuStore(
              _httpClient,
            ).checkUpdate(currentVersion, packageName),
            .appGallery => AppGalleryWebStore(_httpClient).checkUpdate(
              currentVersion: currentVersion,
              expectedPackageName: params.packageName,
              locale: params.locale,
              storeID: params.storeID,
            ),
            .appGalleryNative => const AppGalleryNativeStore().checkUpdate(
              currentPackageName: appMetadata.packageName,
              currentVersion: appMetadata.version,
              hasOverrides:
                  params.packageName != null || params.currentVersion != null,
            ),
            .googlePlayStore => GooglePlayStore(
              _httpClient,
            ).checkUpdate(currentVersion, packageName, params.locale),
          };
        case .iOS:
          return await AppleAppStore(
            _httpClient,
          ).checkUpdate(currentVersion, packageName, params.locale);
        default:
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
}
