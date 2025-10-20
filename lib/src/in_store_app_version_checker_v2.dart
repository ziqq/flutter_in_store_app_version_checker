// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// {@template android_store}
/// Possible types of android store
/// {@endtemplate}
enum AndroidStore {
  /// The default AAB
  googlePlayStore,

  /// The pure APK
  apkPure
}

/// {@template in_store_app_version_checker_result}
/// The result of check app version in AppStore or GooglePlay.
/// {@endtemplate}
@immutable
class InStoreAppVersionChecker$Result {
  /// {@macro in_store_app_version_checker_result}
  const InStoreAppVersionChecker$Result({
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
  String toString() {
    final buffer = StringBuffer()
      ..writeln('Current version: $currentVersion')
      ..writeln('New version: $newVersion')
      ..writeln('App url: $appURL')
      ..writeln('Can update: $canUpdate');
    if (errorMessage != null) buffer.write('\nError: $errorMessage, ');
    if (stackTrace != null) buffer.write('\nStack trace: $stackTrace, ');
    return buffer.toString();
  }

  @override
  bool operator ==(covariant InStoreAppVersionChecker$Result other) {
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

@immutable
class InStoreAppVersionChecker$Settings {
  const InStoreAppVersionChecker$Settings({
    this.appID,
    this.locale,
    this.currentVersion,
    this.androidStore,
  });

  @literal
  const factory InStoreAppVersionChecker$Settings.empty() =
      _InStoreAppVersionChecker$Settings$Empty;

  /// Select The marketplace of your app from [AndroidStore].
  /// Default `AndroidStore.GooglePlayStore`.
  final AndroidStore? androidStore;

  /// The current version of the app.
  /// Default take the Flutter package version.
  final String? currentVersion;

  /// The locale your app store.
  /// Default value is `ru`.
  final String? locale;

  /// The id of the app (com.exemple.your_app).
  /// If [appID] is null the [appID] will take the Flutter package identifier.
  final String? appID;
}

/// Default settings for [InStoreAppVersionChecker].
/// Uses default values for all parameters.
/// [appID] is null,
/// [locale] is 'ru',
/// [currentVersion] is null,
/// [androidStore] is [AndroidStore.googlePlayStore].
@immutable
final class _InStoreAppVersionChecker$Settings$Empty
    extends InStoreAppVersionChecker$Settings {
  const _InStoreAppVersionChecker$Settings$Empty()
      : super(
          appID: null,
          locale: 'ru',
          currentVersion: null,
          androidStore: AndroidStore.googlePlayStore,
        );
}

/// {@template in_store_app_version_checker}
/// [InStoreAppVersionChecker] is an interface for checking the current version
/// of an app available in app stores such as Google Play and ApkPure,
/// comparing it with the installed version on the device.
/// It supports both Android and iOS platforms.
///
/// Properties:
/// - [appID]: The app's identifier (if not provided, Flutter's app ID is used).
/// - [locale]: The language/locale of the app store (default is "ru").
/// - [androidStore]: Specifies the Android app store (Google Play or ApkPure).
/// - [currentVersion]: The current version of the app (if not provided, it is fetched from Flutter).
/// - [httpClient]: A custom HTTP client for making API requests.
///
/// Methods:
/// - `checkUpdate()`: Checks for app updates in the selected app store.
///
/// This class simplifies the process of checking for app updates by automating API
/// requests to app stores and is compatible with popular mobile platforms.
/// {@endtemplate}
abstract interface class IInStoreAppVersionChecker {
  /// The id of the app (com.exemple.your_app).
  /// If [appID] is null the [appID] will take the Flutter package identifier.
  String? get appID;

  /// The locale your app store.
  /// Default value is `ru`.
  String? get locale;

  /// The current version of the app.
  /// Default take the Flutter package version.
  String? get currentVersion;

  /// Select The marketplace of your app from [AndroidStore].
  /// Default `AndroidStore.GooglePlayStore`.
  AndroidStore? get androidStore;

  /// Check update current store type.
  Future<InStoreAppVersionChecker$Result> checkUpdate();
}

final class InStoreAppVersionChecker implements IInStoreAppVersionChecker {
  /// {@macro in_store_app_version_checker}
  InStoreAppVersionChecker(
    this.settings, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final InStoreAppVersionChecker$Settings settings;

  /// This is http client.
  late final http.Client _httpClient;

  /// Whether the current platform is iOS.
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the current platform is Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static InStoreAppVersionChecker? _instance;

  /// Returns the [Contactos] singleton instance.
  /// Also registers this as the default platform implementation.
  // ignore: prefer_constructors_over_static_methods
  static InStoreAppVersionChecker get instance =>
      _instance ??= InStoreAppVersionChecker._(const .InStoreAppVersionChecker$Settings.empty());

  /// Check update current store type.
  @override
  Future<InStoreAppVersionChecker$Result> checkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = appID ?? packageInfo.packageName;
    final currentVersion = this.currentVersion ?? packageInfo.version;
    if (_isAndroid) {
      return await switch (androidStore) {
        AndroidStore.apkPure =>
          _checkPlayStore$ApkPure(currentVersion, packageName),
        _ => _checkPlayStore(currentVersion, packageName),
      };
    } else if (_isIOS) {
      return await _checkAppleStore(
        currentVersion,
        packageName,
        locale: locale,
      );
    } else {
      return InStoreAppVersionChecker$Result(
        currentVersion: currentVersion,
        newVersion: null,
        appURL: '',
        errorMessage:
            'This platform is not yet supported by this package. We support iOS or Android platrforms.',
        stackTrace: StackTrace.current,
      );
    }
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionChecker$Result> _checkAppleStore(
    String currentVersion,
    String packageName, {
    String? locale,
  }) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/$locale/lookup',
        {
          'bundleId': packageName,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Apple Store with the id: $packageName";
      } else {
        final jsonObj = jsonDecode(response.body);
        final results =
            List<dynamic>.from(jsonObj['results'] as Iterable<dynamic>);

        if (results.isEmpty) {
          errorMsg =
              "Can't find an app in the Apple Store with the id: $packageName";
        } else {
          newVersion = jsonObj['results'][0]['version'].toString();
          url = jsonObj['results'][0]['trackViewUrl'].toString();
        }
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    return InStoreAppVersionChecker$Result(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionChecker$Result> _checkPlayStore(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        {
          'id': packageName,
          'hl': locale,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the Google Play Store with the id: $packageName";
      } else {
        newVersion = RegExp(r',\[\[\["([0-9,\.]*)"]],')
            .firstMatch(response.body)
            ?.group(1);
        url = uri.toString();
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    return InStoreAppVersionChecker$Result(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }

  /// {@macro in_store_app_version_checker}
  Future<InStoreAppVersionChecker$Result> _checkPlayStore$ApkPure(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, errorMsg, url;
    StackTrace? stackTrace;

    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        errorMsg =
            "Can't find an app in the ApkPure Store with the id: $packageName";
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)!.group(1)!.trim();
        url = uri.toString();
      }
    } on Object catch (error, st) {
      errorMsg = '$error';
      stackTrace = st;
    }
    return InStoreAppVersionChecker$Result(
      currentVersion: currentVersion,
      newVersion: newVersion,
      appURL: url,
      errorMessage: errorMsg,
      stackTrace: stackTrace,
    );
  }
}
