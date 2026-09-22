/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/services.dart' show MethodChannel, PlatformException;

/// Internal bridge to Huawei `AppUpdateClient` on Android.
@internal
final class AppGalleryNative {
  const AppGalleryNative._(); // coverage:ignore-line

  static const _channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  /// Checks AppGallery for an update to the installed Android application.
  static Future<({String? packageName, String? storeID, String? version})>
  checkUpdate() async {
    final data = await _channel.invokeMapMethod<String, Object?>(
      'checkAppGalleryUpdate',
    );
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
