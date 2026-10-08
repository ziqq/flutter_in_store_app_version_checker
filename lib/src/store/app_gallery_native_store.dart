/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:meta/meta.dart';

/// Checks the installed Android application through Huawei `AppUpdateClient`.
@internal
final class Store$AppGalleryNative implements IStore {
  /// Creates an AppGallery native client.
  const Store$AppGalleryNative();

  static const _channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  /// Shared in-flight native check, so concurrent calls from any checker
  /// instance reuse a single `AppUpdateClient` request.
  static Future<({String? packageName, String? storeID, String? version})>?
  _pendingCheck;

  @override
  String get name => 'AppGallery native';

  /// Checks AppGallery for an update to the installed application.
  ///
  /// Returns a `null` version when Huawei reports that no update exists.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    StoreRequest request,
  ) async {
    if (request.hasOverrides) {
      throw ArgumentError(
        'AppGallery native checks do not support packageName or '
        'currentVersion overrides.',
      );
    }

    final result = await (_pendingCheck ??= _invokeNative().whenComplete(() {
      _pendingCheck = null;
    }));
    if (result.packageName case String packageName
        when packageName != request.packageName) {
      throw StateError(
        'Huawei AppUpdateClient returned package "$packageName" '
        'for installed package "${request.packageName}".',
      );
    }
    return (
      version: result.version,
      appURL: switch (result.storeID) {
        String storeID => Uri(
          scheme: 'https',
          host: 'appgallery.huawei.com',
          path: '/',
          fragment: '/app/$storeID',
        ).toString(),
        null => null,
      },
    );
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
