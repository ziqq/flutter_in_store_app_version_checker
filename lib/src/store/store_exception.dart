/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:meta/meta.dart';

/// A failure reported by a store with a message prepared for the response.
///
/// [error] becomes the response `error`; it is `null` when the store returned
/// an unsuccessful result without an underlying exception.
@internal
final class AppStoreException implements Exception {
  /// Creates a store lookup failure.
  const AppStoreException({required this.message, this.error});

  /// The message used as the response `errorMessage`.
  final String message;

  /// The underlying error, if any.
  final Object? error;

  @override
  String toString() => message;
}
