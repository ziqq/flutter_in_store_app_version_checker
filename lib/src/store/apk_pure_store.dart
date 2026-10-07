/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Checks published application versions on ApkPure listing pages.
@internal
final class ApkPureStore {
  /// Creates an ApkPure client.
  const ApkPureStore(this._httpClient);

  final http.Client _httpClient;

  /// Checks the ApkPure listing of [packageName].
  Future<InStoreAppVersionCheckerResponse> checkUpdate(
    String currentVersion,
    String packageName,
  ) async {
    String? newVersion, url;
    try {
      final uri = Uri.https('apkpure.com', '$packageName/$packageName');
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return InStoreAppVersionCheckerResponse.error(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: url,
          stackTrace: StackTrace.current,
          errorMessage:
              'Cannot find an app in the ApkPure Store with the id: $packageName',
        );
      } else {
        newVersion = RegExp(
          r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
        ).firstMatch(response.body)?.group(1)?.trim();
        if (newVersion == null || newVersion.isEmpty) {
          throw const FormatException(
            'ApkPure listing does not contain a version.',
          );
        }
        return InStoreAppVersionCheckerResponse.success(
          currentVersion: currentVersion,
          newVersion: newVersion,
          appURL: uri.toString(),
        );
      }
    } on Object catch (e, st) {
      return InStoreAppVersionCheckerResponse.error(
        currentVersion: currentVersion,
        newVersion: newVersion,
        appURL: url,
        error: e,
        stackTrace: st,
        errorMessage: e.toString(),
      );
    }
  }
}
