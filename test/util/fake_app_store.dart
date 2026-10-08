/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/app_store.dart';

/// In-memory [AppStore] that returns a fixed listing or throws a fixed error.
final class FakeAppStore implements AppStore {
  /// Creates a store that returns [version] and [appURL].
  const FakeAppStore.listing({this.version, this.appURL}) : error = null;

  /// Creates a store that throws [error].
  const FakeAppStore.failure(Object this.error) : version = null, appURL = null;

  /// The version returned by [fetchListing].
  final String? version;

  /// The listing URL returned by [fetchListing].
  final String? appURL;

  /// The error thrown by [fetchListing], if any.
  final Object? error;

  @override
  String get name => 'Fake';

  @override
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  ) async => switch (error) {
    Object error => Error.throwWithStackTrace(error, StackTrace.current),
    null => (version: version, appURL: appURL),
  };
}
