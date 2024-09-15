import 'dart:math' as math;

import 'package:meta/meta.dart';

/// {@template in_store_app_version_checker_result}
/// The result of check app version in AppStore or GooglePlay.
/// {@endtemplate}
@immutable
class InStoreAppVersionCheckerResult {
  /// {@macro in_store_app_version_checker_result}
  const InStoreAppVersionCheckerResult({
    required this.currentVersion,
    this.newVersion,
    this.appURL,
    this.errorMessage,
    this.stackTrace,
  });

  /// Return current app version
  final String currentVersion;

  /// Return the new app version
  final String? newVersion;

  /// Return the app url
  final String? appURL;

  /// Return error message if found else it will return `null`
  final String? errorMessage;

  /// Return error stack trace
  final StackTrace? stackTrace;

  /// Return `true` if update is available
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    final versionNumbersA =
        versionA.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final versionNumbersB =
        versionB.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final versionASize = versionNumbersA.length;
    final versionBSize = versionNumbersB.length;
    final int maxSize = math.max(versionASize, versionBSize);

    for (var i = 0; i < maxSize; i++) {
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
  String toString() {
    final buffer = StringBuffer()
      ..write('CURRENT VERSION: $currentVersion\n')
      ..write('NEW VERSION: $newVersion\n')
      ..write('APP URL: $appURL\n')
      ..write('CAN UPDATE: $canUpdate');
    if (errorMessage != null) buffer.write('\nERROR: $errorMessage, ');
    if (stackTrace != null) buffer.write('\nSTACK TRACE: $stackTrace, ');
    return buffer.toString();
  }

  @override
  bool operator ==(covariant InStoreAppVersionCheckerResult other) {
    if (identical(this, other)) return true;
    return other.currentVersion == currentVersion &&
        other.newVersion == newVersion &&
        other.appURL == appURL &&
        other.canUpdate == canUpdate &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode =>
      currentVersion.hashCode ^
      newVersion.hashCode ^
      appURL.hashCode ^
      errorMessage.hashCode;
}
