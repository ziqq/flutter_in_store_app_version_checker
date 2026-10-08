/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';

/// In-memory [IStore] that returns a fixed listing or throws a fixed error.
final class FakeStore implements IStore {
  /// Creates a store that returns [version] and [appURL].
  const FakeStore.listing({this.version, this.appURL}) : error = null;

  /// Creates a store that throws [error].
  const FakeStore.failure(Object this.error) : version = null, appURL = null;

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
    StoreRequest request,
  ) async => switch (error) {
    Object error => Error.throwWithStackTrace(error, StackTrace.current),
    null => (version: version, appURL: appURL),
  };
}
