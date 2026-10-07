/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:meta/meta.dart';

/// Checks the installed Android application through Huawei `AppUpdateClient`.
@internal
final class AppGalleryNativeStore {
  /// Creates an AppGallery native client.
  const AppGalleryNativeStore();

  static const _channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  /// Shared in-flight native check, so concurrent calls from any checker
  /// instance reuse a single `AppUpdateClient` request.
  static Future<({String? packageName, String? storeID, String? version})>?
  _pendingCheck;

  /// Checks AppGallery for an update to the installed application.
  Future<InStoreAppVersionCheckerResponse> checkUpdate({
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

      final result = await (_pendingCheck ??= _invokeNative().whenComplete(() {
        _pendingCheck = null;
      }));
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

  static Future<({String? packageName, String? storeID, String? version})>
  _invokeNative() async {
    final data = await _channel
        .invokeMapMethod<String, Object?>('checkAppGalleryUpdate')
        .timeout(const Duration(seconds: 20));
    if (data == null) {
      throw PlatformException(
        code: 'invalid_app_gallery_response',
        message: 'Huawei AppUpdateClient returned no result.',
      );
    }

    String? read(String key) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return (
      packageName: read('packageName'),
      storeID: read('storeID'),
      version: read('version'),
    );
  }
}
