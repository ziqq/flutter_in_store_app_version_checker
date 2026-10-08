/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:meta/meta.dart';

/// Resolved values passed to a store.
@internal
@immutable
final class StoreRequest {
  /// Creates a store request.
  const StoreRequest({
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
