import 'package:flutter/foundation.dart' show defaultTargetPlatform, internal;
import 'package:flutter/services.dart' show MethodChannel, PlatformException;

/// {@template app_metadata}
/// Internal helper for retrieving installed app metadata
/// from the host platform over a method channel.
///
/// It provides the package name and version of the current app.
///
/// Example:
/// ```dart
/// final data = await AppMetadata.fromPlatform();
/// print(data.packageName); // com.example.app
/// print(data.version); // 1.2.3
/// ```
/// {@endtemplate}
@internal
final class AppMetadata {
  /// {@macro app_metadata}
  const AppMetadata._(); // coverage:ignore-line

  /// Channel used by the plugin's native implementations.
  ///
  /// Supported method names:
  /// - `getAppMetadata`: returns a map containing `packageName` and `version`.
  /// - `getPlatformVersion`: returns the host platform version.
  static const MethodChannel _channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  /// Retrieves the app metadata from the platform using a method channel.
  ///
  /// Returns a record with `packageName` and `version` fields.
  ///
  /// `packageName` is resolved from the host platform:
  /// - `bundleIdentifier` on iOS and macOS
  /// - `applicationId` / package name on Android
  /// - `package_name` from generated metadata on Web and Linux
  ///
  /// `version` is the app version exposed by the host platform.
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
