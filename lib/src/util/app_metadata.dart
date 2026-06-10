import 'package:flutter/foundation.dart' show defaultTargetPlatform, internal;
import 'package:flutter/services.dart';

/// {@template app_metadata}
/// [AppMetadata] is a class that retrieves the app metadata
/// from the platform using a method channel.
///
/// It provides the package name and version of the app.
///
/// Example:
/// ```dart
/// final data = await AppMetadata.fromPlatform();
/// print(data.packageName); // prints the package name of the app
/// print(data.version); // prints the version of the app
/// ```
/// {@endtemplate}
@internal
final class AppMetadata {
  /// {@macro app_metadata}
  const AppMetadata._();

  /// Method chanel has 2 methods:
  /// - `getAppMetadata` - returns a map with `packageName` and `version` fields.
  /// - `getPlatformVersion` - returns the platform version of the device.
  static const MethodChannel _channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  /// Retrieves the app metadata from the platform using a method channel.
  ///
  /// This method return record with `packageName` and `version` fields.
  /// `packageName` - The package name of the app.
  /// - `bundleIdentifier` on `iOS` and `macOS`.
  /// Defined in the product target in xcode.
  /// - `packageName` on Android.
  /// Defined in `build.gradle` as `applicationId`.
  /// - `package_name` from `version.json` on Web and Linux.
  ///
  /// `version` - The version of the app.
  ///
  /// Throws a [PlatformException] if the platform
  /// does not provide the required metadata.
  static Future<({String packageName, String version})> fromPlatform() async {
    final data = await _channel.invokeMapMethod<String, Object?>(
      'getAppMetadata',
    );

    final packageName = data?['packageName']?.toString();
    final version = data?['version']?.toString();
    if (packageName == null || version == null) {
      throw PlatformException(
        code: 'invalid_package_info',
        message:
            'Platform $defaultTargetPlatform package info is missing packageName or version.',
      );
    }

    return (packageName: packageName, version: version);
  }
}
