/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_web_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Checks the installed application in AppGallery by its package name.
@internal
final class Store$AppGalleryNative implements IStore {
  /// Creates an AppGallery client for the installed application.
  const Store$AppGalleryNative(this._httpClient);

  final http.Client _httpClient;

  @override
  String get name => 'AppGallery native';

  /// Reads the AppGallery listing of the installed application.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    StoreRequest request,
  ) {
    if (request.hasOverrides) {
      throw ArgumentError(
        'AppGallery native checks do not support packageName or '
        'currentVersion overrides.',
      );
    }
    return Store$AppGalleryWeb(_httpClient).fetchListingByPackageName(request);
  }
}
