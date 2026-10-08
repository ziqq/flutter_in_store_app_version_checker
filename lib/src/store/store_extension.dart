/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_exception.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:meta/meta.dart';

/// Converts an [IStore] lookup into an [InStoreAppVersionCheckerResponse].
@internal
extension StoreCheckUpdate on IStore {
  /// Fetches the listing and maps the result or failure into a response.
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    StoreRequest request,
  ) async {
    try {
      final listing = await fetchListing(request);
      return InStoreAppVersionCheckerResponse.success(
        currentVersion: request.currentVersion,
        newVersion: listing.version,
        appURL: listing.appURL,
      );
    } on AppStoreException catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: request.currentVersion,
        error: error.error,
        stackTrace: stackTrace,
        errorMessage: error.message,
      );
    } on Object catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: request.currentVersion,
        error: error,
        stackTrace: stackTrace,
        errorMessage: error.toString(),
      );
    }
  }
}
