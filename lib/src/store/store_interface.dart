/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/store_exception.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:meta/meta.dart';

/// Contract implemented by each store.
///
/// A store only fetches and parses its listing. Converting the result into
/// an [InStoreAppVersionCheckerResponse] is done once by
/// `StoreCheckUpdate.checkUpdate`.
@internal
abstract interface class IStore {
  /// The store name used in diagnostics.
  String get name;

  /// Returns the published version and the optional listing URL.
  ///
  /// [version] is `null` only when the store reports that no update exists.
  /// Throws on any lookup failure; store-reported failures that have no
  /// underlying error are thrown as [AppStoreException].
  Future<({String? version, String? appURL})> fetchListing(
    StoreRequest request,
  );
}
