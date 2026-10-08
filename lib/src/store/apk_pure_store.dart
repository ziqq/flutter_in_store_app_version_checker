/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/app_store.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Reads published application versions from ApkPure listing pages.
@internal
final class AppStore$ApkPure implements AppStore {
  /// Creates an ApkPure client.
  const AppStore$ApkPure(this._httpClient);

  static final _versionPattern = RegExp(
    r'<div class="details-sdk"><span itemprop="version">(.*?)<\/span>for Android<\/div>',
  );

  final http.Client _httpClient;

  @override
  String get name => 'ApkPure';

  /// Reads the ApkPure listing of `packageName`.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    AppStoreRequest request,
  ) async {
    final packageName = request.packageName;
    final uri = Uri.https('apkpure.com', '$packageName/$packageName');
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AppStoreLookupException(
        'Cannot find an app in the ApkPure Store with the id: $packageName',
      );
    }
    return (
      version: switch (_versionPattern
          .firstMatch(response.body)
          ?.group(1)
          ?.trim()) {
        String version when version.isNotEmpty => version,
        _ => throw const FormatException(
          'ApkPure listing does not contain a version.',
        ),
      },
      appURL: uri.toString(),
    );
  }
}
