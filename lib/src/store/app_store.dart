/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:meta/meta.dart';

/// Contract implemented by each store.
///
/// A store only fetches and parses its listing. Converting the result into
/// an [InStoreAppVersionCheckerResponse] is done once by
/// [AppStoreCheckUpdate.checkUpdate].
@internal
abstract interface class AppStore {
  /// The store name used in diagnostics.
  String get name;

  /// Returns the published version and the optional listing URL.
  ///
  /// [version] is `null` only when the store reports that no update exists.
  /// Throws on any lookup failure; store-reported failures that have no
  /// underlying error are thrown as [AppStoreLookupException].
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  );
}

/// Resolved values passed to an [AppStore].
@internal
@immutable
final class AppStoreRequest {
  /// Creates a store request.
  const AppStoreRequest({
    required this.currentVersion,
    required this.packageName,
    required this.locale,
    this.storeID,
    this.expectedPackageName,
    this.hasOverrides = false,
  });

  /// The installed or overridden application version.
  final String currentVersion;

  /// The Android package name or iOS bundle identifier.
  final String packageName;

  /// The requested store locale.
  final String locale;

  /// The store listing identifier, required by AppGallery web checks.
  final String? storeID;

  /// The package name explicitly supplied by the caller, if any.
  final String? expectedPackageName;

  /// Whether the caller supplied `packageName` or `currentVersion` overrides.
  final bool hasOverrides;
}

/// A failure reported by a store with a message prepared for the response.
///
/// [cause] becomes the response `error`; it is `null` when the store returned
/// an unsuccessful result without an underlying exception.
@internal
final class AppStoreLookupException implements Exception {
  /// Creates a store lookup failure.
  const AppStoreLookupException(this.message, {this.cause});

  /// The message used as the response `errorMessage`.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() => message;
}

/// Converts an [AppStore] lookup into an [InStoreAppVersionCheckerResponse].
@internal
extension AppStoreCheckUpdate on AppStore {
  /// Fetches the listing and maps the result or failure into a response.
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    AppStoreRequest request,
  ) async {
    try {
      final listing = await fetchListing(request);
      return InStoreAppVersionCheckerResponse.success(
        currentVersion: request.currentVersion,
        newVersion: listing.version,
        appURL: listing.appURL,
      );
    } on AppStoreLookupException catch (error, stackTrace) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: request.currentVersion,
        error: error.cause,
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
