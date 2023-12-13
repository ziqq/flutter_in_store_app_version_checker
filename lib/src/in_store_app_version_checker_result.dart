// ignore_for_file: comment_references

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// {@template in_store_app_version_checker_result}
/// The result data model for [_InStoreAppVersionCheckerImpl]
/// {@endtemplate}
@immutable
class InStoreAppVersionCheckerResult {
  /// return current app version
  final String currentVersion;

  /// return the new app version
  final String? newVersion;

  /// return the app url
  final String? appURL;

  /// return error message if found else it will return `null`
  final String? errorMessage;

  /// {@macro in_store_app_version_checker_result}
  const InStoreAppVersionCheckerResult(
    this.currentVersion,
    this.newVersion,
    this.appURL,
    this.errorMessage,
  );

  /// return `true` if update is available
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    final versionNumbersA =
        versionA.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final versionNumbersB =
        versionB.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final int versionASize = versionNumbersA.length;
    final int versionBSize = versionNumbersB.length;
    final int maxSize = math.max(versionASize, versionBSize);

    for (int i = 0; i < maxSize; i++) {
      if ((i < versionASize ? versionNumbersA[i] : 0) >
          (i < versionBSize ? versionNumbersB[i] : 0)) {
        return false;
      } else if ((i < versionASize ? versionNumbersA[i] : 0) <
          (i < versionBSize ? versionNumbersB[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => 'Current Version: $currentVersion\n'
      'New Version: $newVersion\n'
      'App URL: $appURL\n'
      'can update: $canUpdate\n'
      'error: $errorMessage';

  @override
  bool operator ==(covariant InStoreAppVersionCheckerResult other) {
    if (identical(this, other)) return true;

    return other.currentVersion == currentVersion &&
        other.newVersion == newVersion &&
        other.appURL == appURL &&
        other.errorMessage == errorMessage;
  }

  // coverage:ignore-start
  @override
  int get hashCode {
    return currentVersion.hashCode ^
        newVersion.hashCode ^
        appURL.hashCode ^
        errorMessage.hashCode;
  }
  // coverage:ignore-end
}
