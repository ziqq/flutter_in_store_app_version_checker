/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 28 October 2025
 */

import 'dart:math' as math show max;

import 'package:meta/meta.dart';

/// {@template in_store_app_version_checker_response_type}
/// Type of response enumeration
/// {@endtemplate}
enum InStoreAppVersionChecker$Response$Type {
  /// Error response
  error,

  /// Success response
  success,
}

/// {@template in_store_app_version_checker_response}
/// The response of check app version in [AppStore] or [GooglePlay].
/// {@endtemplate}
@immutable
class InStoreAppVersionChecker$Response {
  /// {@macro in_store_app_version_checker_response}
  const InStoreAppVersionChecker$Response({
    required this.currentVersion,
    required this.type,
    this.newVersion,
    this.appURL,
    this.error,
    this.stackTrace,
    this.errorMessage,
  });

  /// Create success response
  @literal
  const factory InStoreAppVersionChecker$Response.success({
    required String currentVersion,
    String? newVersion,
    String? appURL,
  }) = _InStoreAppVersionChecker$Response$Success;

  /// Create error response
  @literal
  const factory InStoreAppVersionChecker$Response.error({
    required String currentVersion,
    required String errorMessage,
    String? newVersion,
    String? appURL,
    Object? error,
    StackTrace? stackTrace,
  }) = _InStoreAppVersionChecker$Response$Error;

  /// Return current app version
  final String currentVersion;

  /// Return the new app version
  final String? newVersion;

  /// Return the app url
  final String? appURL;

  /// Return error object if found else it will return `null`
  final Object? error;

  /// Return error message if found else it will return `null`
  final String? errorMessage;

  /// Return error stack trace
  final StackTrace? stackTrace;

  /// Return response type
  final InStoreAppVersionChecker$Response$Type type;

  /// Whether the response is a success.
  /// Return `true` if the response type
  /// is [InStoreAppVersionChecker$Response$Type.success] else `false`
  bool get isSuccess => type == InStoreAppVersionChecker$Response$Type.success;

  /// Whether the response is an error.
  /// Return `true` if the response type
  /// is [InStoreAppVersionChecker$Response$Type.error] else `false`
  bool get isError => type == InStoreAppVersionChecker$Response$Type.error;

  /// Check can update app.
  /// Return `true` if update is available else `false`
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    var $versionA = versionA.trim();
    var $versionB = versionB.trim();

    String normalize(String v) =>
        v.split('+').first.replaceAll(RegExp(r'[^0-9a-zA-Z\.\-]'), '');

    $versionA = normalize($versionA);
    $versionB = normalize($versionB);

    final partsA = $versionA.split('-');
    final partsB = $versionB.split('-');

    final coreA = partsA.first;
    final coreB = partsB.first;
    final preA = partsA.length > 1 ? partsA.sublist(1).join('-') : null;
    final preB = partsB.length > 1 ? partsB.sublist(1).join('-') : null;

    final numsA = coreA
        .split('.')
        .map(int.tryParse)
        .map((e) => e ?? 0)
        .toList(growable: false);
    final numsB = coreB
        .split('.')
        .map(int.tryParse)
        .map((e) => e ?? 0)
        .toList(growable: false);

    final maxLen = math.max(numsA.length, numsB.length);
    for (int i = 0; i < maxLen; i++) {
      final a = i < numsA.length ? numsA[i] : 0;
      final b = i < numsB.length ? numsB[i] : 0;
      if (a > b) return false;
      if (a < b) return true;
    }

    // Keep existing release vs pre-release rules
    // current is pre, new is release -> no update
    if (preA != null && preB == null) return false;
    // current is release, new is pre -> update (legacy behavior)
    if (preA == null && preB != null) return true;

    // Improved numeric-aware comparison when both have pre-release
    if (preA != null && preB != null) {
      bool isNum(String s) => int.tryParse(s) != null;

      List<String> tokenize(String s) =>
          s.split(RegExp(r'[\-\.]')).where((e) => e.isNotEmpty).toList();

      final toksA = tokenize(preA);
      final toksB = tokenize(preB);
      final len = math.max(toksA.length, toksB.length);

      for (int i = 0; i < len; i++) {
        if (i >= toksA.length && i < toksB.length) {
          // current shorter => current lower -> update
          return true;
        }
        if (i >= toksB.length && i < toksA.length) {
          // new shorter => new lower -> no update
          return false;
        }

        final aTok = toksA[i];
        final bTok = toksB[i];
        final aIsNum = isNum(aTok);
        final bIsNum = isNum(bTok);

        if (aIsNum && bIsNum) {
          final aVal = int.parse(aTok);
          final bVal = int.parse(bTok);
          if (aVal < bVal) return true;
          if (aVal > bVal) return false;
          continue;
        }

        if (aIsNum && !bIsNum) {
          // numeric < alphanumeric => new higher
          return true;
        }
        if (!aIsNum && bIsNum) {
          // alphanumeric > numeric => new lower
          return false;
        }

        // both alphanumeric: lexicographic
        final cmp = aTok.compareTo(bTok);
        if (cmp < 0) return true;
        if (cmp > 0) return false;
      }

      // All tokens equal (including length) -> no update
      return false;
    }

    return false;
  }

  @override
  int get hashCode =>
      currentVersion.hashCode ^
      newVersion.hashCode ^
      canUpdate.hashCode ^
      appURL.hashCode;

  @override
  bool operator ==(covariant InStoreAppVersionChecker$Response other) {
    if (identical(this, other)) return true;
    return other.currentVersion == currentVersion &&
        other.newVersion == newVersion &&
        other.canUpdate == canUpdate &&
        other.appURL == appURL;
  }

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('Current version: $currentVersion')
      ..writeln('New version: $newVersion')
      ..writeln('App url: $appURL')
      ..writeln('Can update: $canUpdate');
    if (errorMessage != null) buffer.writeln('Error message: $errorMessage');
    if (error != null) buffer.writeln('Error: $error');
    if (stackTrace != null) buffer.writeln('Stack trace: $stackTrace');
    return buffer.toString();
  }
}

/// Success response
/// {@macro in_store_app_version_checker_response}
@immutable
final class _InStoreAppVersionChecker$Response$Success
    extends InStoreAppVersionChecker$Response {
  /// {@macro in_store_app_version_checker_response}
  const _InStoreAppVersionChecker$Response$Success({
    required super.currentVersion,
    super.newVersion,
    super.appURL,
  }) : super(type: InStoreAppVersionChecker$Response$Type.success);
}

/// Error response
/// {@macro in_store_app_version_checker_response}
@immutable
final class _InStoreAppVersionChecker$Response$Error
    extends InStoreAppVersionChecker$Response {
  /// {@macro in_store_app_version_checker_response}
  const _InStoreAppVersionChecker$Response$Error({
    required super.currentVersion,
    super.newVersion,
    super.appURL,
    super.error,
    super.stackTrace,
    super.errorMessage,
  }) : super(type: InStoreAppVersionChecker$Response$Type.error);
}
