import 'dart:math' as math show max;

import 'package:meta/meta.dart';

/// {@template in_store_app_version_checker_response}
/// The response of check app version in [AppStore] or [GooglePlay].
/// {@endtemplate}
@immutable
class InStoreAppVersionChecker$Response {
  /// {@macro in_store_app_version_checker_response}
  const InStoreAppVersionChecker$Response({
    required this.currentVersion,
    this.newVersion,
    this.appURL,
    this.error,
    this.stackTrace,
    this.errorMessage,
  });

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

  /// Check can update app.
  /// Return `true` if update is available else `false`
  bool get canUpdate =>
      _shouldUpdate(currentVersion, newVersion ?? currentVersion);

  bool _shouldUpdate(String versionA, String versionB) {
    final versionNumbersA = versionA
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .whereType<int>()
        .toList(growable: false);
    final versionNumbersB = versionB
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .whereType<int>()
        .toList(growable: false);

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
    if (error != null) buffer.write('Error: $error');
    if (errorMessage != null) buffer.write('Error message: $errorMessage');
    if (stackTrace != null) buffer.write('Stack trace: $stackTrace');
    return buffer.toString();
  }
}
